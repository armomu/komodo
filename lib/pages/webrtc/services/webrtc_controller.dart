import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
// ignore: depend_on_referenced_packages
import 'package:get/get.dart' hide navigator;

import '../models/call_state.dart';
import 'signaling_client.dart';

/// WebRTC 视频通话控制器——单房间一对一通话。
///
/// 职责：
/// - 管理 RTCPeerConnection 生命周期
/// - 管理本地/远端媒体流
/// - 与 SignalingClient 协作完成信令交换
class WebrtcController extends GetxController {
  // ==================== 依赖（从 get 注入） ====================
  late final SignalingClient _signaling;

  // ==================== 信令相关 ====================
  String _roomId = '';
  String _myUid = '';
  String _peerUid = '';
  String _serverUrl = '';

  // ==================== WebRTC 相关 ====================
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // ==================== 订阅 ====================
  final List<StreamSubscription> _subs = [];

  /// 防止重复处理 peer-ready
  bool _handshakeStarted = false;

  /// peer-ready 比 PC 先到达时待发送的 offer
  bool _pendingOffer = false;

  // ==================== 可观察状态 ====================

  /// 通话状态
  final callState = CallState.idle.obs;

  /// 本地视频渲染器
  final localRenderer = RTCVideoRenderer();

  /// 远端视频渲染器
  final remoteRenderer = RTCVideoRenderer();

  /// 摄像头是否开启
  final isCameraOn = true.obs;

  /// 麦克风是否开启
  final isMicOn = true.obs;

  /// 房间号
  String get roomId => _roomId;

  /// 是否是对端发起的呼叫（被动方）
  bool get isIncoming =>
      callState.value == CallState.incoming;

  // ==================== 初始化 ====================

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  @override
  void onInit() {
    super.onInit();
    _signaling = Get.find<SignalingClient>();
    _setupListeners();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ==================== 公开 API ====================

  /// 设置信令服务器地址（默认值）
  void setServerUrl(String url) => _serverUrl = url;

  /// 发起呼叫：连接信令、加入房间、获取媒体、创建 Offer
  Future<void> startCall({
    required String serverUrl,
    required String roomId,
    required String myUid,
  }) async {
    _serverUrl = serverUrl;
    _roomId = roomId;
    _myUid = myUid;
    callState.value = CallState.calling;

    try {
      // 1. 连接信令服务器
      await _signaling.connect(_serverUrl);
      // 2. 加入房间
      _signaling.joinRoom(_roomId, _myUid);
      // 3. 获取本地媒体
      await _getLocalMedia();
      // 4. 创建 PeerConnection
      await _createPeerConnection();
      // 5. 等待 peer-ready 事件触发 offer/answer 协商
      callState.value = CallState.connecting;
    } catch (e) {
      callState.value = CallState.error;
    }
  }

  /// 接听来电（手动）
  Future<void> answerCall() async {
    if (_pc == null) return;
    callState.value = CallState.connecting;
    await _createAndSendAnswer();
  }

  /// 挂断
  Future<void> endCall() async {
    if (_peerUid.isNotEmpty) {
      _signaling.sendEndCall(_peerUid);
    }
    _signaling.leaveRoom(_roomId);
    _cleanup();
    callState.value = CallState.ended;
  }

  /// 切换摄像头前后置
  Future<void> switchCamera() async {
    if (_localStream != null) {
      await Helper.switchCamera(_localStream!.getVideoTracks().first);
    }
  }

  /// 切换麦克风静音
  Future<void> toggleMic() async {
    if (_localStream == null) return;
    isMicOn.value = !isMicOn.value;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = isMicOn.value;
    }
  }

  /// 切换摄像头开关
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    isCameraOn.value = !isCameraOn.value;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = isCameraOn.value;
    }
  }

  /// 重连
  Future<void> reconnect({
    required String serverUrl,
    required String roomId,
    required String myUid,
  }) async {
    _cleanup();
    await startCall(
      serverUrl: serverUrl,
      roomId: roomId,
      myUid: myUid,
    );
  }

  // ==================== 内部——信令事件监听 ====================

  void _setupListeners() {
    // 注意：onConnected 的 uid 是服务端分配的会话 UUID，与自定义 UID 不同
    // 所以这里不覆盖 _myUid（已在 startCall 中设置）
    _subs.add(_signaling.onConnected.listen((uid) {
      // _myUid 已在 startCall 中设为自定义 UID，不覆盖
    }));

    _subs.add(_signaling.onUserJoined.listen((uid) {
      if (_peerUid.isEmpty) _peerUid = uid;
    }));

    _subs.add(_signaling.onRoomUsers.listen((data) {
      if (data.users.isNotEmpty && _peerUid.isEmpty) {
        _peerUid = data.users.first;
      }
    }));

    _subs.add(_signaling.onPeerReady.listen((data) {
      _handlePeerReady(data.peers);
    }));

    _subs.add(_signaling.onOffer.listen((data) {
      _handleOfferReceived(data.from, data.sdp);
    }));

    _subs.add(_signaling.onAnswer.listen((data) {
      _handleAnswerReceived(data.sdp);
    }));

    _subs.add(_signaling.onIceCandidate.listen((data) {
      _handleIceCandidateReceived(data.candidate);
    }));

    _subs.add(_signaling.onCallEnded.listen((_) {
      _onPeerEnded();
    }));

    _subs.add(_signaling.onError.listen((msg) {
      callState.value = CallState.error;
    }));
  }

  // ==================== 内部——媒体 & PeerConnection ====================

  /// 收到 peer-ready 事件后决定谁发 Offer 谁发 Answer。
  /// 规则：按 UID 字典序排序，较小的作为 Offer 发起方。
  void _handlePeerReady(List<String> peers) {
    if (_handshakeStarted) return;
    if (peers.length < 2) return;
    _handshakeStarted = true;

    // 找出对端的 UID
    final others = peers.where((uid) => uid != _myUid).toList();
    if (others.isEmpty) return;
    _peerUid = others.first;

    // 排序后第一个发 Offer
    final sorted = List<String>.from(peers)..sort();
    final iAmInitiator = sorted.first == _myUid;

    if (iAmInitiator) {
      if (_pc != null) {
        _createAndSendOffer();
      } else {
        // PC 尚未就绪，标记待发送
        _pendingOffer = true;
      }
    }
    // 非发起方等待对端发来的 Offer（由 _handleOfferReceived 处理）
  }

  Future<void> _getLocalMedia() async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;
    } catch (e) {
      // 获取视频失败
      _localStream = null;
    }
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);

    // 添加本地流（Unified Plan 下须用 addTrack 替代 addStream）
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    // ICE Candidate 回调
    _pc!.onIceCandidate = (candidate) {
      if (_peerUid.isNotEmpty) {
        _signaling.sendIceCandidate(
          _peerUid,
          jsonEncode(candidate.toMap()),
        );
      }
    };

    // 远端流回调
    _pc!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        callState.value = CallState.connected;
      }
    };

    // 连接状态变化
    _pc!.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          callState.value = CallState.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          callState.value = CallState.ended;
          break;
        default:
          break;
      }
    };

    // 如果 peer-ready 已到达但 PC 当时未就绪，现在补发 offer
    if (_pendingOffer) {
      _pendingOffer = false;
      _createAndSendOffer();
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_pc == null) return;

    final session = await _pc!.createOffer();
    await _pc!.setLocalDescription(session);
    if (session.sdp == null) return;
    _signaling.sendOffer(
      _peerUid,
      session.sdp!,
    );
  }

  // ==================== 内部——对端信令处理 ====================

  Future<void> _handleOfferReceived(String fromUid, String sdp) async {
    _peerUid = fromUid;

    if (_pc == null) {
      // PC 尚未创建（未调用 startCall），这是通过信令直接收到来电
      callState.value = CallState.incoming;
      await _getLocalMedia();
      await _createPeerConnection();
    }

    final session = RTCSessionDescription(
      sdp,
      'offer',
    );
    await _pc!.setRemoteDescription(session);

    // peer-ready 流程（双方主动加入房间）：自动应答
    // 非 peer-ready 流程（被叫手动接听）：由 user 按接听按钮触发
    if (_handshakeStarted) {
      await _createAndSendAnswer();
    }
  }

  /// 创建并发送 Answer
  Future<void> _createAndSendAnswer() async {
    if (_pc == null) return;
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    if (answer.sdp == null) return;
    _signaling.sendAnswer(_peerUid, answer.sdp!);
  }

  Future<void> _handleAnswerReceived(String sdp) async {
    final session = RTCSessionDescription(
      sdp,
      'answer',
    );
    await _pc?.setRemoteDescription(session);
  }

  Future<void> _handleIceCandidateReceived(String candidate) async {
    final map = jsonDecode(candidate) as Map<String, dynamic>;
    final iceCandidate = RTCIceCandidate(
      map['candidate'],
      map['sdpMid'],
      map['sdpMLineIndex'] as int?,
    );
    await _pc?.addCandidate(iceCandidate);
  }

  void _onPeerEnded() {
    _cleanup();
    callState.value = CallState.ended;
  }

  // ==================== 清理 ====================

  bool _disposed = false;

  void _cleanup() {
    if (_disposed) return;
    _disposed = true;

    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    _signaling.disconnect();

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    localRenderer.srcObject = null;
    localRenderer.dispose();
    remoteRenderer.srcObject = null;
    remoteRenderer.dispose();

    _pc?.close();
    _pc = null;

    _peerUid = '';
    _handshakeStarted = false;
    _pendingOffer = false;
  }
}

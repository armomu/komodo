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
      // 5. 创建并发送 Offer
      await _createAndSendOffer();
      callState.value = CallState.connecting;
    } catch (e) {
      callState.value = CallState.error;
    }
  }

  /// 接听来电
  Future<void> answerCall() async {
    if (_pc == null) return;
    callState.value = CallState.connecting;

    try {
      final session = await _pc!.createAnswer();
      await _pc!.setLocalDescription(session);
      _signaling.sendAnswer(_peerUid, jsonEncode(session.toMap()));
    } catch (e) {
      callState.value = CallState.error;
    }
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
    _subs.add(_signaling.onConnected.listen((uid) {
      _myUid = uid;
    }));

    _subs.add(_signaling.onUserJoined.listen((uid) {
      // 对端加入房间
    }));

    _subs.add(_signaling.onRoomUsers.listen((data) {
      if (data.users.isNotEmpty) {
        _peerUid = data.users.first;
      }
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

    // 添加本地流
    if (_localStream != null) {
      _pc!.addStream(_localStream!);
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
  }

  Future<void> _createAndSendOffer() async {
    if (_pc == null) return;

    final session = await _pc!.createOffer();
    await _pc!.setLocalDescription(session);
    // 等有对端了才发送 offer（room-users 事件到达后再发）
    // 此处直接发送，room-users 事件会稍后到达
    // 更好的做法：用一个小延迟等待 room-users
    await Future.delayed(const Duration(milliseconds: 500));
    _signaling.sendOffer(
      _peerUid,
      jsonEncode(session.toMap()),
    );
  }

  // ==================== 内部——对端信令处理 ====================

  Future<void> _handleOfferReceived(String fromUid, String sdp) async {
    _peerUid = fromUid;
    callState.value = CallState.incoming;

    // 获取本地媒体
    await _getLocalMedia();
    // 创建 PeerConnection
    await _createPeerConnection();

    // 设置远端描述
    final session = RTCSessionDescription(
      sdp,
      'offer',
    );
    await _pc!.setRemoteDescription(session);
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

  void _cleanup() {
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
    remoteRenderer.srcObject = null;

    _pc?.close();
    _pc = null;

    _peerUid = '';
  }
}

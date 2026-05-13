import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
// ignore: depend_on_referenced_packages
import 'package:get/get.dart' hide navigator;

import '../models/call_state.dart';
import 'signaling_client.dart';

/// WebRTC 视频通话控制器——Mesh 多人通话。
///
/// 架构：
/// - 每个对端一个 RTCPeerConnection，地图存储
/// - UID 字典序较大者主动发起 Offer，较小者自动应答
/// - 服务端只转发信令，媒体流 P2P 直连
class WebrtcController extends GetxController {
  // ==================== 依赖 ====================
  late final SignalingClient _signaling;

  // ==================== 信令相关 ====================
  String _roomId = '';
  String _myUid = '';
  String _serverUrl = '';

  // ==================== 本地媒体 ====================
  MediaStream? _localStream;

  /// 本地视频渲染器
  final localRenderer = RTCVideoRenderer();

  // ==================== 多 Peer 管理 ====================

  /// 每个对端一个 PC
  final Map<String, RTCPeerConnection> _pcs = {};

  /// 每个对端的远端流
  final Map<String, MediaStream> _remoteStreams = {};

  /// 每个对端的渲染器
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  /// 已由我主动发起连接的 peer（防重入）
  final Set<String> _peersIAmInitiator = {};

  // ==================== 订阅 ====================
  final List<StreamSubscription> _subs = [];

  // ==================== 可观察状态 ====================

  /// 通话状态
  final callState = CallState.idle.obs;

  /// 远端 peer UID 列表，UI 据此渲染视频网格
  final remotePeerUids = <String>[].obs;

  /// 摄像头是否开启
  final isCameraOn = true.obs;

  /// 麦克风是否开启
  final isMicOn = true.obs;

  /// 房间号
  String get roomId => _roomId;

  // ==================== 初始化 ====================

  Future<void> initRenderers() async {
    await localRenderer.initialize();
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

  /// 发起呼叫：连接信令、加入房间、获取本地媒体
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
      await _signaling.connect(_serverUrl);
      _signaling.joinRoom(_roomId, _myUid);
      await _getLocalMedia();
      callState.value = CallState.connecting;
    } catch (e) {
      callState.value = CallState.error;
    }
  }

  /// 挂断
  Future<void> endCall() async {
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

  /// UI 获取指定 peer 的渲染器
  RTCVideoRenderer? rendererForPeer(String uid) => _remoteRenderers[uid];

  // ==================== 内部——信令事件监听 ====================

  void _setupListeners() {
    _subs.add(_signaling.onConnected.listen((_) {}));

    _subs.add(_signaling.onUserJoined.listen((_) {}));

    _subs.add(_signaling.onRoomUsers.listen((_) {}));

    _subs.add(
      _signaling.onPeerReady.listen((data) {
        _handlePeerReady(data.peers);
      }),
    );

    _subs.add(
      _signaling.onOffer.listen((data) {
        _handleOfferReceived(data.from, data.sdp).catchError((e) {
          debugPrint('[Mesh] !! onOffer(${data.from}) =========异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onAnswer.listen((data) {
        _handleAnswerReceived(data.from, data.sdp).catchError((e) {
          debugPrint('[Mesh] !! onAnswer(${data.from}) =========异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onIceCandidate.listen((data) {
        _handleIceCandidateReceived(data.from, data.candidate).catchError((e) {
          debugPrint('[Mesh] !! onIceCandidate(${data.from}) 异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onUserLeft.listen((uid) {
        _removePeer(uid);
        if (_pcs.isEmpty) {
          callState.value = CallState.ended;
        }
      }),
    );

    _subs.add(
      _signaling.onCallEnded.listen((_) {
        callState.value = CallState.ended;
      }),
    );

    _subs.add(
      _signaling.onError.listen((_) {
        callState.value = CallState.error;
      }),
    );
  }

  // ==================== 内部——Mesh 信令处理 ====================

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
      _localStream = null;
    }
  }

  /// peer-ready 到达后，与每个比自己 UID 大的 peer 主动建连
  void _handlePeerReady(List<String> peers) {
    debugPrint('[Mesh] peer-ready: ${peers.join(", ")}');
    for (final peerUid in peers) {
      if (peerUid == _myUid) continue;
      if (_pcs.containsKey(peerUid)) continue;

      // 字典序比较：比我大的我主动发 offer，比我小的等待对方发来
      if (peerUid.compareTo(_myUid) > 0) {
        debugPrint('[Mesh] -> 主动发 offer 给 $peerUid');
        _peersIAmInitiator.add(peerUid);
        _establishConnection(peerUid, initiator: true).catchError((e) {
          debugPrint('[Mesh] !! establishConnection($peerUid) 失败: $e');
          _removePeer(peerUid);
        });
      }
    }
  }

  /// 与指定 peer 建立 PeerConnection
  Future<void> _establishConnection(
    String peerUid, {
    required bool initiator,
  }) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[peerUid] = renderer;
    remotePeerUids.add(peerUid);

    try {
      final pc = await _createPeerConnectionForPeer(peerUid);
      _pcs[peerUid] = pc;
      debugPrint('[Mesh] PC 创建成功 | peer=$peerUid');

      if (initiator) {
        await _sendOffer(pc, peerUid);
        debugPrint('[Mesh] Offer 已发送 | peer=$peerUid');
      }
    } catch (e) {
      debugPrint('[Mesh] !! _establishConnection($peerUid) 异常: $e');
      _removePeer(peerUid);
    }
  }

  /// 为指定 peer 创建 RTCPeerConnection
  Future<RTCPeerConnection> _createPeerConnectionForPeer(String peerUid) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    // 添加本地流
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // ICE Candidate——发往指定对端
    pc.onIceCandidate = (candidate) {
      _signaling.sendIceCandidate(peerUid, jsonEncode(candidate.toMap()));
    };

    // 远端流到达
    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteStreams[peerUid] = event.streams[0];
        _remoteRenderers[peerUid]?.srcObject = event.streams[0];
        callState.value = CallState.connected;
      }
    };

    // 连接状态
    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = CallState.connected;
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _removePeer(peerUid);
        if (_pcs.isEmpty) {
          callState.value = CallState.ended;
        }
      }
    };

    return pc;
  }

  /// 向指定对端发送 Offer
  Future<void> _sendOffer(RTCPeerConnection pc, String peerUid) async {
    final session = await pc.createOffer();
    await pc.setLocalDescription(session);
    if (session.sdp != null) {
      _signaling.sendOffer(peerUid, session.sdp!);
    }
  }

  /// 收到对端发来的 Offer
  Future<void> _handleOfferReceived(String fromUid, String sdp) async {
    debugPrint('[Mesh] 收到 Offer | from=$fromUid');

    // 如果已有此对端的 PC，直接设置远端描述并应答
    if (_pcs.containsKey(fromUid)) {
      try {
        final session = RTCSessionDescription(sdp, 'offer');
        await _pcs[fromUid]!.setRemoteDescription(session);
        await _sendAnswer(_pcs[fromUid]!, fromUid);
        debugPrint('[Mesh] 已有PC，应答完毕 | peer=$fromUid');
      } catch (e) {
        debugPrint('[Mesh] !! onOffer($fromUid) 已有PC异常: $e');
      }
      return;
    }

    // 首次收到此对端的 Offer，现场建连
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _remoteRenderers[fromUid] = renderer;
      remotePeerUids.add(fromUid);

      final pc = await _createPeerConnectionForPeer(fromUid);
      _pcs[fromUid] = pc;

      final session = RTCSessionDescription(sdp, 'offer');
      await pc.setRemoteDescription(session);
      await _sendAnswer(pc, fromUid);
      debugPrint('[Mesh] 新建PC应答完毕 | peer=$fromUid');
    } catch (e) {
      debugPrint('[Mesh] !! onOffer($fromUid) 新建PC异常: $e');
      _removePeer(fromUid);
    }
  }

  /// 向指定对端发送 Answer
  Future<void> _sendAnswer(RTCPeerConnection pc, String peerUid) async {
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    if (answer.sdp != null) {
      _signaling.sendAnswer(peerUid, answer.sdp!);
    }
  }

  /// 收到对端发来的 Answer
  Future<void> _handleAnswerReceived(String fromUid, String sdp) async {
    final pc = _pcs[fromUid];
    if (pc == null) return;
    final session = RTCSessionDescription(sdp, 'answer');
    await pc.setRemoteDescription(session);
  }

  /// 收到对端发来的 ICE Candidate
  Future<void> _handleIceCandidateReceived(
    String fromUid,
    String candidate,
  ) async {
    final pc = _pcs[fromUid];
    if (pc == null) return;
    final map = jsonDecode(candidate) as Map<String, dynamic>;
    final iceCandidate = RTCIceCandidate(
      map['candidate'],
      map['sdpMid'],
      map['sdpMLineIndex'] as int?,
    );
    await pc.addCandidate(iceCandidate);
  }

  // ==================== Peer 清理 ====================

  /// 移除指定 peer 的所有资源
  void _removePeer(String uid) {
    _pcs[uid]?.close();
    _pcs.remove(uid);

    _remoteStreams[uid]?.dispose();
    _remoteStreams.remove(uid);

    final r = _remoteRenderers.remove(uid);
    if (r != null) {
      r.srcObject = null;
      r.dispose();
    }

    _peersIAmInitiator.remove(uid);
    remotePeerUids.remove(uid);
  }

  // ==================== 全局清理 ====================

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

    localRenderer.srcObject = null;
    localRenderer.dispose();

    // 清理所有远端 peer
    for (final uid in _pcs.keys.toList()) {
      _removePeer(uid);
    }
    _peersIAmInitiator.clear();
  }
}

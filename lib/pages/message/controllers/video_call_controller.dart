import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;

import '../../webrtc/models/call_state.dart';
import '../../../services/consumer_ws_client.dart';
import '../../../controllers/user_controller.dart';

/// 1v1 视频通话控制器——使用 ConsumerWsClient 替代旧 SignalingClient。
///
/// 参数：
///   - peerUserId (int): 对方 userId
///   - roomId (string): 通话房间标识
///   - isCaller (bool): 是否主动呼叫方（呼叫方需等待对方接受）
class VideoCallController extends GetxController {
  ConsumerWsClient? _ws;

  // ==================== 信令相关 ====================
  int _peerUserId = 0;
  String _roomId = '';
  bool _isCaller = false;

  // ==================== WebRTC ====================
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // ==================== 渲染器 ====================
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  // ==================== 状态 ====================
  final callState = CallState.idle.obs;
  final isCameraOn = true.obs;
  final isMicOn = true.obs;

  // ==================== 订阅 ====================
  final List<StreamSubscription> _subs = [];
  bool _disposed = false;
  bool _handshakeStarted = false;

  // ==================== 初始化 ====================

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  @override
  void onInit() {
    super.onInit();
    _ws = Get.find<ConsumerWsClient>();
    _setupListeners();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ==================== 公开 API ====================

  /// 以呼叫方身份发起：发送邀请 → 进入等待状态
  Future<void> startAsCaller({
    required int peerUserId,
    required String roomId,
  }) async {
    _peerUserId = peerUserId;
    _roomId = roomId;
    _isCaller = true;
    callState.value = CallState.waiting;

    // 先准备好本地渲染器和 PeerConnection，等对方接受后立即开始信令
    try {
      await _getLocalMedia();
      await _createPeerConnection();
    } catch (e) {
      debugPrint('[VideoCall] startAsCaller prepare error: $e');
      callState.value = CallState.error;
    }
  }

  /// 以被叫方身份接听
  Future<void> startAsCallee({
    required int peerUserId,
    required String roomId,
  }) async {
    _peerUserId = peerUserId;
    _roomId = roomId;
    _isCaller = false;
    callState.value = CallState.calling;

    try {
      await _getLocalMedia();
      await _createPeerConnection();
      _ws!.joinRoom(_roomId);
      callState.value = CallState.connecting;
    } catch (e) {
      debugPrint('[VideoCall] startAsCallee error: $e');
      callState.value = CallState.error;
    }
  }

  /// 挂断
  Future<void> endCall() async {
    if (_roomId.isNotEmpty && _peerUserId > 0) {
      _ws!.leaveRoom(_roomId);
      _ws!.sendEndCall(_roomId, _peerUserId);
    }
    _cleanup();
    callState.value = CallState.ended;
  }

  Future<void> toggleMic() async {
    if (_localStream == null) return;
    isMicOn.value = !isMicOn.value;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = isMicOn.value;
    }
  }

  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    isCameraOn.value = !isCameraOn.value;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = isCameraOn.value;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      await Helper.switchCamera(_localStream!.getVideoTracks().first);
    }
  }

  // ==================== 内部 ====================

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

  void _setupListeners() {
    if (_ws == null) return;

    _subs.add(_ws!.onPeerReady.listen((data) {
      _handlePeerReady(data.peers);
    }));
    _subs.add(_ws!.onOffer.listen((data) {
      _handleOfferReceived(data.from, data.sdp).catchError((e) {
        debugPrint('[VideoCall] onOffer error: $e');
      });
    }));
    _subs.add(_ws!.onAnswer.listen((data) {
      _handleAnswerReceived(data.sdp);
    }));
    _subs.add(_ws!.onIceCandidate.listen((data) {
      _handleIceCandidateReceived(data.candidate);
    }));
    _subs.add(_ws!.onUserLeft.listen((_) {
      if (callState.value == CallState.connected) {
        callState.value = CallState.ended;
      }
    }));
    _subs.add(_ws!.onCallEnded.listen((_) {
      callState.value = CallState.ended;
    }));

    // 呼叫方监听：对方接受邀请 → 加入房间开始建连
    _subs.add(_ws!.onVideoCallAccept.listen((data) {
      if (_isCaller && data.from == _peerUserId && data.roomId == _roomId) {
        debugPrint('[VideoCall] 对方接受了邀请，开始连接');
        callState.value = CallState.connecting;
        _ws!.joinRoom(_roomId);
        // 此时 peer-ready 或 offer 会触发
      }
    }));

    // 呼叫方监听：对方拒绝邀请 → 结束
    _subs.add(_ws!.onVideoCallReject.listen((data) {
      if (_isCaller && data.from == _peerUserId && data.roomId == _roomId) {
        debugPrint('[VideoCall] 对方拒绝了邀请');
        callState.value = CallState.ended;
      }
    }));
  }

  void _handlePeerReady(List<int> peers) {
    if (_handshakeStarted) return;
    if (peers.length < 2) return;
    _handshakeStarted = true;

    final myUserId = UserController.to.userId;
    final others = peers.where((uid) => uid != myUserId).toList();
    if (others.isEmpty) return;
    _peerUserId = others.first;

    // 按 userId 字典序，小的发 Offer
    final sorted = List<int>.from(peers)..sort();
    if (sorted.first == myUserId) {
      _createAndSendOffer();
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_pc == null) return;
    final session = await _pc!.createOffer();
    await _pc!.setLocalDescription(session);
    if (session.sdp != null) {
      _ws!.sendOffer(_roomId, _peerUserId, session.sdp!);
    }
  }

  Future<void> _handleOfferReceived(int fromUid, String sdp) async {
    _peerUserId = fromUid;

    if (_pc == null) {
      await _getLocalMedia();
      await _createPeerConnection();
    }

    final session = RTCSessionDescription(sdp, 'offer');
    await _pc!.setRemoteDescription(session);

    if (_handshakeStarted) {
      await _createAndSendAnswer();
    }
  }

  Future<void> _createAndSendAnswer() async {
    if (_pc == null) return;
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    if (answer.sdp != null) {
      _ws!.sendAnswer(_roomId, _peerUserId, answer.sdp!);
    }
  }

  Future<void> _handleAnswerReceived(String sdp) async {
    final session = RTCSessionDescription(sdp, 'answer');
    await _pc?.setRemoteDescription(session);
  }

  Future<void> _handleIceCandidateReceived(String candidate) async {
    final pc = _pc;
    if (pc == null) return;
    final map = jsonDecode(candidate) as Map<String, dynamic>;
    await pc.addCandidate(RTCIceCandidate(
      map['candidate'],
      map['sdpMid'],
      map['sdpMLineIndex'] as int?,
    ));
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    _pc!.onIceCandidate = (candidate) {
      if (_peerUserId > 0) {
        _ws!.sendIceCandidate(_roomId, _peerUserId, jsonEncode(candidate.toMap()));
      }
    };

    _pc!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        callState.value = CallState.connected;
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = CallState.connected;
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        callState.value = CallState.ended;
      }
    };
  }

  // ==================== 清理 ====================

  void _cleanup() {
    if (_disposed) return;
    _disposed = true;

    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    if (_roomId.isNotEmpty) {
      _ws!.leaveRoom(_roomId);
    }

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

    _peerUserId = 0;
    _handshakeStarted = false;
  }
}

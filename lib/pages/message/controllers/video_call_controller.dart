import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;

import '../../webrtc/models/call_state.dart';
import '../../webrtc/services/signaling_client.dart';

/// 简化版 1v1 视频通话控制器——消息聊天中的双人通话。
///
/// 复用全局 SignalingClient，房间名基于聊天对端用户名生成。
class VideoCallController extends GetxController {
  late final SignalingClient _signaling;

  // ==================== 信令相关 ====================
  String _roomId = '';
  String _myUid = '';
  String _serverUrl = '';
  String _peerUid = '';

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
    _signaling = Get.find<SignalingClient>();
    _setupListeners();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ==================== 公开 API ====================

  /// 发起 1v1 通话：先开摄像头，再连信令，加入房间
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
      await _getLocalMedia();
      await _createPeerConnection();
      await _signaling.connect(_serverUrl);
      _signaling.joinRoom(_roomId, _myUid);
      callState.value = CallState.connecting;
    } catch (e) {
      debugPrint('[VideoCall] startCall error: $e');
      callState.value = CallState.error;
    }
  }

  /// 挂断
  Future<void> endCall() async {
    _signaling.leaveRoom(_roomId);
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
    _subs.add(_signaling.onConnected.listen((_) {}));
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
      _handleOfferReceived(data.from, data.sdp).catchError((e) {
        debugPrint('[VideoCall] onOffer error: $e');
      });
    }));
    _subs.add(_signaling.onAnswer.listen((data) {
      _handleAnswerReceived(data.sdp);
    }));
    _subs.add(_signaling.onIceCandidate.listen((data) {
      _handleIceCandidateReceived(data.candidate);
    }));
    _subs.add(_signaling.onUserLeft.listen((_) {
      callState.value = CallState.ended;
    }));
    _subs.add(_signaling.onCallEnded.listen((_) {
      callState.value = CallState.ended;
    }));
    _subs.add(_signaling.onError.listen((_) {
      callState.value = CallState.error;
    }));
  }

  void _handlePeerReady(List<String> peers) {
    if (_handshakeStarted) return;
    if (peers.length < 2) return;
    _handshakeStarted = true;

    final others = peers.where((uid) => uid != _myUid).toList();
    if (others.isEmpty) return;
    _peerUid = others.first;

    // 按 UID 字典序，小的发 Offer
    final sorted = List<String>.from(peers)..sort();
    if (sorted.first == _myUid) {
      _createAndSendOffer();
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_pc == null) return;
    final session = await _pc!.createOffer();
    await _pc!.setLocalDescription(session);
    if (session.sdp != null) {
      _signaling.sendOffer(_peerUid, session.sdp!);
    }
  }

  Future<void> _handleOfferReceived(String fromUid, String sdp) async {
    _peerUid = fromUid;

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
      _signaling.sendAnswer(_peerUid, answer.sdp!);
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
      if (_peerUid.isNotEmpty) {
        _signaling.sendIceCandidate(_peerUid, jsonEncode(candidate.toMap()));
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
  }
}

import 'dart:async';
import 'dart:collection';
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

  /// 每个 peer 的克隆轨道（用于独立释放）
  final Map<String, List<MediaStreamTrack>> _clonedTracks = {};

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

  // ==================== 串行建连队列 ====================

  /// 待发起连接的 peer 队列
  final Queue<String> _pendingPeers = Queue<String>();

  /// 是否正在处理建连队列
  bool _isConnecting = false;

  // ==================== 防竞态保护 ====================

  /// 正在异步建连/应答中的 peer（_removePeer 等待其完成）
  final Set<String> _peersInProgress = {};

  /// 被 user-left 标记清理但尚在处理中的 peer
  final Set<String> _pendingRemovals = {};

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

  /// 发起呼叫：先获取本地媒体，再连接信令、加入房间
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
      await _signaling.connect(_serverUrl);
      _signaling.joinRoom(_roomId, _myUid);
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
    for (final tracks in _clonedTracks.values) {
      for (final track in tracks) {
        if (track.kind == 'audio') {
          track.enabled = isMicOn.value;
        }
      }
    }
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = isMicOn.value;
    }
  }

  /// 切换摄像头开关
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    isCameraOn.value = !isCameraOn.value;
    for (final tracks in _clonedTracks.values) {
      for (final track in tracks) {
        if (track.kind == 'video') {
          track.enabled = isCameraOn.value;
        }
      }
    }
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
          debugPrint('[Mesh] ❌ onOffer(${data.from}) 未捕获异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onAnswer.listen((data) {
        _handleAnswerReceived(data.from, data.sdp).catchError((e) {
          debugPrint('[Mesh] ❌ onAnswer(${data.from}) 未捕获异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onIceCandidate.listen((data) {
        _handleIceCandidateReceived(data.from, data.candidate).catchError((e) {
          debugPrint('[Mesh] ❌ onIceCandidate(${data.from}) 异常: $e');
        });
      }),
    );

    _subs.add(
      _signaling.onUserLeft.listen((uid) {
        _handleUserLeft(uid);
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

  /// user-left 到达，支持延迟清理（等待正在建连的异步过程完成）
  void _handleUserLeft(String uid) {
    if (_peersInProgress.contains(uid)) {
      // 该 peer 正在异步建连/应答中，标记延迟清理
      _pendingRemovals.add(uid);
      debugPrint('[Mesh] 🚫 user-left 延迟清理 | uid=$uid（建连进行中）');
      return;
    }
    _removePeer(uid);
    if (_pcs.isEmpty) {
      callState.value = CallState.ended;
    }
  }

  /// 标记 peer 进入建连/应答流程
  void _markInProgress(String uid) {
    _peersInProgress.add(uid);
  }

  /// 标记 peer 退出建连/应答流程，并消费延迟清理
  void _markDone(String uid) {
    _peersInProgress.remove(uid);
    if (_pendingRemovals.remove(uid)) {
      debugPrint('[Mesh] 🧹 消费延迟清理 | uid=$uid');
      _removePeer(uid);
      if (_pcs.isEmpty) {
        callState.value = CallState.ended;
      }
    }
  }

  /// peer-ready 到达后，将需要主动建连的 peer 加入串行队列
  void _handlePeerReady(List<String> peers) {
    debugPrint('[Mesh] 🔔 peer-ready 到达 | peers=${peers.join(", ")} | 已有PC=${_pcs.keys.toList()}');

    var queued = 0;
    for (final peerUid in peers) {
      if (peerUid == _myUid) continue;
      if (_pcs.containsKey(peerUid)) {
        debugPrint('[Mesh] ⏭️  跳过已有PC | peer=$peerUid');
        continue;
      }
      if (peerUid.compareTo(_myUid) > 0) {
        if (!_pendingPeers.contains(peerUid)) {
          _pendingPeers.add(peerUid);
          queued++;
          debugPrint('[Mesh] 📋 加入建连队列 | peer=$peerUid');
        }
      }
    }

    if (queued > 0) {
      debugPrint('[Mesh] 📋 队列新增 $queued 个 peer，当前队列=${_pendingPeers.toList()}');
    }

    if (!_isConnecting) {
      _connectNext();
    }
  }

  /// 与指定 peer 建立 PeerConnection
  Future<void> _establishConnection(
    String peerUid, {
    required bool initiator,
  }) async {
    _markInProgress(peerUid);
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _remoteRenderers[peerUid] = renderer;
      if (!remotePeerUids.contains(peerUid)) {
        remotePeerUids.add(peerUid);
      }

      final pc = await _createPeerConnectionForPeer(peerUid);
      _pcs[peerUid] = pc;
      debugPrint('[Mesh] ✅ PC 创建成功 | peer=$peerUid');

      if (initiator) {
        await _sendOffer(pc, peerUid);
        debugPrint('[Mesh] 📤 Offer 已发送 | peer=$peerUid');
      }
    } catch (e) {
      debugPrint('[Mesh] ❌ _establishConnection($peerUid) 异常: $e');
      _removePeerInternal(peerUid);
      rethrow;
    } finally {
      _markDone(peerUid);
    }
  }

  /// 为指定 peer 创建 RTCPeerConnection
  ///   clone() 可用时：每个 PC 独立轨道
  ///   clone() 不可用时：回退到 addTrack（使用原始轨道）
  Future<RTCPeerConnection> _createPeerConnectionForPeer(String peerUid) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    final tracks = <MediaStreamTrack>[];
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          final cloned = await track.clone();
          cloned.enabled = track.enabled;
          await pc.addTrack(cloned, _localStream!);
          tracks.add(cloned);
          debugPrint('[Mesh] 🎯 轨道克隆添加 | peer=$peerUid | kind=${cloned.kind}');
        } catch (e) {
          // ★ clone() 不可用时回退到 addTrack
          //   addTrack 会正确关联 stream（远端 onTrack 时 streams 非空）
          debugPrint('[Mesh] ⚠️ clone() 不支持，回退 addTrack | peer=$peerUid | kind=${track.kind}');
          await pc.addTrack(track, _localStream!);
          tracks.add(track);
        }
      }
      _clonedTracks[peerUid] = tracks;
    }

    // ICE Candidate
    pc.onIceCandidate = (candidate) {
      final candStr = candidate.candidate;
      if (candStr != null && candStr.isNotEmpty) {
        _signaling.sendIceCandidate(peerUid, jsonEncode(candidate.toMap()));
      }
    };

    // 远端流到达
    pc.onTrack = (event) {
      _onRemoteTrack(peerUid, event);
    };

    // 连接状态
    pc.onConnectionState = (state) {
      debugPrint('[Mesh] 🔗 连接状态变化 | peer=$peerUid | state=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = CallState.connected;
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        // ★ 不在建连过程中才清理，避免与 _handleOfferReceived 竞态
        if (!_peersInProgress.contains(peerUid)) {
          _removePeer(peerUid);
          if (_pcs.isEmpty) {
            callState.value = CallState.ended;
          }
        }
      }
    };

    return pc;
  }

  /// 处理远端轨道到达——包裹 try-catch 防止回调中异常被吞没
  void _onRemoteTrack(String peerUid, RTCTrackEvent event) {
    try {
      final kind = event.track.kind;
      debugPrint('[Mesh] 📺 onTrack | peer=$peerUid | kind=$kind | streams=${event.streams.length}');

      MediaStream? stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
      } else {
        // ★ streams 为空：用已有的远端流，没有则从 event 构造
        stream = _remoteStreams[peerUid];
        if (stream == null) {
          try {
            stream = createLocalMediaStream('remote_$peerUid') as MediaStream;
          } catch (_) {
            // createLocalMediaStream 返回类型不兼容时的兜底
            debugPrint('[Mesh] ⚠️  无法创建 MediaStream，跳过 onTrack 处理 | peer=$peerUid');
            return;
          }
        }
        stream.addTrack(event.track);
        debugPrint('[Mesh] ⚠️  streams 为空，手动构造 | peer=$peerUid');
      }

      _remoteStreams[peerUid] = stream;

      if (kind == 'video') {
        final renderer = _remoteRenderers[peerUid];
        if (renderer != null) {
          renderer.srcObject = stream;
          debugPrint('[Mesh] ✅ 视频渲染已绑定 | peer=$peerUid');
        }
      }

      callState.value = CallState.connected;
    } catch (e, stack) {
      debugPrint('[Mesh] ❌ onTrack 处理异常 | peer=$peerUid | $e\n$stack');
    }
  }

  /// 向指定对端发送 Offer
  Future<void> _sendOffer(RTCPeerConnection pc, String peerUid) async {
    final session = await pc.createOffer();
    await pc.setLocalDescription(session);
    if (session.sdp != null) {
      _signaling.sendOffer(peerUid, session.sdp!);
    }
  }

  /// 收到对端发来的 Offer（非发起方路径）
  Future<void> _handleOfferReceived(String fromUid, String sdp) async {
    debugPrint('[Mesh] 📩 收到 Offer | from=$fromUid | sdpLen=${sdp.length}');

    if (_pcs.containsKey(fromUid)) {
      try {
        final session = RTCSessionDescription(sdp, 'offer');
        await _pcs[fromUid]!.setRemoteDescription(session);
        await _sendAnswer(_pcs[fromUid]!, fromUid);
        debugPrint('[Mesh] 🔄 已有PC，重协商完毕 | peer=$fromUid');
      } catch (e) {
        debugPrint('[Mesh] ❌ onOffer($fromUid) 已有PC异常: $e');
      }
      return;
    }

    // ★ 标记为处理中，防止 user-left 在此期间关闭 PC
    _markInProgress(fromUid);
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _remoteRenderers[fromUid] = renderer;
      if (!remotePeerUids.contains(fromUid)) {
        remotePeerUids.add(fromUid);
      }

      final pc = await _createPeerConnectionForPeer(fromUid);
      _pcs[fromUid] = pc;

      // ★ 每个 await 后检查 PC 是否仍有效
      if (!_pcs.containsKey(fromUid)) {
        debugPrint('[Mesh] ⚠️  PC 在 async 期间已移除 | peer=$fromUid');
        return;
      }

      final session = RTCSessionDescription(sdp, 'offer');
      await pc.setRemoteDescription(session);

      if (!_pcs.containsKey(fromUid) ||
          pc.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        debugPrint('[Mesh] ⚠️  PC 已关闭，跳过应答 | peer=$fromUid');
        return;
      }

      await _sendAnswer(pc, fromUid);
      _flushBufferedCandidates(fromUid);

      debugPrint('[Mesh] ✅ 新建PC应答完毕 | peer=$fromUid');
    } catch (e, stack) {
      debugPrint('[Mesh] ❌ onOffer($fromUid) 新建PC异常: $e\n$stack');
      _removePeerInternal(fromUid);
    } finally {
      _markDone(fromUid);
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
    if (pc == null) {
      debugPrint('[Mesh] ⚠️  Answer 收到但 PC 不存在 | from=$fromUid');
      return;
    }
    debugPrint('[Mesh] 📥 收到 Answer | from=$fromUid | sdpLen=${sdp.length}');
    final session = RTCSessionDescription(sdp, 'answer');
    await pc.setRemoteDescription(session);
  }

  /// ICE candidate 缓冲
  final Map<String, List<Map<String, dynamic>>> _bufferedCandidates = {};

  /// 收到 ICE Candidate
  Future<void> _handleIceCandidateReceived(String fromUid, String candidate) async {
    final pc = _pcs[fromUid];
    if (pc == null) {
      final map = _parseIceCandidateMap(candidate);
      if (map != null) {
        _bufferedCandidates.putIfAbsent(fromUid, () => []);
        _bufferedCandidates[fromUid]!.add(map);
      }
      return;
    }
    await _addIceToPeer(pc, fromUid, candidate);
  }

  /// 消费缓冲的 ICE
  Future<void> _flushBufferedCandidates(String peerUid) async {
    final buffered = _bufferedCandidates.remove(peerUid);
    if (buffered == null || buffered.isEmpty) return;
    final pc = _pcs[peerUid];
    if (pc == null) return;

    debugPrint('[Mesh] 🧊 消费缓冲ICE | peer=$peerUid | 数量=${buffered.length}');
    for (final map in buffered) {
      try {
        final ice = RTCIceCandidate(map['candidate'] as String? ?? '', map['sdpMid'] as String?, map['sdpMLineIndex'] as int?);
        await pc.addCandidate(ice);
      } catch (e) {
        debugPrint('[Mesh] ⚠️  缓冲ICE添加失败 | peer=$peerUid | err=$e');
      }
    }
  }

  Map<String, dynamic>? _parseIceCandidateMap(String raw) {
    try {
      if (raw.trimLeft().startsWith('{')) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return {'candidate': raw, 'sdpMid': null, 'sdpMLineIndex': null};
    } catch (_) {
      return null;
    }
  }

  Future<void> _addIceToPeer(RTCPeerConnection pc, String fromUid, String raw) async {
    final map = _parseIceCandidateMap(raw);
    if (map == null) return;
    try {
      final iceCandidate = RTCIceCandidate(map['candidate'] as String? ?? '', map['sdpMid'] as String?, map['sdpMLineIndex'] as int?);
      await pc.addCandidate(iceCandidate);
    } catch (e) {
      debugPrint('[Mesh] ⚠️  addCandidate 失败 | from=$fromUid | err=$e');
    }
  }

  // ==================== Peer 清理 ====================

  /// 内部清理（不检查 _peersInProgress）——仅在 catch 块中使用
  void _removePeerInternal(String uid) {
    _doRemovePeer(uid);
  }

  /// 公开清理——检查是否正在处理中
  void _removePeer(String uid) {
    if (_peersInProgress.contains(uid)) {
      _pendingRemovals.add(uid);
      debugPrint('[Mesh] 🚫 延迟清理 | uid=$uid');
      return;
    }
    _doRemovePeer(uid);
  }

  void _doRemovePeer(String uid) {
    debugPrint('[Mesh] 🧹 清理 peer | uid=$uid');

    _pcs[uid]?.close();
    _pcs.remove(uid);

    _remoteStreams[uid]?.dispose();
    _remoteStreams.remove(uid);

    final tracks = _clonedTracks.remove(uid);
    if (tracks != null) {
      for (final t in tracks) {
        t.stop();
      }
    }

    final r = _remoteRenderers.remove(uid);
    if (r != null) {
      r.srcObject = null;
      r.dispose();
    }

    _bufferedCandidates.remove(uid);
    _pendingRemovals.remove(uid);
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

    for (final uid in _pcs.keys.toList()) {
      _doRemovePeer(uid);
    }

    _bufferedCandidates.clear();
    _clonedTracks.clear();
    _pendingPeers.clear();
    _peersInProgress.clear();
    _pendingRemovals.clear();

    debugPrint('[Mesh] 🧹 全局清理完毕');
  }

  // ==================== 串行建连队列处理 ====================

  Future<void> _connectNext() async {
    _connectNextImpl();
  }

  Future<void> _connectNextImpl() async {
    if (_isConnecting) return;
    if (_pendingPeers.isEmpty) {
      debugPrint('[Mesh] 📋 建连队列已空');
      return;
    }

    _isConnecting = true;
    final peerUid = _pendingPeers.removeFirst();
    debugPrint('[Mesh] 🔗 开始建连 | peer=$peerUid | 队列剩余=${_pendingPeers.length}');

    try {
      await _establishConnection(peerUid, initiator: true);
      _flushBufferedCandidates(peerUid);
    } catch (e) {
      debugPrint('[Mesh] ❌ 建连失败 | peer=$peerUid | err=$e');
      _removePeer(peerUid);
    } finally {
      _isConnecting = false;
      _connectNextImpl();
    }
  }
}

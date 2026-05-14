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
///
/// ★ 多 Peer 修复要点：
/// - 串行建立连接（队列），避免 flutter_webrtc 竞态
/// - 每个 PC 使用 clone() 独立轨道，消除跨 PC 共享副作用
/// - onTrack 处理空 streams + 音视频分离
/// - ICE candidate 缓冲（PC 未就绪时暂存，就绪后批量消费）
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
  /// （保证 Offer 到达时 _localStream 已就绪，避免无轨道建连）
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
      // 1. 先获取本地媒体（摄像头授权可能需要时间）
      await _getLocalMedia();
      // 2. 再连接信令服务器
      await _signaling.connect(_serverUrl);
      // 3. 最后加入房间，此时 _localStream 已就绪
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
    // 所有克隆轨道同步静音状态
    for (final tracks in _clonedTracks.values) {
      for (final track in tracks) {
        if (track.kind == 'audio') {
          track.enabled = isMicOn.value;
        }
      }
    }
    // 源轨道也更新
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = isMicOn.value;
    }
  }

  /// 切换摄像头开关
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    isCameraOn.value = !isCameraOn.value;
    // 所有克隆轨道同步摄像头状态
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

      // 字典序比较：比我大的我主动发 offer，比我小的等待对方发来
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

    // 串行处理建连队列
    if (!_isConnecting) {
      _connectNext();
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
    if (!remotePeerUids.contains(peerUid)) {
      remotePeerUids.add(peerUid);
    }

    try {
      final pc = await _createPeerConnectionForPeer(peerUid);
      _pcs[peerUid] = pc;
      debugPrint('[Mesh] ✅ PC 创建成功 | peer=$peerUid');

      if (initiator) {
        await _sendOffer(pc, peerUid);
        debugPrint('[Mesh] 📤 Offer 已发送 | peer=$peerUid');
      }
    } catch (e) {
      debugPrint('[Mesh] ❌ _establishConnection($peerUid) 异常: $e');
      _removePeer(peerUid);
      rethrow;
    }
  }

  /// 为指定 peer 创建 RTCPeerConnection，每个 PC 使用独立的克隆轨道
  Future<RTCPeerConnection> _createPeerConnectionForPeer(String peerUid) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(config);

    // ★ 核心修复：为每个 PC 克隆独立的音视频轨道
    //   避免同一 MediaStreamTrack 跨多个 PC 共享导致的竞态
    final tracks = <MediaStreamTrack>[];
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          // clone() 返回 Future<MediaStreamTrack>，必须 await
          final cloned = await track.clone();
          // 同步 mute 状态
          cloned.enabled = track.enabled;
          await pc.addTrack(cloned, _localStream!);
          tracks.add(cloned);
          debugPrint('[Mesh] 🎯 轨道克隆添加 | peer=$peerUid | kind=${cloned.kind}');
        } catch (e) {
          // clone() 不可用时回退到原始轨道（兼容旧版 flutter_webrtc）
          debugPrint('[Mesh] ⚠️ clone() 失败，使用原始轨道 | peer=$peerUid | err=$e');
          await pc.addTrack(track, _localStream!);
          tracks.add(track);
        }
      }
      _clonedTracks[peerUid] = tracks;
    }

    // ICE Candidate——发往指定对端
    pc.onIceCandidate = (candidate) {
      final candStr = candidate.candidate;
      if (candStr != null && candStr.isNotEmpty) {
        _signaling.sendIceCandidate(
          peerUid,
          jsonEncode(candidate.toMap()),
        );
      }
    };

    // 远端流到达——健壮处理空 streams 和音视频分离
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
        _removePeer(peerUid);
        if (_pcs.isEmpty) {
          callState.value = CallState.ended;
        }
      }
    };

    return pc;
  }

  /// 处理远端轨道到达——健壮处理各种边界情况
  void _onRemoteTrack(String peerUid, RTCTrackEvent event) {
    final kind = event.track.kind;
    debugPrint('[Mesh] 📺 onTrack | peer=$peerUid | kind=$kind | streams=${event.streams.length}');

    // 获取或创建远端流
    MediaStream stream;
    if (event.streams.isNotEmpty) {
      stream = event.streams[0];
    } else {
      // ★ streams 为空时的兜底：手动创建 MediaStream 并添加 track
      stream = _remoteStreams[peerUid] ?? (createLocalMediaStream('remote_$peerUid') as MediaStream);
      stream.addTrack(event.track);
      debugPrint('[Mesh] ⚠️  streams 为空，手动创建 MediaStream | peer=$peerUid');
    }

    _remoteStreams[peerUid] = stream;

    // 视频轨道：绑定到渲染器
    if (kind == 'video') {
      final renderer = _remoteRenderers[peerUid];
      if (renderer != null) {
        renderer.srcObject = stream;
        debugPrint('[Mesh] ✅ 视频渲染已绑定 | peer=$peerUid');
      } else {
        debugPrint('[Mesh] ⚠️  渲染器不存在（可能已被清理） | peer=$peerUid');
      }
    }

    // 任一轨道到达即认为已连接
    callState.value = CallState.connected;
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

    // 如果已有此对端的 PC（重协商），直接设置远端描述并应答
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

    // 首次收到此对端的 Offer，现场建连
    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _remoteRenderers[fromUid] = renderer;
      if (!remotePeerUids.contains(fromUid)) {
        remotePeerUids.add(fromUid);
      }

      // ★ 先创建 PC（包含轨道克隆），再设置远端描述
      //   确保 ICE candidate 到达时 _pcs[fromUid] 已就绪
      final pc = await _createPeerConnectionForPeer(fromUid);
      _pcs[fromUid] = pc;

      final session = RTCSessionDescription(sdp, 'offer');
      await pc.setRemoteDescription(session);
      await _sendAnswer(pc, fromUid);

      // 消费缓冲的 ICE candidates
      _flushBufferedCandidates(fromUid);

      debugPrint('[Mesh] ✅ 新建PC应答完毕 | peer=$fromUid');
    } catch (e, stack) {
      debugPrint('[Mesh] ❌ onOffer($fromUid) 新建PC异常: $e\n$stack');
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
    if (pc == null) {
      debugPrint('[Mesh] ⚠️  Answer 收到但 PC 不存在 | from=$fromUid');
      return;
    }
    debugPrint('[Mesh] 📥 收到 Answer | from=$fromUid | sdpLen=${sdp.length}');
    final session = RTCSessionDescription(sdp, 'answer');
    await pc.setRemoteDescription(session);
  }

  /// ICE candidate 缓冲（PC 尚未创建时暂存）
  final Map<String, List<Map<String, dynamic>>> _bufferedCandidates = {};

  /// 收到对端发来的 ICE Candidate——支持缓冲，PC 未就绪时暂存
  Future<void> _handleIceCandidateReceived(
    String fromUid,
    String candidate,
  ) async {
    final pc = _pcs[fromUid];
    if (pc == null) {
      // PC 尚未就绪：缓冲 ICE candidate，待 PC 创建后消费
      final map = _parseIceCandidateMap(candidate);
      if (map != null) {
        _bufferedCandidates.putIfAbsent(fromUid, () => []);
        _bufferedCandidates[fromUid]!.add(map);
        debugPrint('[Mesh] 🧊 ICE 缓冲 | from=$fromUid | 缓冲数=${_bufferedCandidates[fromUid]!.length}');
      }
      return;
    }
    await _addIceToPeer(pc, fromUid, candidate);
  }

  /// 消费某 peer 的缓冲 ICE candidates
  Future<void> _flushBufferedCandidates(String peerUid) async {
    final buffered = _bufferedCandidates.remove(peerUid);
    if (buffered == null || buffered.isEmpty) return;

    final pc = _pcs[peerUid];
    if (pc == null) return;

    debugPrint('[Mesh] 🧊 消费缓冲ICE | peer=$peerUid | 数量=${buffered.length}');
    for (final map in buffered) {
      try {
        final ice = RTCIceCandidate(
          map['candidate'] as String? ?? '',
          map['sdpMid'] as String?,
          map['sdpMLineIndex'] as int?,
        );
        await pc.addCandidate(ice);
      } catch (e) {
        debugPrint('[Mesh] ⚠️  缓冲ICE添加失败 | peer=$peerUid | err=$e');
      }
    }
  }

  Map<String, dynamic>? _parseIceCandidateMap(String raw) {
    try {
      // candidate 可能是 JSON 格式
      if (raw.trimLeft().startsWith('{')) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      // 也可能是 SDP 字符串格式，包装为 candidate 字段
      return {'candidate': raw, 'sdpMid': null, 'sdpMLineIndex': null};
    } catch (_) {
      return null;
    }
  }

  Future<void> _addIceToPeer(
    RTCPeerConnection pc,
    String fromUid,
    String raw,
  ) async {
    final map = _parseIceCandidateMap(raw);
    if (map == null) return;
    try {
      final iceCandidate = RTCIceCandidate(
        map['candidate'] as String? ?? '',
        map['sdpMid'] as String?,
        map['sdpMLineIndex'] as int?,
      );
      await pc.addCandidate(iceCandidate);
    } catch (e) {
      debugPrint('[Mesh] ⚠️  addCandidate 失败 | from=$fromUid | err=$e');
    }
  }

  // ==================== Peer 清理 ====================

  /// 移除指定 peer 的所有资源
  void _removePeer(String uid) {
    debugPrint('[Mesh] 🧹 清理 peer | uid=$uid');

    _pcs[uid]?.close();
    _pcs.remove(uid);

    _remoteStreams[uid]?.dispose();
    _remoteStreams.remove(uid);

    // 释放克隆轨道
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

    // 清理所有缓冲
    _bufferedCandidates.clear();
    _clonedTracks.clear();
    _pendingPeers.clear();

    debugPrint('[Mesh] 🧹 全局清理完毕');
  }

  // ==================== 串行建连队列处理 ====================

  /// 串行建连：逐个处理队列中的 peer，避免 flutter_webrtc 并发竞态
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
      // 建连成功后消费缓冲的 ICE candidates
      _flushBufferedCandidates(peerUid);
    } catch (e) {
      debugPrint('[Mesh] ❌ 建连失败 | peer=$peerUid | err=$e');
      _removePeer(peerUid);
    } finally {
      _isConnecting = false;
      // 继续处理下一个 peer
      _connectNextImpl();
    }
  }
}

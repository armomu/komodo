// =============================================================================
// video_call_controller.dart
//
// 1v1 视频通话的核心控制器，负责：
//   • 本地媒体采集（摄像头 + 麦克风）
//   • RTCPeerConnection 的创建与生命周期管理
//   • WebRTC 信令的发送与接收（Offer / Answer / ICE）
//   • 通话状态机（idle → waiting/calling → connecting → connected → ended）
//   • 渲染器的初始化与释放
//   • 通话计时（connected 后启动，每秒更新 callDuration）
//   • 网络质量监控（connected 后每3秒采集 RTT/丢包率，输出 networkQuality）
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart'
    hide navigator; // 隐藏 Get 的 navigator，使用 flutter_webrtc 的 navigator
import 'package:komodo/pages/message/models/chat_models.dart';

import 'consumer_ws_client.dart';
import '../../../controllers/user_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 网络质量枚举
// ─────────────────────────────────────────────────────────────────────────────

/// 网络质量等级，根据 RTT 和丢包率综合判定
enum NetworkQuality {
  /// 网络良好：RTT < 150ms 且丢包率 < 3%
  good,

  /// 网络一般：RTT < 300ms 且丢包率 < 8%
  fair,

  /// 网络较差：RTT ≥ 300ms 或丢包率 ≥ 8%
  poor,

  /// 未知：通话未建立或尚未采集到数据
  unknown,
}

/// ## VideoCallController
///
/// 1v1 视频通话控制器——使用 [ConsumerWsClient] 作为信令通道。
///
/// ### 整体流程（呼叫方）
/// ```
/// startAsCaller()
///   └─ _getLocalMedia()           // 采集本地摄像头/麦克风
///   └─ _createPeerConnection()    // 创建 RTCPeerConnection，挂上本地流
///
/// (等待对方接受 video-call-accept 事件)
///
/// onVideoCallAccept 触发
///   └─ ws.joinRoom(roomId)        // 加入信令房间
///   └─ (等 peer-ready 事件)
///
/// onPeerReady 触发（房间双方都已就绪）
///   └─ _handlePeerReady()
///       └─ [userId 较小的一方] _createAndSendOffer()
///           └─ pc.createOffer()
///           └─ pc.setLocalDescription()
///           └─ ws.sendOffer()     → 后端转发给对方
///
/// onOffer 触发（对方收到 Offer）
///   └─ _handleOfferReceived()
///       └─ pc.setRemoteDescription(offer)
///       └─ _createAndSendAnswer()
///           └─ pc.createAnswer()
///           └─ pc.setLocalDescription()
///           └─ ws.sendAnswer()    → 后端转发给对方
///
/// onAnswer 触发（呼叫方收到 Answer）
///   └─ pc.setRemoteDescription(answer)
///
/// onIceCandidate（双方互发 ICE candidate，打洞）
///   └─ pc.addCandidate()
///
/// pc.onTrack（远端视频流到达）
///   └─ remoteRenderer.srcObject = remoteStream
///   └─ callState → connected  ✓  通话建立
///   └─ _startCallTimer()      开始通话计时
///   └─ _startNetworkMonitor() 开始网络质量采集
/// ```
///
/// ### 整体流程（被叫方）
/// ```
/// acceptCall() ← 用户在来电界面点击"接听"
///   └─ ws.sendVideoCallAccept()
///   └─ startAsCallee()
///
/// startAsCallee()
///   └─ _getLocalMedia()
///   └─ _createPeerConnection()
///   └─ ws.joinRoom(roomId)        // 直接加入（已接受邀请）
///   └─ callState → connecting
///
/// (后续流程同呼叫方 peer-ready 之后)
/// ```
class VideoCallController extends GetxController {
  /// WebSocket 信令客户端（全局单例，通过 GetX 服务容器获取）
  ConsumerWsClient? _ws;

  // ==================== 信令标识 ====================

  /// 对方的用户 ID（服务端数据库 userId）
  int _peerUserId = 0;

  /// 通话房间 ID（由邀请方生成，格式通常为 "call_<timestamp>"）
  String _roomId = '';

  /// 是否是主叫方（主叫方需要等 video-call-accept 后再加入房间）
  bool _isCaller = false;

  // ==================== WebRTC 核心对象 ====================

  /// WebRTC 点对点连接对象，负责媒体协商、传输、ICE 打洞
  RTCPeerConnection? _pc;

  /// 本地媒体流（包含摄像头视频轨 + 麦克风音频轨）
  MediaStream? _localStream;

  /// 远端媒体流（收到对方的视频/音频轨后赋值）
  MediaStream? _remoteStream;

  // ==================== 视频渲染器 ====================

  /// 本地摄像头画面渲染器（小画中画，显示自己）
  final localRenderer = RTCVideoRenderer();

  /// 远端视频流渲染器（主画面，显示对方）
  final remoteRenderer = RTCVideoRenderer();

  // ==================== 响应式状态（UI 监听）====================

  /// 通话状态机（UI 根据此值显示不同界面）
  ///
  /// 状态流转：
  /// - idle → waiting（主叫等待对方接听）
  /// - idle → incoming（被叫收到来电，显示接听界面）
  /// - incoming → connecting（被叫接听后开始建连）
  /// - waiting/connecting → connected（WebRTC 媒体通道建立）
  /// - any → ended（挂断 / 对方拒绝 / 连接断开）
  /// - any → error（媒体获取失败等异常）
  final callState = CallState.idle.obs;

  /// 摄像头是否开启（可通过 toggleCamera() 切换）
  final isCameraOn = true.obs;

  /// 麦克风是否开启（可通过 toggleMic() 切换）
  final isMicOn = true.obs;

  // ==================== 通话计时 ====================

  /// 通话已持续时长（connected 后每秒 +1）
  ///
  /// UI 展示格式：[formattedDuration]
  final callDuration = 0.obs;

  /// 通话计时器（connected 时启动，cleanup 时取消）
  Timer? _callTimer;

  // ==================== 网络质量 ====================

  /// 当前网络质量等级（UI 根据此值显示信号图标颜色）
  ///
  /// - [NetworkQuality.good]  → 绿色信号格
  /// - [NetworkQuality.fair]  → 黄色信号格
  /// - [NetworkQuality.poor]  → 红色信号格
  final networkQuality = NetworkQuality.unknown.obs;

  /// 上一次采集到的总发送丢包数（用于计算增量丢包率）
  int _lastPacketsLost = 0;

  /// 上一次采集到的总发送包数（用于计算增量丢包率）
  int _lastPacketsSent = 0;

  /// 网络质量采集定时器（每3秒采集一次 RTT + 丢包率）
  Timer? _networkTimer;

  // ==================== 内部订阅 & 标志位 ====================

  /// 所有 WS Stream 订阅的引用，便于 dispose 时统一取消
  final List<StreamSubscription> _subs = [];

  /// 防止 _cleanup() 被重复执行的标志位
  bool _disposed = false;

  /// 防止 peer-ready 触发多次 Offer 的标志位
  bool _handshakeStarted = false;

  // ==================== 计算属性 ====================

  /// 将通话秒数格式化为 "MM:SS" 或 "HH:MM:SS" 字符串
  ///
  /// 示例：65 → "01:05"，3665 → "01:01:05"
  String get formattedDuration {
    final secs = callDuration.value;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ==================== 生命周期 ====================

  /// 在 UI 渲染前必须先调用此方法初始化渲染器（分配 OpenGL 纹理）
  ///
  /// 通常在 [VideoCallPage.initState] 中调用：
  /// ```dart
  /// await controller.initRenderers();
  /// ```
  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// GetX 控制器初始化入口
  ///
  /// 1. 从 GetX 服务容器中获取 [ConsumerWsClient] 单例
  /// 2. 注册所有 WS 事件监听（Offer/Answer/ICE/通话接受/拒绝等）
  @override
  void onInit() {
    super.onInit();
    _ws = Get.find<ConsumerWsClient>();
    _setupListeners();
  }

  /// GetX 控制器销毁时的回调（页面关闭 / Get.back() 触发）
  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ==================== 公开 API ====================

  /// 【主叫方入口】发起一次视频通话
  ///
  /// 执行步骤：
  /// 1. 记录对方 userId、roomId，标记 isCaller = true
  /// 2. 状态切换为 [CallState.waiting]（UI 显示"等待对方接听"）
  /// 3. 提前采集本地摄像头/麦克风（让用户提前看到自己）
  /// 4. 提前创建 RTCPeerConnection（对方一接受就能立即 Offer）
  ///
  /// 注意：此时并不加入信令房间，要等收到 video-call-accept 后再加入
  Future<void> startAsCaller({
    required int peerUserId,
    required String roomId,
  }) async {
    _peerUserId = peerUserId;
    _roomId = roomId;
    _isCaller = true;
    callState.value = CallState.waiting;

    try {
      await _getLocalMedia();
      await _createPeerConnection();
    } catch (e) {
      debugPrint('[VideoCall] startAsCaller prepare error: $e');
      callState.value = CallState.error;
    }
  }

  /// 【被叫方入口】接听来电（由来电界面"接听"按钮触发）
  ///
  /// 执行步骤：
  /// 1. 通过 WS 发送 video-call-accept 通知对方（主叫方收到后才加入房间）
  /// 2. 记录对方 userId / roomId，标记 isCaller = false
  /// 3. 采集本地摄像头/麦克风
  /// 4. 创建 RTCPeerConnection
  /// 5. 加入信令房间，通知后端双方都已就绪
  /// 6. 状态切换为 [CallState.connecting]
  Future<void> acceptCall({
    required int peerUserId,
    required String roomId,
  }) async {
    // 先告知对方已接受，主叫方收到后才会 joinRoom
    _ws!.sendVideoCallAccept(peerUserId, roomId);

    _peerUserId = peerUserId;
    _roomId = roomId;
    _isCaller = false;

    try {
      await _getLocalMedia();
      await _createPeerConnection();
      _ws!.joinRoom(_roomId);
      callState.value = CallState.connecting;
    } catch (e) {
      debugPrint('[VideoCall] acceptCall error: $e');
      callState.value = CallState.error;
    }
  }

  /// 【被叫方】拒绝来电
  ///
  /// 向对方发送 video-call-reject 信令，然后关闭页面
  Future<void> rejectCall({
    required int peerUserId,
    required String roomId,
  }) async {
    _ws!.sendVideoCallReject(peerUserId, roomId);
    callState.value = CallState.ended;
  }

  /// 挂断通话
  ///
  /// 1. 通知服务端离开房间（leaveRoom）
  /// 2. 向对方发送 end-call 信令
  /// 3. 执行本地清理（媒体流/连接/渲染器释放）
  /// 4. 状态切换为 [CallState.ended]
  Future<void> endCall() async {
    if (_roomId.isNotEmpty && _peerUserId > 0) {
      _ws!.leaveRoom(_roomId);
      _ws!.sendEndCall(_roomId, _peerUserId);
    }
    _cleanup();
    callState.value = CallState.ended;
  }

  /// 切换麦克风静音/开启
  Future<void> toggleMic() async {
    if (_localStream == null) return;
    isMicOn.value = !isMicOn.value;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = isMicOn.value;
    }
  }

  /// 切换摄像头开启/关闭（遮黑画面，不重协商）
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    isCameraOn.value = !isCameraOn.value;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = isCameraOn.value;
    }
  }

  /// 翻转摄像头（前置 ↔ 后置）
  Future<void> switchCamera() async {
    if (_localStream != null) {
      await Helper.switchCamera(_localStream!.getVideoTracks().first);
    }
  }

  // ==================== 内部实现 ====================

  /// 采集本地摄像头和麦克风，绑定到 [localRenderer]
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

  /// 注册所有来自 [ConsumerWsClient] 的 WebRTC / 通话事件监听
  void _setupListeners() {
    if (_ws == null) return;

    // peer-ready：服务端检测到房间内已有 ≥2 个用户时推送
    // userId 较小的一方负责发 Offer
    _subs.add(
      _ws!.onPeerReady.listen((data) {
        _handlePeerReady(data.peers);
      }),
    );

    // offer：收到对方的 SDP Offer
    _subs.add(
      _ws!.onOffer.listen((data) {
        _handleOfferReceived(data.from, data.sdp).catchError((e) {
          debugPrint('[VideoCall] onOffer error: $e');
        });
      }),
    );

    // answer：收到对方的 SDP Answer，完成 SDP 交换
    _subs.add(
      _ws!.onAnswer.listen((data) {
        _handleAnswerReceived(data.sdp);
      }),
    );

    // ice-candidate：收到对方的网络候选地址，addCandidate 进行 ICE 打洞
    _subs.add(
      _ws!.onIceCandidate.listen((data) {
        _handleIceCandidateReceived(data.candidate);
      }),
    );

    // user-left：对方离开了信令房间（网络断开 / 意外退出）
    _subs.add(
      _ws!.onUserLeft.listen((_) {
        if (callState.value == CallState.connected) {
          callState.value = CallState.ended;
        }
      }),
    );

    // call-ended：对方主动发送了 end-call 信令（点击挂断按钮）
    _subs.add(
      _ws!.onCallEnded.listen((_) {
        callState.value = CallState.ended;
      }),
    );

    // video-call-accept：【仅主叫方处理】对方接听了来电
    // 主叫方此时才加入信令房间，触发 peer-ready → Offer 流程
    _subs.add(
      _ws!.onVideoCallAccept.listen((data) {
        if (_isCaller && data.from == _peerUserId && data.roomId == _roomId) {
          debugPrint('[VideoCall] 对方接受了邀请，开始连接');
          callState.value = CallState.connecting;
          _ws!.joinRoom(_roomId);
        }
      }),
    );

    // video-call-reject：【仅主叫方处理】对方拒绝了来电
    _subs.add(
      _ws!.onVideoCallReject.listen((data) {
        if (_isCaller && data.from == _peerUserId && data.roomId == _roomId) {
          debugPrint('[VideoCall] 对方拒绝了邀请');
          callState.value = CallState.ended;
        }
      }),
    );
  }

  /// 处理 peer-ready：决定谁先发 Offer（userId 最小的一方）
  void _handlePeerReady(List<int> peers) {
    if (_handshakeStarted) return;
    if (peers.length < 2) return;
    _handshakeStarted = true;

    final myUserId = UserController.to.userId;
    final others = peers.where((uid) => uid != myUserId).toList();
    if (others.isEmpty) return;
    _peerUserId = others.first;

    final sorted = List<int>.from(peers)..sort();
    if (sorted.first == myUserId) {
      _createAndSendOffer();
    }
  }

  /// 创建 SDP Offer 并通过 WS 发送给对方
  Future<void> _createAndSendOffer() async {
    if (_pc == null) return;
    final session = await _pc!.createOffer();
    await _pc!.setLocalDescription(session);
    if (session.sdp != null) {
      _ws!.sendOffer(_roomId, _peerUserId, session.sdp!);
    }
  }

  /// 处理收到的 SDP Offer
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

  /// 创建 SDP Answer 并通过 WS 发送给对方
  Future<void> _createAndSendAnswer() async {
    if (_pc == null) return;
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    if (answer.sdp != null) {
      _ws!.sendAnswer(_roomId, _peerUserId, answer.sdp!);
    }
  }

  /// 处理收到的 SDP Answer
  Future<void> _handleAnswerReceived(String sdp) async {
    final session = RTCSessionDescription(sdp, 'answer');
    await _pc?.setRemoteDescription(session);
  }

  /// 处理收到的 ICE candidate（网络候选地址）
  Future<void> _handleIceCandidateReceived(String candidate) async {
    final pc = _pc;
    if (pc == null) return;
    final map = jsonDecode(candidate) as Map<String, dynamic>;
    await pc.addCandidate(
      RTCIceCandidate(
        map['candidate'],
        map['sdpMid'],
        map['sdpMLineIndex'] as int?,
      ),
    );
  }

  /// 创建 RTCPeerConnection 并完成基础配置
  ///
  /// STUN 服务器：Google 公共 STUN，用于 NAT 穿透时发现外网 IP/端口
  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);

    // 将本地轨道加入 PC
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    // ICE candidate 收集回调：边收集边发送，降低建连延迟
    _pc!.onIceCandidate = (candidate) {
      if (_peerUserId > 0) {
        _ws!.sendIceCandidate(
          _roomId,
          _peerUserId,
          jsonEncode(candidate.toMap()),
        );
      }
    };

    // 远端媒体轨道到达：绑定渲染器，并启动计时 + 网络监控
    _pc!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        callState.value = CallState.connected;
        _startCallTimer(); // 通话建立 → 开始计时
        _startNetworkMonitor(); // 通话建立 → 开始网络质量采集
      }
    };

    // PC 连接状态监听
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = CallState.connected;
        _startCallTimer();
        _startNetworkMonitor();
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        callState.value = CallState.ended;
      }
    };
  }

  // ==================== 通话计时 ====================

  /// 启动通话计时器（幂等：已启动则跳过）
  ///
  /// connected 后调用，每秒递增 [callDuration]
  void _startCallTimer() {
    if (_callTimer != null) return; // 防止重复启动（onTrack 与 onConnectionState 均可能触发）
    callDuration.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) callDuration.value++;
    });
  }

  /// 停止并重置通话计时器
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  // ==================== 网络质量监控 ====================

  /// 启动网络质量采集定时器（幂等：已启动则跳过）
  ///
  /// 每3秒调用 [_collectNetworkStats] 采集 RTT 和丢包率
  void _startNetworkMonitor() {
    if (_networkTimer != null) return;
    _networkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _collectNetworkStats();
    });
  }

  /// 停止网络质量采集
  void _stopNetworkMonitor() {
    _networkTimer?.cancel();
    _networkTimer = null;
  }

  /// 采集 WebRTC 统计数据并更新 [networkQuality]
  ///
  /// 指标来源：RTCPeerConnection.getStats()
  ///
  /// 采集策略：
  /// - RTT（往返延迟）：从 `remote-inbound-rtp` 报告中取 `roundTripTime`（单位秒）
  /// - 丢包率：（本次采集增量丢包数）/ （本次采集增量发送数）× 100%
  ///   使用增量计算而非累计值，反映"当前一段时间"的质量而非历史平均
  ///
  /// 判定规则：
  /// | 等级 | RTT (ms)  | 丢包率  |
  /// |------|-----------|--------|
  /// | good | < 150     | < 3%   |
  /// | fair | 150~299   | 3~7%   |
  /// | poor | ≥ 300     | ≥ 8%   |
  Future<void> _collectNetworkStats() async {
    final pc = _pc;
    if (pc == null || _disposed) return;

    try {
      final stats = await pc.getStats();

      double rttMs = -1;
      int totalPacketsSent = 0;
      int totalPacketsLost = 0;

      for (final report in stats) {
        final values = report.values;

        // RTT：从 remote-inbound-rtp 类型报告中读取 roundTripTime（单位：秒）
        if (report.type == 'remote-inbound-rtp') {
          final rtt = values['roundTripTime'];
          if (rtt != null) {
            final rttSec = (rtt as num).toDouble();
            if (rttSec >= 0) rttMs = rttSec * 1000; // 秒 → 毫秒
          }
        }

        // 丢包率：从 outbound-rtp 报告中读取 packetsSent + packetsLost
        if (report.type == 'outbound-rtp') {
          final sent = values['packetsSent'];
          final lost = values['packetsLost'];
          if (sent != null) totalPacketsSent += (sent as num).toInt();
          if (lost != null) totalPacketsLost += (lost as num).toInt();
        }
      }

      // 计算增量丢包率（避免历史累积导致数值失真）
      final deltaSent = totalPacketsSent - _lastPacketsSent;
      final deltaLost = totalPacketsLost - _lastPacketsLost;
      _lastPacketsSent = totalPacketsSent;
      _lastPacketsLost = totalPacketsLost;

      final lossRate = (deltaSent > 0) ? (deltaLost / deltaSent * 100) : 0.0;

      debugPrint(
        '[VideoCall] 网络质量采集 RTT=${rttMs.toStringAsFixed(1)}ms loss=${lossRate.toStringAsFixed(1)}%',
      );

      // 综合判定质量等级
      networkQuality.value = _judgeQuality(rttMs, lossRate);
    } catch (e) {
      debugPrint('[VideoCall] getStats error: $e');
    }
  }

  /// 根据 RTT 和丢包率判定网络质量等级
  ///
  /// 任一指标达到较差阈值则判定为对应等级（取较差的一方）
  NetworkQuality _judgeQuality(double rttMs, double lossRate) {
    // RTT 未采集到（-1）时仅靠丢包率判断
    final rttScore = rttMs < 0
        ? NetworkQuality
              .good // RTT 无数据时不降级
        : rttMs < 150
        ? NetworkQuality.good
        : rttMs < 300
        ? NetworkQuality.fair
        : NetworkQuality.poor;

    final lossScore = lossRate < 3
        ? NetworkQuality.good
        : lossRate < 8
        ? NetworkQuality.fair
        : NetworkQuality.poor;

    // 取两者中较差的等级
    final scores = [rttScore, lossScore];
    if (scores.contains(NetworkQuality.poor)) return NetworkQuality.poor;
    if (scores.contains(NetworkQuality.fair)) return NetworkQuality.fair;
    return NetworkQuality.good;
  }

  // ==================== 资源清理 ====================

  /// 完整资源清理（幂等——多次调用安全）
  ///
  /// 执行顺序：
  /// 1. 停止通话计时器
  /// 2. 停止网络质量采集
  /// 3. 取消所有 WS 事件订阅
  /// 4. 通知服务端离开房间
  /// 5. 停止并释放本地媒体流
  /// 6. 释放远端媒体流
  /// 7. 解绑并释放视频渲染器
  /// 8. 关闭 RTCPeerConnection
  /// 9. 重置内部状态
  void _cleanup() {
    if (_disposed) return;
    _disposed = true;

    // 1. 停止计时器
    _stopCallTimer();

    // 2. 停止网络监控
    _stopNetworkMonitor();

    // 3. 取消所有 WS 订阅
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();

    // 4. 通知服务端离开房间
    if (_roomId.isNotEmpty) {
      _ws!.leaveRoom(_roomId);
    }

    // 5. 停止并释放本地媒体流
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    // 6. 释放远端媒体流
    _remoteStream?.dispose();
    _remoteStream = null;

    // 7. 解绑并释放渲染器
    localRenderer.srcObject = null;
    localRenderer.dispose();
    remoteRenderer.srcObject = null;
    remoteRenderer.dispose();

    // 8. 关闭 RTCPeerConnection
    _pc?.close();
    _pc = null;

    // 9. 重置状态
    _peerUserId = 0;
    _handshakeStarted = false;
    _lastPacketsSent = 0;
    _lastPacketsLost = 0;
  }
}

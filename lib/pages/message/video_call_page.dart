import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import 'controllers/video_call_controller.dart';
import 'widgets/call_control_bar.dart';
import 'widgets/call_ended_overlay.dart';
import 'widgets/call_top_bar.dart';
import 'widgets/connecting_overlay.dart';
import 'widgets/error_overlay.dart';
import 'widgets/incoming_call_overlay.dart';
import 'widgets/local_video_view.dart';
import 'widgets/rejected_overlay.dart';
import 'widgets/remote_video_view.dart';
import 'widgets/waiting_overlay.dart';

/// 1v1 视频通话页面（基于 ConsumerWsClient）
///
/// 参数通过 Get.arguments 传入 Map:
///   - peerUserId: int,    对方 userId
///   - peerName: String,   对方昵称
///   - roomId: String,     通话房间标识
///   - isCaller: bool,     是否主动呼叫方（默认 true）
///
/// ### 被叫方流程变化
/// 旧流程：ConsumerWsClient 自动调用 sendVideoCallAccept + startAsCallee
/// 新流程：跳转到此页面 → 显示 [IncomingCallOverlay] → 用户手动点击接听/拒绝
///          接听 → controller.acceptCall()
///          拒绝 → controller.rejectCall() → 返回上一页
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final VideoCallController _controller;
  late final int _peerUserId;
  late final String _roomId;
  late final String _peerName;
  late final bool _isCaller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    _peerUserId = args['peerUserId'] as int;
    _peerName = args['peerName'] as String? ?? '';
    _roomId = args['roomId'] as String;
    _isCaller = args['isCaller'] as bool? ?? true;

    _controller = Get.put(VideoCallController(), permanent: true);

    if (_isCaller) {
      // 主叫方：初始化渲染器后立即开始呼叫（等待对方接听）
      _controller.initRenderers().then((_) {
        _controller.startAsCaller(peerUserId: _peerUserId, roomId: _roomId);
      });
    } else {
      // 被叫方：初始化渲染器即可，等用户点击"接听"后再调用 acceptCall()
      // 此时页面会展示 IncomingCallOverlay，状态保持 idle
      _controller.initRenderers();
    }
  }

  @override
  void dispose() {
    Get.delete<VideoCallController>(force: true);
    super.dispose();
  }

  /// 用户点击挂断 / 返回键时调用
  Future<void> _handleBack() async {
    await _controller.endCall();
    Get.back();
  }

  /// 被叫方点击"接听"
  Future<void> _handleAccept() async {
    await _controller.acceptCall(peerUserId: _peerUserId, roomId: _roomId);
  }

  /// 被叫方点击"拒绝"
  Future<void> _handleReject() async {
    await _controller.rejectCall(peerUserId: _peerUserId, roomId: _roomId);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (_controller.callState.value == CallState.ended) {
            Get.back();
            return;
          }
          await _controller.endCall();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Obx(() {
            final state = _controller.callState.value;

            // ── 被叫方来电接听界面（用户尚未操作）──
            // 仅当被叫方且状态为 idle 时展示
            if (!_isCaller && state == CallState.idle) {
              return IncomingCallOverlay(
                peerName: _peerName,
                onAccept: _handleAccept,
                onReject: _handleReject,
              );
            }

            // ── 主叫方：对方拒绝后显示提示并自动返回 ──
            if (state == CallState.ended && _isCaller) {
              return RejectedOverlay(peerName: _peerName);
            }

            // ── 通话主界面（等待 / 建连 / 通话中 / 结束 / 错误）──
            return Stack(
              children: [
                // 远端视频（背景层）
                Positioned.fill(
                  child: RemoteVideoView(
                    controller: _controller,
                    peerName: _peerName,
                  ),
                ),

                // 等待对方接受（主叫方 waiting 状态）
                if (state == CallState.waiting)
                  Positioned.fill(
                    child: WaitingOverlay(
                      peerName: _peerName,
                      onHangUp: _handleBack,
                    ),
                  ),

                // 本地画中画（右上角小窗）
                Positioned(
                  top: 12,
                  right: 12,
                  width: 100,
                  height: 150,
                  child: LocalVideoView(controller: _controller),
                ),

                // 顶部栏（返回按钮 + 对方昵称）
                Positioned(
                  top: 12,
                  left: 12,
                  child: CallTopBar(peerName: '', onBack: _handleBack),
                ),

                // ── 通话中：计时 + 网络质量指示器 ──
                if (state == CallState.connected)
                  Positioned(
                    top: 174, // 在 CallTopBar 下方
                    right: 12,
                    child: _CallStatusBar(controller: _controller),
                  ),

                // 连接中（building ICE / waiting peer-ready）
                if (state == CallState.calling || state == CallState.connecting)
                  Positioned.fill(
                    child: ConnectingOverlay(peerName: _peerName),
                  ),

                // 通话结束
                if (state == CallState.ended)
                  const Positioned.fill(child: CallEndedOverlay()),

                // 异常
                if (state == CallState.error)
                  const Positioned.fill(child: ErrorOverlay()),

                // 底部控制栏（通话中 & 建连中均可操作）
                if (state == CallState.connected ||
                    state == CallState.connecting)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: CallControlBar(
                      controller: _controller,
                      onHangUp: _handleBack,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部组件：通话计时 + 网络质量指示器
// ─────────────────────────────────────────────────────────────────────────────

/// 通话中状态栏：左侧显示计时，右侧显示网络质量信号格
///
/// 仅在 [CallState.connected] 时由 [VideoCallPage] 展示
class _CallStatusBar extends StatelessWidget {
  final VideoCallController controller;

  const _CallStatusBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 通话计时 ──
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Obx(
            () => Text(
              controller.formattedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── 网络质量信号格 ──
          Obx(
            () => _NetworkQualityIcon(quality: controller.networkQuality.value),
          ),
        ],
      ),
    );
  }
}

/// 网络质量信号格图标
///
/// 用三条竖线模拟信号格：
/// - good  → 三格全绿
/// - fair  → 两格黄色
/// - poor  → 一格红色
/// - unknown → 三格灰色
class _NetworkQualityIcon extends StatelessWidget {
  final NetworkQuality quality;

  const _NetworkQualityIcon({required this.quality});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final int activeBars;
    final String label;

    switch (quality) {
      case NetworkQuality.good:
        color = const Color(0xFF4CAF50); // 绿色
        activeBars = 3;
        label = '信号良好';
      case NetworkQuality.fair:
        color = const Color(0xFFFFB300); // 黄色
        activeBars = 2;
        label = '信号一般';
      case NetworkQuality.poor:
        color = const Color(0xFFF44336); // 红色
        activeBars = 1;
        label = '信号较差';
      case NetworkQuality.unknown:
        color = Colors.white38;
        activeBars = 0;
        label = '';
    }

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final isActive = i < activeBars;
          final barHeight = 6.0 + i * 3.0; // 递增高度：6 / 9 / 12
          return Container(
            width: 4,
            height: barHeight,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: isActive ? color : Colors.white24,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}

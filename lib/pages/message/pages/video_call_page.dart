import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../webrtc/models/call_state.dart';
import '../controllers/video_call_controller.dart';

/// 1v1 视频通话页面（基于 ConsumerWsClient）
///
/// 参数通过 Get.arguments 传入 Map:
///   - peerUserId: int, 对方 userId
///   - peerName: String, 对方昵称
///   - roomId: String, 通话房间标识
///   - isCaller: bool, 是否主动呼叫方（默认 true）
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
    _controller.initRenderers().then((_) {
      if (_isCaller) {
        _controller.startAsCaller(
          peerUserId: _peerUserId,
          roomId: _roomId,
        );
      } else {
        _controller.startAsCallee(
          peerUserId: _peerUserId,
          roomId: _roomId,
        );
      }
    });
  }

  @override
  void dispose() {
    Get.delete<VideoCallController>(force: true);
    super.dispose();
  }

  Future<void> _handleBack() async {
    await _controller.endCall();
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

            // 被拒绝 → 显示提示后自动返回
            if (state == CallState.ended && _isCaller) {
              return _buildRejectedOverlay();
            }

            // 等待对方接受
            if (state == CallState.waiting) {
              return _buildWaitingOverlay();
            }

            return Stack(
              children: [
                // 远端视频
                Positioned.fill(child: _buildRemoteVideo()),

                // 本地面中画
                Positioned(
                  top: 12,
                  right: 12,
                  width: 100,
                  height: 150,
                  child: _buildLocalVideo(),
                ),

                // 顶部栏
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildTopBar(),
                ),

                // 连接中
                if (state == CallState.calling ||
                    state == CallState.connecting)
                  Positioned.fill(child: _buildConnectingOverlay()),

                // 已挂断
                if (state == CallState.ended)
                  Positioned.fill(child: _buildEndedOverlay()),

                // 错误
                if (state == CallState.error)
                  Positioned.fill(child: _buildErrorOverlay()),

                // 底部控制栏
                if (state == CallState.connected ||
                    state == CallState.connecting)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: _buildControls(state),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---- 等待对方接受 ----

  Widget _buildWaitingOverlay() {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          Text(
            '正在呼叫 $_peerName...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '等待对方接受视频通话',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: IconButton(
              onPressed: _handleBack,
              icon: const Icon(Icons.call_end, color: Colors.white, size: 36),
              iconSize: 36,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 被拒绝 ----

  Widget _buildRejectedOverlay() {
    // 2秒后自动返回
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Get.back();
    });

    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_disabled, color: Colors.white54, size: 64),
          const SizedBox(height: 24),
          Text(
            '$_peerName 拒绝了通话',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '即将返回...',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---- 连接中 ----

  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            '正在连接...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待 $_peerName 加入...',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---- 通话结束 ----

  Widget _buildEndedOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call_end, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          const Text(
            '通话已结束',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }

  // ---- 错误 ----

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          const Text(
            '连接失败',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }

  // ---- 视频渲染 ----

  Widget _buildRemoteVideo() {
    return Obx(() {
      if (_controller.callState.value == CallState.connected) {
        return Stack(
          children: [
            RTCVideoView(
              _controller.remoteRenderer,
              mirror: false,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _peerName,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      }
      return const ColoredBox(color: Colors.black);
    });
  }

  Widget _buildLocalVideo() {
    return Obx(() {
      if (!_controller.isCameraOn.value) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child:
                Icon(Icons.videocam_off, color: Colors.white54, size: 28),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            RTCVideoView(
              _controller.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _peerName,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            splashRadius: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _peerName,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ---- 底部控制栏 ----

  Widget _buildControls(CallState state) {
    if (state == CallState.ended || state == CallState.error) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ctrlBtn(
            icon: Obx(() => Icon(
                  _controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                  size: 24,
                )),
            label: Obx(() => Text(
                  _controller.isMicOn.value ? '麦克风' : '静音',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )),
            onTap: _controller.toggleMic,
          ),
          _ctrlBtn(
            icon: Obx(() => Icon(
                  _controller.isCameraOn.value
                      ? Icons.videocam
                      : Icons.videocam_off,
                  color: Colors.white,
                  size: 24,
                )),
            label: Obx(() => Text(
                  _controller.isCameraOn.value ? '摄像头' : '关闭',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )),
            onTap: _controller.toggleCamera,
          ),
          _ctrlBtn(
            icon: const Icon(Icons.flip_camera_android,
                color: Colors.white, size: 24),
            label: const Text('翻转',
                style: TextStyle(color: Colors.white, fontSize: 10)),
            onTap: _controller.switchCamera,
          ),
          _ctrlBtn(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            label: const Text('挂断',
                style: TextStyle(color: Colors.red, fontSize: 10)),
            onTap: _handleBack,
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required Widget icon,
    required Widget label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          label,
        ],
      ),
    );
  }
}

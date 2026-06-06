import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/video_call_controller.dart';

/// 视频通话底部控制栏
///
/// 包含：麦克风开关 / 摄像头开关 / 翻转摄像头 / 挂断
class CallControlBar extends StatelessWidget {
  final VideoCallController controller;
  final VoidCallback onHangUp;

  const CallControlBar({
    super.key,
    required this.controller,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
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
          _ctrlItem(
            icon: Obx(
              () => Icon(
                controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: Obx(
              () => Text(
                controller.isMicOn.value ? '麦克风' : '静音',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            onTap: controller.toggleMic,
          ),
          _ctrlItem(
            icon: Obx(
              () => Icon(
                controller.isCameraOn.value
                    ? Icons.videocam
                    : Icons.videocam_off,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: Obx(
              () => Text(
                controller.isCameraOn.value ? '摄像头' : '关闭',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            onTap: controller.toggleCamera,
          ),
          _ctrlItem(
            icon: const Icon(
              Icons.flip_camera_android,
              color: Colors.white,
              size: 24,
            ),
            label: const Text(
              '翻转',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            onTap: controller.switchCamera,
          ),
          _ctrlItem(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            label: const Text(
              '挂断',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
            onTap: onHangUp,
          ),
        ],
      ),
    );
  }

  Widget _ctrlItem({
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

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../controllers/video_call_controller.dart';

/// 本地点击视频渲染组件（画中画小窗）
///
/// - 摄像头关闭时显示灰色占位 + 关闭图标
/// - 摄像头开启时显示 [RTCVideoView]（镜像）
class LocalVideoView extends StatelessWidget {
  final VideoCallController controller;
  final double width;
  final double height;

  const LocalVideoView({
    super.key,
    required this.controller,
    this.width = 100,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isCameraOn.value) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: RTCVideoView(
            controller.localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      );
    });
  }
}

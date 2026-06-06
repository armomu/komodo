import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import '../controllers/video_call_controller.dart';

/// 远端视频渲染组件
///
/// 仅在 [CallState.connected] 时显示 [RTCVideoView]，
/// 否则显示黑色占位。
class RemoteVideoView extends StatelessWidget {
  final VideoCallController controller;
  final String peerName;

  const RemoteVideoView({
    super.key,
    required this.controller,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.callState.value == CallState.connected) {
        return Stack(
          children: [
            RTCVideoView(
              controller.remoteRenderer,
              mirror: false,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  peerName,
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
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_placeholder.dart';

/// 视频播放区域
class VideoPlayerArea extends StatelessWidget {
  final VideoPlayerController controller;
  final String? playUrl;
  final VoidCallback onTap;

  const VideoPlayerArea({
    super.key,
    required this.controller,
    this.playUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (playUrl == null || !controller.value.isInitialized) {
      return const VideoPlaceholder();
    }
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

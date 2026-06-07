import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_player_controller.dart';

/// 播放列表底部弹窗（公共组件）
///
/// 从播放器详情页和 mini 播放条复用。
/// 点击列表项会切换曲目并关闭弹窗。
class PlaylistBottomSheet extends StatelessWidget {
  final MusicPlayerController controller;

  const PlaylistBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.queue_music, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '播放列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    '${controller.currentIndex.value + 1}/${MusicPlayerController.playlist.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分割线
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.1)),

          // 播放列表
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: MusicPlayerController.playlist.length,
              itemBuilder: (context, index) {
                return Obx(() {
                  final track = MusicPlayerController.playlist[index];
                  final isCurrent = index == controller.currentIndex.value;

                  return ListTile(
                    onTap: () {
                      controller.selectTrack(index);
                      Get.back();
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: track.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isCurrent
                            ? const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              )
                            : Icon(
                                Icons.music_note,
                                color: track.accentColor,
                                size: 20,
                              ),
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCurrent ? Colors.white : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent
                            ? Colors.white70
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? (controller.isBuffering.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: track.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.equalizer,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ))
                        : null,
                  );
                });
              },
            ),
          ),

          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 便捷方法：显示播放列表底部弹窗
  static void show(MusicPlayerController controller) {
    Get.bottomSheet(
      PlaylistBottomSheet(controller: controller),
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }
}

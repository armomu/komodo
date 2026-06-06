import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_models.dart';
import 'package:komodo/pages/music/music_player_controller.dart';
import 'package:komodo/pages/music/playlist_bottom_sheet.dart';
import 'package:komodo/pages/music/widgets/mini_player_cover.dart';
import 'package:komodo/routes/app_routes.dart';

/// 音乐播放浮层 (Mini Player Bar)
///
/// 显示在底部导航栏上方，类似酷狗音乐的 mini 播放条。
/// - 左侧：正方形专辑封面 + 右侧滑出小CD圆
/// - 中间：歌名 + 歌手
/// - 右侧：播放/暂停按钮 + 播放列表按钮
/// - 底部：播放进度条
/// - 点击整体区域跳转播放器页
class MiniPlayerBar extends StatelessWidget {
  /// 当前首页 Tab 索引（0=音乐, 1=短视频, 3=消息, 4=我的）
  /// 只有音乐 Tab 才显示浮层
  final int currentTabIndex;

  const MiniPlayerBar({super.key, required this.currentTabIndex});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();

    return Obx(() {
      if (!controller.hasStartedPlaying.value || currentTabIndex != 0) {
        return const SizedBox.shrink();
      }

      final track = controller.currentTrack;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, -2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部细线
            Container(height: 0.5, color: Colors.white.withValues(alpha: 0.1)),

            // 主内容区
            GestureDetector(
              onTap: () => Get.toNamed(Routes.musicPlayer),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(),
                child: Row(
                  children: [
                    // 左侧：正方形封面 + 右侧滑出小CD圆
                    MiniPlayerCover(track: track),
                    const SizedBox(width: 12),
                    // 中间：歌名 + 歌手
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // 右侧按钮区
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlayPauseButton(controller),
                        const SizedBox(width: 8),
                        _buildPlaylistButton(controller),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            // 底部进度条
            _buildProgressBar(controller, track),
          ],
        ),
      );
    });
  }

  /// 播放/暂停按钮
  Widget _buildPlayPauseButton(MusicPlayerController controller) {
    return Obx(() {
      return GestureDetector(
        onTap: () => controller.togglePlay(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            controller.isPlaying.value
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    });
  }

  /// 播放列表按钮
  Widget _buildPlaylistButton(MusicPlayerController controller) {
    return GestureDetector(
      onTap: () => PlaylistBottomSheet.show(controller),
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Icon(Icons.queue_music_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  /// 底部进度条
  Widget _buildProgressBar(
    MusicPlayerController controller,
    PlaylistItem track,
  ) {
    return Obx(() {
      final progress = controller.duration.value.inMilliseconds > 0
          ? controller.position.value.inMilliseconds /
                controller.duration.value.inMilliseconds
          : 0.0;

      return SizedBox(
        height: 2,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(track.accentColor),
            minHeight: 2,
          ),
        ),
      );
    });
  }
}

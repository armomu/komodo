import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_models.dart';
import 'package:komodo/pages/music/music_player_controller.dart';
import 'package:komodo/routes/app_routes.dart';

/// 本地歌曲排行单项
class LocalRankingItem extends StatelessWidget {
  final PlaylistItem data;
  final int rank;
  final bool isLast;
  final VoidCallback? onTap;

  const LocalRankingItem({
    super.key,
    required this.data,
    required this.rank,
    required this.isLast,
    this.onTap,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFF32CD32);
      case 2:
        return const Color(0xFFFF9500);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final player = Get.find<MusicPlayerController>();
      final isCurrent =
          player.hasStartedPlaying.value && player.currentTrack.id == data.id;
      final isCurrentPlaying = isCurrent && player.isPlaying.value;

      return Column(
        children: [
          GestureDetector(
            onTap: onTap ?? () => Get.toNamed(Routes.musicPlayer),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _rankColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('$rank',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _rankColor)),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _rankColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent
                                ? _rankColor
                                : _rankColor.withValues(alpha: 0.3),
                            width: isCurrent ? 2.5 : 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.network(
                            data.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF2A2A2A),
                              child: Icon(Icons.music_note,
                                  color: _rankColor, size: 20),
                            ),
                          ),
                        ),
                      ),
                      if (isCurrentPlaying)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? _rankColor : null),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(data.artist,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  isCurrent
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _rankColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  isCurrentPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 14,
                                  color: _rankColor),
                              const SizedBox(width: 2),
                              Text(
                                  isCurrentPlaying ? '播放中' : '已暂停',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _rankColor)),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF32CD32)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up,
                                  size: 14, color: Color(0xFF32CD32)),
                              SizedBox(width: 2),
                              Text('1',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF32CD32))),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

import 'package:flutter/material.dart';
import '../music_models.dart';

/// Mini 播放条封面（正方形圆角封面 + 右侧小 CD 圆）
class MiniPlayerCover extends StatelessWidget {
  final PlaylistItem track;

  const MiniPlayerCover({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 小圆形 CD（右侧滑出）
          Positioned(
            right: 0,
            top: 1,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 54, 54, 93),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
            ),
          ),
          // 正方形圆角封面（主体）
          Positioned(
            left: 1,
            top: 1,
            child: Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                track.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2A2A3E),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

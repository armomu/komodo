import 'package:flutter/material.dart';
import 'video_data.dart';

class VideoActionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final int favorites;
  final int shares;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const VideoActionBar({
    super.key,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 头像 + 关注按钮
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: -8,
              left: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // 点赞
        _ActionButton(
          icon: Icons.favorite,
          color: Colors.red,
          count: likes,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        // 评论
        _ActionButton(
          icon: Icons.chat_bubble_rounded,
          color: Colors.white,
          count: comments,
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        // 收藏
        _ActionButton(
          icon: Icons.star_rounded,
          color: Colors.amber,
          count: favorites,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        // 分享
        GestureDetector(
          onTap: onShare,
          child: Column(
            children: [
              Transform.flip(
                flipX: true,
                child: const Icon(Icons.reply, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 4),
              Text(
                formatCount(shares),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 4),
          Text(
            formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

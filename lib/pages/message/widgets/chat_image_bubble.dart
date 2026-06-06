import 'dart:io';
import 'package:flutter/material.dart';
import 'chat_avatar.dart';

/// 图片消息气泡
class ChatImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isLocalImage;
  final bool isMe;
  final String avatarUrl;
  final VoidCallback onTap;

  const ChatImageBubble({
    super.key,
    required this.imageUrl,
    required this.isLocalImage,
    required this.isMe,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ChatAvatar(url: avatarUrl),
          if (!isMe) const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isLocalImage
                  ? Image.file(File(imageUrl),
                      width: 180,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder())
                  : Image.network(imageUrl,
                      width: 180,
                      height: 240,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                            width: 180, height: 240, child: _ImagePlaceholder());
                      },
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder()),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) ChatAvatar(url: avatarUrl),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      height: 240,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.broken_image,
          color: colorScheme.onSurface.withValues(alpha: 0.3), size: 40),
    );
  }
}

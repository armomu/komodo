import 'package:flutter/material.dart';
import 'chat_avatar.dart';

/// 语音消息气泡
class ChatVoiceBubble extends StatelessWidget {
  final int duration;
  final bool isMe;
  final bool isPlaying;
  final String avatarUrl;
  final VoidCallback onTap;

  const ChatVoiceBubble({
    super.key,
    required this.duration,
    required this.isMe,
    required this.isPlaying,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final bubbleWidth =
        (80.0 + duration * 10.0).clamp(80.0, 180.0);
    final peerBubbleColor = colorScheme.surfaceContainer;
    final peerBubbleTextColor = colorScheme.onSurface;

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(
                  minWidth: bubbleWidth, maxWidth: bubbleWidth),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? (isPlaying
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.85))
                    : peerBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                    color: isMe
                        ? colorScheme.onPrimary
                        : peerBubbleTextColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  isPlaying
                      ? _PlayingWave(isMe: isMe)
                      : Icon(Icons.graphic_eq,
                          size: 18,
                          color: isMe
                              ? colorScheme.onPrimary.withValues(alpha: 0.7)
                              : peerBubbleTextColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('$duration"',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: isMe
                                ? colorScheme.onPrimary
                                : peerBubbleTextColor.withValues(alpha: 0.7))),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) ChatAvatar(url: avatarUrl),
        ],
      ),
    );
  }
}

/// 语音播放波形动画
class _PlayingWave extends StatelessWidget {
  final bool isMe;
  const _PlayingWave({required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isMe
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.5);
    return SizedBox(
      width: 18,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          3,
          (i) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 100),
            curve: Curves.easeInOut,
            builder: (_, v, __) => AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 100),
              width: 3,
              height: 6 + v * 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

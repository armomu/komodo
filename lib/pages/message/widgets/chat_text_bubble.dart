import 'package:flutter/material.dart';
import 'chat_avatar.dart';

/// 文字消息气泡
class ChatTextBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String avatarUrl;

  const ChatTextBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ChatAvatar(url: avatarUrl),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? colorScheme.primary : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(text,
                  style: TextStyle(
                      fontSize: 15,
                      color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                      height: 1.4)),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) ChatAvatar(url: avatarUrl),
        ],
      ),
    );
  }
}

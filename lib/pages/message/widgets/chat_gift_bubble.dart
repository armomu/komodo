import 'package:flutter/material.dart';
import 'chat_avatar.dart';

/// 礼物消息气泡
class ChatGiftBubble extends StatelessWidget {
  final String giftEmoji;
  final String giftLabel;
  final String avatarUrl;

  const ChatGiftBubble({
    super.key,
    required this.giftEmoji,
    required this.giftLabel,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B81), Color(0xFFFF4757)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(giftEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
                Text(giftLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ChatAvatar(url: avatarUrl),
        ],
      ),
    );
  }
}

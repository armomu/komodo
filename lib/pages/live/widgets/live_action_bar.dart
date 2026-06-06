import 'package:flutter/material.dart';
import 'bottom_action_button.dart';

/// 底部操作栏（聊天入口 + 购物车 + 礼物 + 分享）
class LiveActionBar extends StatelessWidget {
  final VoidCallback onChatTap;
  final VoidCallback onEmojiTap;
  final VoidCallback onCartTap;
  final VoidCallback onGiftTap;
  final VoidCallback onShareTap;

  const LiveActionBar({
    super.key,
    required this.onChatTap,
    required this.onEmojiTap,
    required this.onCartTap,
    required this.onGiftTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safePadding = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, safePadding + 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onChatTap,
                      child: const Text(
                        '说点什么…',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEmojiTap,
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          BottomActionButton(icon: Icons.shopping_cart_outlined, onTap: onCartTap),
          const SizedBox(width: 8),
          BottomActionButton(
            icon: Icons.card_giftcard,
            color: Colors.orange,
            onTap: onGiftTap,
          ),
          const SizedBox(width: 8),
          BottomActionButton(icon: Icons.share_outlined, onTap: onShareTap),
        ],
      ),
    );
  }
}

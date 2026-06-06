import 'package:flutter/material.dart';

/// 消息列表单项（头像 + 标题 + 摘要 + 时间 + 未读标识）
///
/// 支持两种模式：
/// 1. 传入 MessageItem（旧版本地会话）
/// 2. 传入 _WSMessageItem + onTap（新版在线用户列表）
class MessageListItem extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final String subtitle;
  final String time;
  final int unread;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isOnline;

  const MessageListItem({
    super.key,
    required this.title,
    this.avatarUrl,
    this.subtitle = '',
    this.time = '',
    this.unread = 0,
    required this.isDark,
    this.onTap,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (isOnline) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(time,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white24
                              : Colors.grey[400])),
                ],
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('$unread',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
          width: 1,
        ),
        image: avatarUrl != null && avatarUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Icon(Icons.person, size: 26, color: Colors.grey[400])
          : null,
    );
  }

  /// 从旧版 MessageItem 构造（兼容旧有用法）
  factory MessageListItem.fromMessageItem({
    required dynamic item,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return MessageListItem(
      title: item.title,
      avatarUrl: item.avatarUrl,
      subtitle: item.subtitle,
      time: item.time,
      unread: item.unread ?? 0,
      isDark: isDark,
      onTap: onTap,
    );
  }
}

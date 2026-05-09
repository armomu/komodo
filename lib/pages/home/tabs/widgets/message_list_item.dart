import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';
import '../models/message_models.dart';

/// 消息列表单项（头像 + 标题 + 摘要 + 时间 + 未读标识）
class MessageListItem extends StatelessWidget {
  final MessageItem item;
  final bool isDark;

  const MessageListItem({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Get.toNamed(
              Routes.chat,
              arguments: {
                'peerName': item.title,
                'peerAvatar': item.avatarUrl,
              },
            );
          },
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
                      Text(item.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(item.subtitle,
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item.time,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey[400])),
                    if (item.unread != null && item.unread! > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('${item.unread}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (item.type == MessageType.system) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: item.iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, size: 26, color: item.iconColor),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
          width: 1,
        ),
        image: DecorationImage(
          image: NetworkImage(item.avatarUrl!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

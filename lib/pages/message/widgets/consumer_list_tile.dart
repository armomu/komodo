import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/models/consumer_list_item.dart';

/// 消费者列表项组件
///
/// 显示：头像 + 在线绿点 + 昵称 + 最后消息 subtitle + 时间 + 未读 badge
class ConsumerListTile extends StatelessWidget {
  final ConsumerListItem item;
  final VoidCallback? onTap;

  const ConsumerListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(),
      title: Text(
        item.nickname,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.lastMessage != null
          ? Text(
              item.lastMessage!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: _buildTrailing(),
      onTap: onTap,
    );
  }

  Widget _buildLeading() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: item.avatar.isNotEmpty
              ? NetworkImage(item.avatar)
              : null,
          child: item.avatar.isEmpty ? const Icon(Icons.person, size: 28) : null,
        ),
        // 在线绿点
        if (item.isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (item.lastTime != null)
          Text(
            item.lastTime!,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        const SizedBox(height: 4),
        if (item.unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.unread > 99 ? "99+" : item.unread}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        else
          const SizedBox(height: 18),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';
import 'package:komodo/services/consumer_ws_client.dart';
import 'widgets/message_list_item.dart';

/// 消息Tab — 显示在线用户列表（来自 WebSocket）
///
/// 用户登录后自动连接 WS，此 Tab 实时展示所有在线用户。
/// 点击进入聊天页面后可发送消息和发起视频通话。
class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  MessageTabState createState() => MessageTabState();
}

class MessageTabState extends State<MessageTab> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.position.pixels;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openChat(OnlineUser user) {
    Get.toNamed(
      Routes.chat,
      arguments: {
        'peerUserId': user.userId,
        'peerName': user.nickname,
        'peerAvatar': user.avatar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxExtent = 102.0;
    const minExtent = kToolbarHeight;
    final shrinkOffset = _scrollOffset.clamp(0.0, maxExtent - minExtent);
    final collapseProgress = shrinkOffset / (maxExtent - minExtent);

    const startLeft = 16.0;
    const endLeft = 52.0;
    final leftPadding = startLeft + (endLeft - startLeft) * collapseProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            leading: Opacity(
              opacity: collapseProgress,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            expandedHeight: maxExtent,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '在线用户',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              titlePadding: EdgeInsets.only(left: leftPadding, bottom: 14),
              centerTitle: false,
            ),
          ),
        ];
      },
      body: Obx(() {
        final ws = Get.find<ConsumerWsClient>();
        final users = ws.onlineUsers;

        if (!ws.isAuthenticated.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('未连接到服务器',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('暂无其他在线用户',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return MessageListItem(
                title: user.nickname,
                avatarUrl: user.avatar,
                subtitle: '在线',
                isDark: isDark,
                isOnline: true,
                onTap: () => _openChat(user),
              );
            },
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/routes/app_routes.dart';
import 'package:komodo/services/consumer_ws_client.dart';
import 'widgets/message_list_item.dart';

/// 消息Tab — 显示在线用户列表（来自 WebSocket）
///
/// 用户登录后自动连接 WS，此 Tab 实时展示所有在线用户。
/// 下拉刷新时如果未连接会尝试重新连接。
class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  MessageTabState createState() => MessageTabState();
}

class MessageTabState extends State<MessageTab> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  /// 下拉刷新中
  bool _refreshing = false;

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

  /// 下拉刷新：未连接时尝试重连
  Future<void> _onRefresh() async {
    final ws = Get.find<ConsumerWsClient>();
    if (ws.isConnected.value && ws.isAuthenticated.value) {
      debugPrint('[MessageTab] 已连接，无需重连');
      return;
    }

    setState(() => _refreshing = true);
    try {
      final token = UserController.to.accessToken;
      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未登录，请先登录')),
          );
        }
        return;
      }

      debugPrint('[MessageTab] 尝试重新连接 WebSocket');
      await ws.connect(token);
      if (mounted && ws.isAuthenticated.value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已重新连接'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Obx(() {
          final ws = Get.find<ConsumerWsClient>();
          final users = ws.onlineUsers;
          // ListView 需要至少一个子项才能下拉刷新，否则 RefreshIndicator 不响应
          // 当无数据时用一个 SingleChildScrollView 包裹占位内容
          if (!ws.isAuthenticated.value) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('未连接到服务器',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 16),
                        if (_refreshing)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton.icon(
                            onPressed: _onRefresh,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('点击重试'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (users.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('暂无其他在线用户',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
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
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';

class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  MessageTabState createState() => MessageTabState();
}

/// 消息Tab — 微博风格消息中心
/// 布局：搜索栏 → 快捷入口（通知/@我的/评论/赞） → 消息列表
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
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded),
          ),
          expandedHeight: maxExtent,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            titlePadding: EdgeInsets.only(left: leftPadding, bottom: 14),
            centerTitle: false,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return _buildMessageItem(
                context,
                _mockMessageList[index],
                isDark,
              );
            },
            childCount: _mockMessageList.length, // 指定数量
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 消息列表
  // ════════════════════════════════════════════════════════════════════════

  static const List<_MessageItem> _mockMessageList = [
    // 系统消息
    // _MessageItem(
    //   type: _MessageType.system,
    //   title: '微博视频',
    //   subtitle: 'SUNMI 发布了新MV《Narcissism》',
    //   time: '昨天',
    //   icon: Icons.play_circle_fill,
    //   iconColor: Color(0xFFFF3B30),
    //   iconBgColor: Color(0xFFFFF0EF),
    // ),
    // _MessageItem(
    //   type: _MessageType.system,
    //   title: '未关注人消息',
    //   subtitle: '有3条来自未关注人的私信',
    //   time: '4-30',
    //   icon: Icons.mail_rounded,
    //   iconColor: Color(0xFFFF9500),
    //   iconBgColor: Color(0xFFFFF5EC),
    //   showBadge: true,
    // ),
    // 私信消息
    _MessageItem(
      type: _MessageType.private,
      title: 'Sarah Miller',
      subtitle: '这首歌太好听了！你听过吗？',
      time: '昨天',
      avatarUrl: 'https://picsum.photos/seed/user1/100/100',
      unread: 2,
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'John Doe',
      subtitle: '周末一起去看演唱会吧',
      time: '4-28',
      avatarUrl: 'https://picsum.photos/seed/user2/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Emma Wilson',
      subtitle: '分享了一首歌给你 🎵',
      time: '4-25',
      avatarUrl: 'https://picsum.photos/seed/user3/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Mike Chen',
      subtitle: '[图片]',
      time: '4-20',
      avatarUrl: 'https://picsum.photos/seed/user4/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Lisa Park',
      subtitle: '在吗？有个事想问你',
      time: '4-15',
      avatarUrl: 'https://picsum.photos/seed/user5/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Alex Turner',
      subtitle: '好的，没问题',
      time: '4-10',
      avatarUrl: 'https://picsum.photos/seed/user6/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Lisa Park',
      subtitle: '在吗？有个事想问你',
      time: '4-15',
      avatarUrl: 'https://picsum.photos/seed/user7/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Lucy',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user8/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Lily',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user9/100/100',
    ),
    _MessageItem(
      type: _MessageType.private,
      title: 'Lucy',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user10/100/100',
    ),
  ];

  Widget _buildMessageItem(
    BuildContext context,
    _MessageItem item,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Get.toNamed(
              Routes.chat,
              arguments: {'peerName': item.title, 'peerAvatar': item.avatarUrl},
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 头像 / 图标
                _buildAvatar(context, item, isDark),
                const SizedBox(width: 14),
                // 标题 + 摘要
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 时间
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                    ),
                    // 未读数
                    if (item.unread != null && item.unread! > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.unread}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // 分割线
        // if (!isLast)
        //   Divider(
        //     height: 0.5,
        //     indent: 76,
        //     endIndent: 16,
        //     color: isDark
        //         ? Colors.white.withValues(alpha: 0.06)
        //         : Colors.grey[300],
        //   ),
      ],
    );
  }

  /// 构建头像：系统消息用图标，私信用真实头像
  Widget _buildAvatar(BuildContext context, _MessageItem item, bool isDark) {
    if (item.type == _MessageType.system) {
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

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

enum _MessageType { system, private }

// ignore: unused_element
class _QuickEntry {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final bool showBadge;

  const _QuickEntry({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.showBadge,
  });
}

class _MessageItem {
  final _MessageType type;
  final String title;
  final String subtitle;
  final String time;

  // 私信头像
  final String? avatarUrl;

  // 系统消息图标
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;

  // 未读相关
  final bool showBadge;
  final int? unread;

  const _MessageItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.avatarUrl,
    this.iconColor,
    this.iconBgColor,
    this.showBadge = false,
    this.unread,
    this.icon,
  });
}

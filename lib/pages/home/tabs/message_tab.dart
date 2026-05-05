import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';

/// 消息Tab — 微博风格消息中心
/// 布局：搜索栏 → 快捷入口（通知/@我的/评论/赞） → 消息列表
class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '消息',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.contacts_outlined, color: colorScheme.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 搜索栏
          _buildSearchBar(context, isDark),
          const SizedBox(height: 20),
          // 快捷功能入口
          _buildQuickEntries(context, isDark),
          const SizedBox(height: 20),
          // 消息列表
          ..._mockMessageList.map(
            (item) => _buildMessageItem(context, item, isDark),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 搜索栏
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // TODO: 跳转搜索页面
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2C)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search,
                size: 18,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                '搜索',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 快捷功能入口 — 4宫格
  // ════════════════════════════════════════════════════════════════════════

  static const List<_QuickEntry> _quickEntries = [
    _QuickEntry(
      icon: Icons.notifications_active_rounded,
      label: '通知',
      gradient: LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _QuickEntry(
      icon: Icons.alternate_email_rounded,
      label: '@我的',
      gradient: LinearGradient(
        colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _QuickEntry(
      icon: Icons.chat_bubble_rounded,
      label: '评论',
      gradient: LinearGradient(
        colors: [Color(0xFF34C759), Color(0xFF30D158)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showBadge: true,
    ),
    _QuickEntry(
      icon: Icons.thumb_up_rounded,
      label: '赞',
      gradient: LinearGradient(
        colors: [Color(0xFFFF3B30), Color(0xFFFF6961)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  Widget _buildQuickEntries(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _quickEntries.map((entry) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: 跳转对应页面
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  // 图标容器
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: entry.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: entry.gradient.colors.first
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          entry.icon,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      // 未读红点
                      if (entry.showBadge)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '3',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 消息列表
  // ════════════════════════════════════════════════════════════════════════

  static const List<_MessageItem> _mockMessageList = [
    // 系统消息
    _MessageItem(
      type: _MessageType.system,
      title: '微博视频',
      subtitle: 'SUNMI 发布了新MV《Narcissism》',
      time: '昨天',
      icon: Icons.play_circle_fill,
      iconColor: const Color(0xFFFF3B30),
      iconBgColor: const Color(0xFFFFF0EF),
    ),
    _MessageItem(
      type: _MessageType.system,
      title: '未关注人消息',
      subtitle: '有3条来自未关注人的私信',
      time: '4-30',
      icon: Icons.mail_rounded,
      iconColor: const Color(0xFFFF9500),
      iconBgColor: const Color(0xFFFFF5EC),
      showBadge: true,
    ),
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
  ];

  Widget _buildMessageItem(
    BuildContext context,
    _MessageItem item,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = item == _mockMessageList.last;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (item.type == _MessageType.private && item.avatarUrl != null) {
              Get.toNamed(
                Routes.chat,
                arguments: {'peerName': item.title, 'peerAvatar': item.avatarUrl},
              );
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        if (!isLast)
          Divider(
            height: 0.5,
            indent: 76,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey[300],
          ),
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
        child: Icon(
          item.icon,
          size: 26,
          color: item.iconColor,
        ),
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

class _QuickEntry {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final bool showBadge;

  const _QuickEntry({
    required this.icon,
    required this.label,
    required this.gradient,
    this.showBadge = false,
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
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.showBadge = false,
    this.unread,
  });
}

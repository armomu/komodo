import 'package:flutter/material.dart';
import 'models/message_models.dart';
import 'widgets/message_list_item.dart';

/// 消息Tab — 微博风格消息中心
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

  static const List<MessageItem> _mockMessageList = [
    MessageItem(
      type: MessageType.private,
      title: 'Sarah Miller',
      subtitle: '这首歌太好听了！你听过吗？',
      time: '昨天',
      avatarUrl: 'https://picsum.photos/seed/user1/100/100',
      unread: 2,
    ),
    MessageItem(
      type: MessageType.private,
      title: 'John Doe',
      subtitle: '周末一起去看演唱会吧',
      time: '4-28',
      avatarUrl: 'https://picsum.photos/seed/user2/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Emma Wilson',
      subtitle: '分享了一首歌给你 🎵',
      time: '4-25',
      avatarUrl: 'https://picsum.photos/seed/user3/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Mike Chen',
      subtitle: '[图片]',
      time: '4-20',
      avatarUrl: 'https://picsum.photos/seed/user4/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Lisa Park',
      subtitle: '在吗？有个事想问你',
      time: '4-15',
      avatarUrl: 'https://picsum.photos/seed/user5/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Alex Turner',
      subtitle: '好的，没问题',
      time: '4-10',
      avatarUrl: 'https://picsum.photos/seed/user6/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Lisa Park',
      subtitle: '在吗？有个事想问你',
      time: '4-15',
      avatarUrl: 'https://picsum.photos/seed/user7/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Lucy',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user8/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Lily',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user9/100/100',
    ),
    MessageItem(
      type: MessageType.private,
      title: 'Lucy',
      subtitle: '你今天吃啥？',
      time: '4-18',
      avatarUrl: 'https://picsum.photos/seed/user10/100/100',
    ),
  ];

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
            title: const Text('Messages',
                style: TextStyle(fontWeight: FontWeight.w600)),
            titlePadding: EdgeInsets.only(left: leftPadding, bottom: 14),
            centerTitle: false,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => MessageListItem(
              item: _mockMessageList[index],
              isDark: isDark,
            ),
            childCount: _mockMessageList.length,
          ),
        ),
      ],
    );
  }
}

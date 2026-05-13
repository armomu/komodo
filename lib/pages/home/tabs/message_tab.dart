import 'package:flutter/material.dart';
import 'package:komodo/database/chat_database.dart';
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

  List<MessageItem> _conversations = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.position.pixels;
      });
    });
    _loadConversations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final db = ChatDatabase.to;
    final list = await db.getConversations();
    if (mounted) setState(() => _conversations = list);
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
                'Messages',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              titlePadding: EdgeInsets.only(left: leftPadding, bottom: 14),
              centerTitle: false,
            ),
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: _conversations.length,
          itemBuilder: (BuildContext context, int index) =>
              MessageListItem(item: _conversations[index], isDark: isDark),
        ),
      ),
    );
  }
}

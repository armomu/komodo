import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 聊天详情页 — 社交私信聊天界面
/// 布局：导航栏 → 用户信息卡 → 动态展示区 → 消息列表 → 快捷表情栏 → 输入栏
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 从路由参数获取对方信息
    final args = Get.arguments as Map<String, dynamic>?;
    final peerName = args?['peerName'] as String? ?? _defaultPeerName;
    final peerAvatar = args?['peerAvatar'] as String? ?? _defaultPeerAvatar;

    return _ChatContent(
      peerName: peerName,
      peerAvatar: peerAvatar,
    );
  }

  static const String _defaultPeerName = '九黎❤️是美女';
  static const String _defaultPeerAvatar = 'https://picsum.photos/seed/chatpeer/100/100';
}

class _ChatContent extends StatefulWidget {
  final String peerName;
  final String peerAvatar;

  const _ChatContent({
    required this.peerName,
    required this.peerAvatar,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showQuickReplies = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showQuickReplies) {
        setState(() => _showQuickReplies = false);
      } else if (!_focusNode.hasFocus && !_showQuickReplies) {
        setState(() => _showQuickReplies = true);
      }
    });
    // 延迟滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 模拟数据
  // ════════════════════════════════════════════════════════════════════════

  static const String _myAvatar = 'https://picsum.photos/seed/myavatar/100/100';
  static const String _distance = '3.52km';
  static const String _signature = '你会，为我着迷吗❤️';

  static const List<_MomentItem> _moments = [
    _MomentItem(
      type: _MomentType.gift,
      label: '一鹿兜萌',
      subLabel: '520 钻石',
      emoji: '🦌',
    ),
    _MomentItem(
      type: _MomentType.gift,
      label: '圣光飞轮',
      subLabel: '888 钻石',
      emoji: '✨',
    ),
    _MomentItem(type: _MomentType.photo, imageUrl: 'https://picsum.photos/seed/m1/200/200'),
    _MomentItem(type: _MomentType.photo, imageUrl: 'https://picsum.photos/seed/m2/200/200'),
    _MomentItem(type: _MomentType.photo, imageUrl: 'https://picsum.photos/seed/m3/200/200'),
    _MomentItem(type: _MomentType.photo, imageUrl: 'https://picsum.photos/seed/m4/200/200'),
  ];

  static const List<String> _quickReplies = [
    '哈喽',
    '你好',
    '美女你好~',
    '在干嘛呢',
    '你好漂亮',
  ];

  static const List<_ChatMessage> _messages = [
    _ChatMessage(type: _MsgType.timestamp, time: '19:01'),
    _ChatMessage(
      type: _MsgType.text,
      isMe: false,
      content: '嗨，你好呀～很高兴认识你 😊',
    ),
    _ChatMessage(
      type: _MsgType.voice,
      isMe: false,
      duration: 11,
    ),
    _ChatMessage(
      type: _MsgType.image,
      isMe: false,
      imageUrl: 'https://picsum.photos/seed/chatimg1/400/600',
    ),
    _ChatMessage(
      type: _MsgType.gift,
      isMe: true,
      giftEmoji: '🌹',
      giftLabel: '红玫瑰',
    ),
    _ChatMessage(
      type: _MsgType.text,
      isMe: false,
      content: '谢谢你的玫瑰，好开心～',
    ),
    _ChatMessage(
      type: _MsgType.text,
      isMe: true,
      content: '你也太好看了吧',
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveName = widget.peerName;
    final effectiveAvatar = widget.peerAvatar;

    return Scaffold(
      appBar: AppBar(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colorScheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Positioned(
              right: 2,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          effectiveName,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 可滚动内容区
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                // 用户信息卡
                _buildPeerInfoCard(context, isDark, effectiveAvatar),
                // 动态展示区
                _buildMomentsSection(context, isDark),
                // 聊天消息
                ..._messages.map((msg) => _buildChatMessage(context, msg, isDark, effectiveAvatar)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // 底部区域（不滚动）
          _buildBottomArea(context, isDark, effectiveAvatar),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 用户信息卡片
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildPeerInfoCard(BuildContext context, bool isDark, String avatar) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 14),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 距离
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      _distance,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 签名
                Text(
                  _signature,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 动态展示区
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMomentsSection(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // 标题行
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    '动态 ${_moments.length}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          // 横向滚动缩略图
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _moments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _moments[index];
                if (item.type == _MomentType.gift) {
                  return _buildGiftMoment(item, isDark);
                }
                return _buildPhotoMoment(item, isDark);
              },
            ),
          ),
          // 底部分割线
          const SizedBox(height: 8),
          Divider(height: 0.5, color: isDark ? Colors.white12 : Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _buildGiftMoment(_MomentItem item, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji!, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            item.label ?? '',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.subLabel!,
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoMoment(_MomentItem item, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        item.imageUrl!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
          child: Icon(Icons.image, color: isDark ? Colors.white24 : Colors.grey[400]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 聊天消息
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildChatMessage(BuildContext context, _ChatMessage msg, bool isDark, String peerAvatar) {
    switch (msg.type) {
      case _MsgType.timestamp:
        return _buildTimestamp(msg.time!);
      case _MsgType.text:
        return _buildTextMessage(msg, isDark, peerAvatar);
      case _MsgType.voice:
        return _buildVoiceMessage(msg, isDark, peerAvatar);
      case _MsgType.image:
        return _buildImageMessage(msg, isDark, peerAvatar);
      case _MsgType.gift:
        return _buildGiftMessage(msg);
    }
  }

  Widget _buildTimestamp(String time) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(_ChatMessage msg, bool isDark, String peerAvatar) {
    final isMe = msg.isMe;
    final avatarUrl = isMe ? _myAvatar : peerAvatar;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatarWidget(avatarUrl, isDark),
          if (!isMe) const SizedBox(width: 10),
          // 气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                msg.content!,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 10),
          if (isMe) _buildAvatarWidget(avatarUrl, isDark),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage(_ChatMessage msg, bool isDark, String peerAvatar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarWidget(peerAvatar, isDark),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 声波图标
                  Icon(Icons.graphic_eq, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    '${msg.duration}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(_ChatMessage msg, bool isDark, String peerAvatar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarWidget(peerAvatar, isDark),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              msg.imageUrl!,
              width: 180,
              height: 240,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 240,
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                child: Icon(Icons.broken_image, color: isDark ? Colors.white24 : Colors.grey[400], size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftMessage(_ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B81), Color(0xFFFF4757)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.giftEmoji!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
                Text(
                  msg.giftLabel!,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildAvatarWidget(_myAvatar, false),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(String url, bool isDark) {
    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(url),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 底部区域：快捷表情栏 + 工具栏 + 输入框
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomArea(BuildContext context, bool isDark, String peerAvatar) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快捷表情栏
            if (_showQuickReplies) _buildQuickReplies(context, isDark),
            // 工具栏 + 输入框
            _buildInputBar(context, isDark, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(BuildContext context, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _textController.text = _quickReplies[index];
              _focusNode.requestFocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  _quickReplies[index],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 工具按钮
          _buildToolButton(Icons.home_outlined, colorScheme, onPressed: () {}),
          const SizedBox(width: 2),
          _buildToolButton(Icons.emoji_emotions_outlined, colorScheme, onPressed: () {}),
          const SizedBox(width: 2),
          _buildToolButton(Icons.image_outlined, colorScheme, onPressed: () {}),
          const SizedBox(width: 2),
          _buildToolButton(Icons.mic_outlined, colorScheme, onPressed: () {}),
          // 礼物按钮（突出显示）
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B81), Color(0xFFFF4757)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.card_giftcard, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 2),
          _buildToolButton(Icons.add_circle_outline, colorScheme, onPressed: () {}),
          // 输入框
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '请输入内容...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, ColorScheme colorScheme, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

enum _MsgType { timestamp, text, voice, image, gift }

class _ChatMessage {
  final _MsgType type;
  final bool isMe;
  final String? content;
  final String? imageUrl;
  final int? duration;
  final String? giftEmoji;
  final String? giftLabel;
  final String? time;

  const _ChatMessage({
    required this.type,
    this.isMe = false,
    this.content,
    this.imageUrl,
    this.duration,
    this.giftEmoji,
    this.giftLabel,
    this.time,
  });
}

enum _MomentType { gift, photo }

class _MomentItem {
  final _MomentType type;
  final String? label;
  final String? subLabel;
  final String? emoji;
  final String? imageUrl;

  const _MomentItem({
    required this.type,
    this.label,
    this.subLabel,
    this.emoji,
    this.imageUrl,
  });
}

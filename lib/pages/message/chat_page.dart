import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

/// 聊天详情页 — 社交私信聊天界面
/// 布局：导航栏 → 消息列表 → 底部输入栏（录音/输入/表情/+）→ 可展开图标栏 + 表情面板
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final peerName = args?['peerName'] as String? ?? _defaultPeerName;
    final peerAvatar = args?['peerAvatar'] as String? ?? _defaultPeerAvatar;

    return _ChatContent(peerName: peerName, peerAvatar: peerAvatar);
  }

  static const String _defaultPeerName = '九黎❤️是美女';
  static const String _defaultPeerAvatar =
      'https://picsum.photos/seed/chatpeer/100/100';
}

class _ChatContent extends StatefulWidget {
  final String peerName;
  final String peerAvatar;

  const _ChatContent({required this.peerName, required this.peerAvatar});

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // 消息列表（可变）
  final List<_ChatMessage> _messages = List.from(_initialMessages);

  // UI 状态
  bool _showEmojiPicker = false;
  bool _showIconBar = false;
  bool _isRecording = false;

  // 录音
  AudioRecorder? _recorder;

  // 图片选择
  final ImagePicker _picker = ImagePicker();

  // 常用表情列表
  static const List<String> _emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😌',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '👍',
    '👎',
    '👏',
    '🙌',
    '🤝',
    '🙏',
    '💪',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '💯',
    '💢',
    '💨',
    '💫',
    '💬',
    '🗨️',
    '🗯️',
    '💭',
    '🎉',
    '🎊',
    '🎈',
    '🎁',
    '🏆',
    '🥇',
    '🎵',
    '🎶',
    '🎤',
  ];

  static const String _myAvatar = 'https://picsum.photos/seed/myavatar/100/100';

  static const List<_ChatMessage> _initialMessages = [
    _ChatMessage(type: _MsgType.timestamp, time: '19:01'),
    _ChatMessage(type: _MsgType.text, isMe: false, content: '嗨，你好呀～很高兴认识你 😊'),
    _ChatMessage(type: _MsgType.voice, isMe: false, duration: 11),
    _ChatMessage(
      type: _MsgType.image,
      isMe: false,
      imageUrl: 'https://picsum.photos/seed/chatimg1/400/600',
    ),
    _ChatMessage(type: _MsgType.text, isMe: false, content: '回复了一条信息'),
    _ChatMessage(type: _MsgType.text, isMe: true, content: '你好呀～'),
  ];

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _focusNode.addListener(() {
      // 输入框获焦时关闭表情面板和图标栏
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recorder?.dispose();
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

  void _sendTextMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(type: _MsgType.text, isMe: true, content: trimmed),
      );
    });
    _textController.clear();
    _scrollToBottom();
  }

  void _sendEmojiMessage(String emoji) {
    setState(() {
      _messages.add(
        _ChatMessage(type: _MsgType.text, isMe: true, content: emoji),
      );
    });
    _scrollToBottom();
  }

  void _sendImageMessage(String imagePath) {
    setState(() {
      _messages.add(
        _ChatMessage(
          type: _MsgType.image,
          isMe: true,
          imageUrl: imagePath,
          isLocalImage: true,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _sendImageMessage(image.path);
      }
    } catch (e) {
      debugPrint('图片选择失败: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _recorder?.stop();
        if (path != null) {
          setState(() {
            _messages.add(
              const _ChatMessage(type: _MsgType.voice, isMe: true, duration: 3),
            );
          });
          _scrollToBottom();
        }
      } catch (e) {
        debugPrint('停止录音失败: $e');
      }
      setState(() => _isRecording = false);
    } else {
      try {
        if (await _recorder!.hasPermission()) {
          final tempDir = await Directory.systemTemp.createTemp('chat_voice');
          final filePath =
              '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _recorder!.start(const RecordConfig(), path: filePath);
          setState(() => _isRecording = true);
        }
      } catch (e) {
        debugPrint('开始录音失败: $e');
      }
    }
  }

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
              icon: const Icon(Icons.arrow_back),
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
                child: const Text(
                  '2',
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
        title: Text(
          effectiveName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 可滚动消息区
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                ..._messages.map(
                  (msg) =>
                      _buildChatMessage(context, msg, isDark, effectiveAvatar),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // 底部区域
          _buildBottomArea(context, isDark, colorScheme),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 聊天消息
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildChatMessage(
    BuildContext context,
    _ChatMessage msg,
    bool isDark,
    String peerAvatar,
  ) {
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
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatarWidget(avatarUrl, isDark),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? const Color(0xFF3A3A3C) : Colors.white),
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
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
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
    final avatarUrl = msg.isMe ? _myAvatar : peerAvatar;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!msg.isMe) _buildAvatarWidget(avatarUrl, isDark),
          if (!msg.isMe) const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: msg.isMe
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.9)
                    : (isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFF0F0F0)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                  bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 18,
                    color: msg.isMe
                        ? Colors.white70
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${msg.duration}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isMe
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isMe) const SizedBox(width: 10),
          if (msg.isMe) _buildAvatarWidget(avatarUrl, isDark),
        ],
      ),
    );
  }

  Widget _buildImageMessage(_ChatMessage msg, bool isDark, String peerAvatar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!msg.isMe) _buildAvatarWidget(peerAvatar, isDark),
          if (!msg.isMe) const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: msg.isLocalImage && msg.imageUrl != null
                  ? Image.file(
                      File(msg.imageUrl!),
                      width: 180,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder(isDark),
                    )
                  : Image.network(
                      msg.imageUrl!,
                      width: 180,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImagePlaceholder(isDark),
                    ),
            ),
          ),
          if (msg.isMe) const SizedBox(width: 10),
          if (msg.isMe) _buildAvatarWidget(_myAvatar, isDark),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: 180,
      height: 240,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        color: isDark ? Colors.white24 : Colors.grey[400],
        size: 40,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
  // 底部区域：输入行 → 表情面板 → 可展开图标栏 → 录音指示
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomArea(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
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
            // 输入行：录音按钮 | 输入框 | 表情 | +
            _buildInputRow(context, isDark, colorScheme),
            // 表情面板
            if (_showEmojiPicker) _buildEmojiPicker(context, isDark),
            // 可展开图标栏
            if (_showIconBar)
              _buildExpandedIconBar(context, isDark, colorScheme),
            // 录音指示
            if (_isRecording) _buildRecordingIndicator(isDark),
          ],
        ),
      ),
    );
  }

  /// 输入行：录音按钮 | 输入框 | 表情按钮 | 圆形加号按钮
  Widget _buildInputRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 左侧录音按钮
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isRecording
                      ? Colors.red
                      : colorScheme.onSurfaceVariant,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 20,
                color: _isRecording ? Colors.red : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 中间输入框
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF5F5F5),
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
                  hintText: '说点什么...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                onSubmitted: _sendTextMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 右侧表情按钮
          GestureDetector(
            onTap: () {
              setState(() {
                _showEmojiPicker = !_showEmojiPicker;
                if (_showEmojiPicker) {
                  _focusNode.unfocus();
                }
              });
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                _showEmojiPicker
                    ? Icons.keyboard_alt_outlined
                    : Icons.emoji_emotions_outlined,
                size: 22,
                color: _showEmojiPicker
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 圆形加号按钮
          GestureDetector(
            onTap: () {
              setState(() {
                _showIconBar = !_showIconBar;
                if (_showIconBar) {
                  _showEmojiPicker = false;
                  _focusNode.unfocus();
                }
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _showIconBar
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _showIconBar
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _showIconBar ? Icons.close : Icons.add,
                size: 20,
                color: _showIconBar
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 可展开的图标操作栏
  Widget _buildExpandedIconBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 图片
          _buildIconBarItem(
            icon: Icons.image_outlined,
            label: '图片',
            colorScheme: colorScheme,
            onTap: () {
              _pickAndSendImage();
              setState(() => _showIconBar = false);
            },
          ),
          // 拍照（可选）
          _buildIconBarItem(
            icon: Icons.camera_alt_outlined,
            label: '拍照',
            colorScheme: colorScheme,
            onTap: () {},
          ),
          // 礼物
          _buildIconBarItem(
            icon: Icons.card_giftcard,
            label: '礼物',
            colorScheme: colorScheme,
            isPrimary: true,
            onTap: () {},
          ),
          // 位置
          _buildIconBarItem(
            icon: Icons.location_on_outlined,
            label: '位置',
            colorScheme: colorScheme,
            onTap: () {},
          ),
          // 更多
          _buildIconBarItem(
            icon: Icons.more_horiz,
            label: '更多',
            colorScheme: colorScheme,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildIconBarItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary
                  ? null
                  : (colorScheme.brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF5F5F5)),
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B81), Color(0xFFFF4757)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isPrimary ? Colors.white : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 表情选择面板
  Widget _buildEmojiPicker(BuildContext context, bool isDark) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendEmojiMessage(_emojis[index]),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
              ),
              alignment: Alignment.center,
              child: Text(_emojis[index], style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  /// 录音指示条
  Widget _buildRecordingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withValues(alpha: 0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, size: 18, color: Colors.red),
          SizedBox(width: 8),
          Text(
            '正在录音...点击停止按钮结束',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
  final bool isLocalImage;
  final int? duration;
  final String? giftEmoji;
  final String? giftLabel;
  final String? time;

  const _ChatMessage({
    required this.type,
    this.isMe = false,
    this.content,
    this.imageUrl,
    this.isLocalImage = false,
    this.duration,
    this.giftEmoji,
    this.giftLabel,
    this.time,
  });
}

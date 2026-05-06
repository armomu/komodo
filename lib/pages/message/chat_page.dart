import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// 录音状态枚举
enum _RecordState {
  idle, // 文字输入模式（话筒按钮）
  ready, // 长按录音模式（输入框换成录音条）
  recording, // 正在录音（弹出浮层）
  preview, // 录音完成，浮层预览中
}

class _ChatContentState extends State<_ChatContent>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // 消息列表（可变）
  final List<_ChatMessage> _messages = List.from(_initialMessages);

  // UI 状态
  bool _showEmojiPicker = false;
  bool _showIconBar = false;

  // 录音状态机
  _RecordState _recordState = _RecordState.idle;

  // 录音 & 播放
  AudioRecorder? _recorder;
  String? _recordedPath; // 录制好的文件路径
  int _recordSeconds = 0; // 已录音秒数
  Timer? _recordTimer;

  // 录音浮层播放状态（mock）
  bool _previewPlaying = false;
  Timer? _previewPlayTimer;

  // 波形动画
  late AnimationController _waveAnimController;
  final List<double> _waveHeights = List.generate(20, (i) => 0.3);
  Timer? _waveTimer;

  // 图片选择
  final ImagePicker _picker = ImagePicker();

  // 消息内正在播放的 voice（mock index）
  int? _playingVoiceIndex;
  Timer? _voicePlayTimer;

  // 常用表情列表
  static const List<String> _emojis = [
    '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😉','😊','😇','🥰','😍',
    '🤩','😘','😗','😚','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔',
    '🤐','🤨','😐','😑','😶','😏','😒','🙄','😬','🤥','😌','😔','😪','🤤',
    '😴','😷','🤒','🤕','🤢','🤮','👍','👎','👏','🙌','🤝','🙏','💪','❤️',
    '🧡','💛','💚','💙','💜','🖤','🤍','💯','💢','💨','💫','💬','🗨️','🗯️',
    '💭','🎉','🎊','🎈','🎁','🏆','🥇','🎵','🎶','🎤',
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
    _ChatMessage(type: _MsgType.voice, isMe: true, duration: 5),
  ];

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _focusNode.addListener(() {
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
    _waveAnimController.dispose();
    _recordTimer?.cancel();
    _previewPlayTimer?.cancel();
    _waveTimer?.cancel();
    _voicePlayTimer?.cancel();
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

  // ─── 录音状态机 ───────────────────────────────────────────────────────────

  /// 切换话筒模式：idle ↔ ready（输入框变录音条）
  void _toggleVoiceMode() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_recordState == _RecordState.idle) {
        _recordState = _RecordState.ready;
        _focusNode.unfocus();
        _showEmojiPicker = false;
        _showIconBar = false;
      } else {
        _recordState = _RecordState.idle;
      }
    });
  }

  /// 长按开始录音
  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    try {
      if (await _recorder!.hasPermission()) {
        final tempDir = await Directory.systemTemp.createTemp('chat_voice');
        final filePath =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder!.start(const RecordConfig(), path: filePath);
        _recordSeconds = 0;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _recordSeconds++);
          if (_recordSeconds >= 60) _stopRecording(); // 最长1分钟
        });
        _startWaveAnimation();
        setState(() {
          _recordState = _RecordState.recording;
          _recordedPath = filePath;
        });
        _showRecordingOverlay();
      } else {
        _showPermissionTip();
      }
    } catch (e) {
      debugPrint('开始录音失败: $e');
    }
  }

  /// 松手停止录音
  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _stopWaveAnimation();
    try {
      final path = await _recorder?.stop();
      if (path != null || _recordedPath != null) {
        setState(() {
          _recordState = _RecordState.preview;
        });
        // 更新浮层到预览模式（通过 setState 驱动）
      } else {
        setState(() => _recordState = _RecordState.ready);
      }
    } catch (e) {
      debugPrint('停止录音失败: $e');
      setState(() => _recordState = _RecordState.ready);
    }
  }

  /// 发送录音消息
  void _sendVoiceMessage() {
    final duration = _recordSeconds.clamp(1, 60);
    setState(() {
      _messages.add(
        _ChatMessage(type: _MsgType.voice, isMe: true, duration: duration),
      );
      _recordState = _RecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
      _previewPlaying = false;
    });
    Navigator.of(context).pop(); // 关闭浮层
    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  /// 取消录音
  void _cancelRecording() {
    setState(() {
      _recordState = _RecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
      _previewPlaying = false;
    });
    Navigator.of(context).pop();
    HapticFeedback.lightImpact();
  }

  // ─── 波形动画 ─────────────────────────────────────────────────────────────

  void _startWaveAnimation() {
    final random = Random();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.2 + random.nextDouble() * 0.8;
        }
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.3;
      }
    });
  }

  // ─── 录音浮层 ─────────────────────────────────────────────────────────────

  void _showRecordingOverlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _RecordingOverlay(
        state: this,
      ),
    );
  }

  void _showPermissionTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请授予麦克风权限'), duration: Duration(seconds: 2)),
    );
  }

  // ─── 消息内语音播放（Mock）────────────────────────────────────────────────

  void _playVoiceMessage(int index) {
    if (_playingVoiceIndex == index) {
      // 再次点击停止
      _voicePlayTimer?.cancel();
      setState(() => _playingVoiceIndex = null);
      return;
    }
    _voicePlayTimer?.cancel();
    final msg = _messages[index];
    setState(() => _playingVoiceIndex = index);
    _voicePlayTimer = Timer(
      Duration(seconds: (msg.duration ?? 3) + 1),
      () {
        if (mounted) setState(() => _playingVoiceIndex = null);
      },
    );
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const SizedBox(height: 8);
                }
                return _buildChatMessage(
                  context,
                  _messages[index],
                  index,
                  isDark,
                  effectiveAvatar,
                );
              },
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
    int index,
    bool isDark,
    String peerAvatar,
  ) {
    switch (msg.type) {
      case _MsgType.timestamp:
        return _buildTimestamp(msg.time!);
      case _MsgType.text:
        return _buildTextMessage(msg, isDark, peerAvatar);
      case _MsgType.voice:
        return _buildVoiceMessage(msg, index, isDark, peerAvatar);
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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatarWidget(avatarUrl, isDark),
          if (!isMe) const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  Widget _buildVoiceMessage(
    _ChatMessage msg,
    int index,
    bool isDark,
    String peerAvatar,
  ) {
    final avatarUrl = msg.isMe ? _myAvatar : peerAvatar;
    final isPlaying = _playingVoiceIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 根据时长计算气泡宽度（40~160）
    final bubbleWidth = (40.0 + (msg.duration ?? 3) * 8.0).clamp(80.0, 180.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isMe) _buildAvatarWidget(avatarUrl, isDark),
          if (!msg.isMe) const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _playVoiceMessage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(
                minWidth: bubbleWidth.clamp(80.0, 180.0),
                maxWidth: bubbleWidth.clamp(80.0, 180.0),
              ),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: msg.isMe
                    ? (isPlaying
                        ? primaryColor.withValues(alpha: 1)
                        : primaryColor.withValues(alpha: 0.85))
                    : (isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
                  bottomRight: Radius.circular(msg.isMe ? 4 : 18),
                ),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 播放/暂停图标
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                    color: msg.isMe
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  // 波形图标或动态波形
                  isPlaying
                      ? _buildPlayingWave(msg.isMe, isDark)
                      : Icon(
                          Icons.graphic_eq,
                          size: 18,
                          color: msg.isMe
                              ? Colors.white70
                              : (isDark ? Colors.white54 : Colors.black38),
                        ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${msg.duration}"',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: msg.isMe
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
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

  /// 播放中波形动画（3条小竖线）
  Widget _buildPlayingWave(bool isMe, bool isDark) {
    final color = isMe ? Colors.white70 : (isDark ? Colors.white54 : Colors.black38);
    return SizedBox(
      width: 18,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 100),
            curve: Curves.easeInOut,
            builder: (_, v, __) => AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 100),
              width: 3,
              height: 6 + v * 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildImageMessage(
      _ChatMessage msg, bool isDark, String peerAvatar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
  // 底部区域：输入行 → 表情面板 → 可展开图标栏
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
            // 输入行
            _buildInputRow(context, isDark, colorScheme),
            // 表情面板
            if (_showEmojiPicker) _buildEmojiPicker(context, isDark),
            // 可展开图标栏
            if (_showIconBar)
              _buildExpandedIconBar(context, isDark, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 输入行：话筒 | 输入框 or 长按录音条 | 表情 | 加号
  Widget _buildInputRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isVoiceMode = _recordState != _RecordState.idle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 左侧话筒/键盘切换按钮
          GestureDetector(
            onTap: _toggleVoiceMode,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isVoiceMode
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic_outlined,
                size: 22,
                color: isVoiceMode
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 中间：文字输入框 or 长按录音条
          Expanded(
            child: isVoiceMode
                ? _buildVoiceRecordBar(isDark, colorScheme)
                : _buildTextInputField(isDark),
          ),
          const SizedBox(width: 8),
          // 表情按钮（语音模式下隐藏）
          if (!isVoiceMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                  if (_showEmojiPicker) _focusNode.unfocus();
                });
              },
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard_alt_outlined
                    : Icons.emoji_emotions_outlined,
              ),
            ),
          // 圆形加号按钮
          IconButton(
            onPressed: () {
              setState(() {
                _showIconBar = !_showIconBar;
                if (_showIconBar) {
                  _showEmojiPicker = false;
                  _focusNode.unfocus();
                }
              });
            },
            icon: _showIconBar
                ? const Icon(Icons.arrow_drop_down_circle_outlined)
                : const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  /// 文字输入框
  Widget _buildTextInputField(bool isDark) {
    return Container(
      height: 40,
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
          hintText: '说点什么...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.black38,
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
    );
  }

  /// 长按录音条
  Widget _buildVoiceRecordBar(bool isDark, ColorScheme colorScheme) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        decoration: BoxDecoration(
          color: _recordState == _RecordState.recording
              ? colorScheme.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _recordState == _RecordState.recording
                ? colorScheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: 16,
              color: _recordState == _RecordState.recording
                  ? colorScheme.primary
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(width: 6),
            Text(
              '长按录音',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _recordState == _RecordState.recording
                    ? colorScheme.primary
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
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
          _buildIconBarItem(
            icon: Icons.image_outlined,
            label: '图片',
            colorScheme: colorScheme,
            onTap: () {
              _pickAndSendImage();
              setState(() => _showIconBar = false);
            },
          ),
          _buildIconBarItem(
            icon: Icons.camera_alt_outlined,
            label: '拍照',
            colorScheme: colorScheme,
            onTap: () {},
          ),
          _buildIconBarItem(
            icon: Icons.card_giftcard,
            label: '礼物',
            colorScheme: colorScheme,
            isPrimary: true,
            onTap: () {},
          ),
          _buildIconBarItem(
            icon: Icons.location_on_outlined,
            label: '位置',
            colorScheme: colorScheme,
            onTap: () {},
          ),
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
            style:
                TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
              child: Text(
                _emojis[index],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 录音浮层（独立 StatefulWidget，订阅父 State 的变化）
// ──────────────────────────────────────────────────────────────────────────────

class _RecordingOverlay extends StatefulWidget {
  final _ChatContentState state;
  const _RecordingOverlay({required this.state});

  @override
  State<_RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<_RecordingOverlay> {
  @override
  void initState() {
    super.initState();
    // 监听父 State 变化（录音完成 → preview 模式）
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenParent());
  }

  void _listenParent() {
    // 父级状态变化时重建
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<_RecordState>(
      stream: s._recordStateStream,
      initialData: s._recordState,
      builder: (context, snapshot) {
        final currentState = snapshot.data ?? s._recordState;
        final inPreview = currentState == _RecordState.preview;
        return _buildSheet(context, inPreview, isDark, colorScheme);
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    bool inPreview,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final s = widget.state;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动把手
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              inPreview ? '录音完成' : '正在录音...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 内容区
          inPreview
              ? _buildPreviewContent(context, isDark, colorScheme, s)
              : _buildRecordingContent(context, isDark, colorScheme, s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 录音中内容：大话筒 + 波形 + 计时
  Widget _buildRecordingContent(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    _ChatContentState s,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 麦克风图标（脉冲效果）
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, size: 36, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          // 波形可视化
          SizedBox(
            height: 48,
            child: StatefulBuilder(
              builder: (context, setWave) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: s._waveHeights.map((h) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      width: 4,
                      height: 8 + h * 36,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.6 + h * 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 计时器
          Text(
            _formatDuration(s._recordSeconds),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '松手停止录音',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  /// 预览内容：播放条 + 发送/取消
  Widget _buildPreviewContent(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    _ChatContentState s,
  ) {
    final duration = s._recordSeconds.clamp(1, 60);
    final isPlaying = s._previewPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 播放条
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // 播放按钮
                GestureDetector(
                  onTap: () {
                    s.setState(() {
                      s._previewPlaying = !s._previewPlaying;
                    });
                    if (s._previewPlaying) {
                      // Mock 播放：duration 秒后停止
                      s._previewPlayTimer?.cancel();
                      s._previewPlayTimer =
                          Timer(Duration(seconds: duration + 1), () {
                        if (s.mounted) {
                          s.setState(() => s._previewPlaying = false);
                          setState(() {});
                        }
                      });
                    } else {
                      s._previewPlayTimer?.cancel();
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 波形/进度条
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: isPlaying
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(seconds: duration),
                                builder: (_, v, __) => FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: v,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '录音 ${_formatDuration(duration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          Icon(
                            Icons.graphic_eq,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 发送 / 取消
          Row(
            children: [
              // 取消按钮
              Expanded(
                child: GestureDetector(
                  onTap: s._cancelRecording,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 发送按钮
              Expanded(
                child: GestureDetector(
                  onTap: s._sendVoiceMessage,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          '发送',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 录音状态流扩展（用于浮层订阅）
// ──────────────────────────────────────────────────────────────────────────────

extension _RecordStateStreamExt on _ChatContentState {
  Stream<_RecordState> get _recordStateStream async* {
    _RecordState last = _recordState;
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) break;
      if (_recordState != last) {
        last = _recordState;
        yield last;
      }
    }
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
    // ignore: unused_element_parameter
    this.giftEmoji,
    // ignore: unused_element_parameter
    this.giftLabel,
    this.time,
  });
}

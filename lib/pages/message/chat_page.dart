import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komodo/pages/message/emojis.dart';
import 'package:komodo/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:komodo/pages/message/chat_voice_controller.dart';
import 'models/chat_models.dart';
import 'widgets/chat_timestamp.dart';
import 'widgets/chat_text_bubble.dart';
import 'widgets/chat_voice_bubble.dart';
import 'widgets/chat_image_bubble.dart';
import 'widgets/chat_gift_bubble.dart';
import 'widgets/record_overlay.dart';

/// 聊天详情页 — 社交私信聊天界面
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

class _ChatContentState extends State<_ChatContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  final List<ChatMessage> _messages = List.from(_initialMessages);

  bool _showEmojiPicker = false;
  bool _showIconBar = false;

  static const double _expandedHeight = 260.0;

  ChatRecordState _recordState = ChatRecordState.idle;

  AudioRecorder? _recorder;
  String? _recordedPath;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  OverlayEntry? _overlayEntry;

  int? _playingVoiceIndex;

  final List<double> _waveHeights = List.generate(20, (i) => 0.0);
  StreamSubscription<Amplitude>? _amplitudeSub;

  final ImagePicker _picker = ImagePicker();

  static const String _myAvatar = 'https://picsum.photos/seed/myavatar/100/100';

  static const List<ChatMessage> _initialMessages = [
    ChatMessage(type: ChatMsgType.timestamp, time: '19:01'),
    ChatMessage(type: ChatMsgType.text, isMe: false, content: '嗨，你好呀～很高兴认识你 😊'),
    ChatMessage(type: ChatMsgType.voice, isMe: false, duration: 11),
    ChatMessage(
      type: ChatMsgType.image,
      isMe: false,
      imageUrl: 'https://picsum.photos/seed/chatimg1/400/600',
    ),
    ChatMessage(type: ChatMsgType.text, isMe: false, content: '回复了一条信息'),
    ChatMessage(type: ChatMsgType.text, isMe: true, content: '你好呀～'),
    ChatMessage(
      type: ChatMsgType.voice,
      voicePath: 'https://www.w3schools.com/html/horse.mp3',
      isMe: true,
      duration: 5,
    ),
  ];

  final voiceCtrl = Get.put(ChatVoiceController());
  Worker? _lisenPlaying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recorder = AudioRecorder();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    _lisenPlaying = ever(voiceCtrl.isPlaying, (bool playing) {
      if (!playing && mounted) {
        setState(() => _playingVoiceIndex = null);
        _overlayEntry?.markNeedsBuild();
      }
    });
    if (!Get.isRegistered<ChatVoiceController>()) {
      Get.put(ChatVoiceController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bool isKeyboardVisible = View.of(context).viewInsets.bottom > 0;
    if (_isKeyboardVisible != isKeyboardVisible) {
      setState(() => _isKeyboardVisible = isKeyboardVisible);
      if (!isKeyboardVisible && _focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recorder?.dispose();
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    _lisenPlaying?.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _scrollToBottom({int milliseconds = 60}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
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
          ChatMessage(type: ChatMsgType.text, isMe: true, content: trimmed));
    });
    _textController.clear();
    _scrollToBottom();
  }

  void _sendEmojiMessage(String emoji) {
    setState(() {
      _textController.text = _textController.text + emoji;
    });
    _scrollToBottom();
  }

  void _sendImageMessage(String imagePath) {
    setState(() {
      _messages.add(ChatMessage(
          type: ChatMsgType.image,
          isMe: true,
          imageUrl: imagePath,
          isLocalImage: true));
    });
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) _sendImageMessage(image.path);
    } catch (e) {
      debugPrint('图片选择失败: $e');
    }
  }

  // ─── 录音 ────────────────────────────────────────────────────────────

  void _toggleVoiceMode() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_recordState == ChatRecordState.idle) {
        _recordState = ChatRecordState.ready;
        _focusNode.unfocus();
        _showEmojiPicker = false;
        _showIconBar = false;
      } else {
        _recordState = ChatRecordState.idle;
      }
      _scrollToBottom();
    });
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    try {
      if (await _recorder!.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory('${appDir.path}/voice_messages');
        if (!await voiceDir.exists()) {
          await voiceDir.create(recursive: true);
        }
        final filePath =
            '${voiceDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder!.start(const RecordConfig(), path: filePath);
        _recordSeconds = 0;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => _recordSeconds++);
          if (_recordSeconds >= 60) _stopRecording();
        });
        _startWaveAnimation();
        Get.find<ChatVoiceController>().stop();
        setState(() {
          _recordState = ChatRecordState.recording;
          _recordedPath = filePath;
        });
        _showRecordingOverlay();
      } else {
        _showPermissionTip();
      }
    } catch (e) {
      debugPrint('【录音失败】开始异常: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _stopWaveAnimation();
    try {
      await _recorder?.stop();
      if (_recordedPath != null) {
        final file = File(_recordedPath!);
        if (await file.exists()) {
          final size = await file.length();
          if (size < 100) {
            debugPrint('【录音异常】文件过小(${size}B)');
          }
          setState(() => _recordState = ChatRecordState.preview);
          _overlayEntry?.markNeedsBuild();
        } else {
          _removeOverlay();
          setState(() => _recordState = ChatRecordState.ready);
        }
      } else {
        _removeOverlay();
        setState(() => _recordState = ChatRecordState.ready);
      }
    } catch (e) {
      debugPrint('【录音失败】停止异常: $e');
      _removeOverlay();
      setState(() => _recordState = ChatRecordState.ready);
    }
  }

  Future<void> _sendVoiceMessage() async {
    final duration = _recordSeconds.clamp(1, 60);
    final path = _recordedPath;
    await voiceCtrl.stop();
    setState(() {
      _messages.add(ChatMessage(
          type: ChatMsgType.voice,
          isMe: true,
          duration: duration,
          voicePath: path));
      _recordState = ChatRecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
    });
    _removeOverlay();
    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  void _cancelRecording() {
    if (_recordedPath != null) {
      try {
        File(_recordedPath!).deleteSync();
      } catch (e) {
        debugPrint('【取消录音】删除失败: $e');
      }
    }
    voiceCtrl.stop();
    setState(() {
      _recordState = ChatRecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
    });
    _removeOverlay();
    HapticFeedback.lightImpact();
  }

  // ─── 波形动画 ────────────────────────────────────────────────────────

  void _startWaveAnimation() {
    final recorder = _recorder;
    _amplitudeSub?.cancel();
    if (recorder == null) return;
    _amplitudeSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      if (!mounted) return;
      final normalized = _dbfsToNormalized(amp.current);
      setState(() {
        _waveHeights.removeAt(0);
        _waveHeights.add(normalized);
      });
      _overlayEntry?.markNeedsBuild();
    });
  }

  double _dbfsToNormalized(double dbfs) {
    const minDb = -60.0;
    if (dbfs < minDb) return 0.05;
    return ((dbfs - minDb) / (-minDb)).clamp(0.05, 1.0);
  }

  void _stopWaveAnimation() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.0;
      }
    });
  }

  // ─── Overlay ─────────────────────────────────────────────────────────

  void _showRecordingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (ctx) => RecordOverlay(
        recordState: _recordState,
        waveHeights: _waveHeights,
        recordSeconds: _recordSeconds,
        recordedPath: _recordedPath,
        colorScheme: Theme.of(context).colorScheme,
        onTogglePreviewPlay: _togglePreviewPlay,
        onCancelRecording: _cancelRecording,
        onSendVoiceMessage: _sendVoiceMessage,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showPermissionTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('请授予麦克风权限'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _togglePreviewPlay() async {
    if (_recordedPath == null) return;
    try {
      if (voiceCtrl.isPlayingPath(_recordedPath!)) {
        await voiceCtrl.stop();
      } else {
        await voiceCtrl.play(_recordedPath!);
      }
    } catch (e) {
      debugPrint('【预览播放失败】$e');
    }
  }

  Future<void> _playVoiceMessage(int index) async {
    final msg = _messages[index];
    if (msg.type != ChatMsgType.voice) return;
    final ctrl = Get.find<ChatVoiceController>();
    if (_playingVoiceIndex == index && ctrl.isPlayingPath(msg.voicePath ?? '')) {
      await ctrl.stop();
      setState(() => _playingVoiceIndex = null);
      return;
    }
    try {
      if (msg.voicePath != null) {
        await ctrl.play(msg.voicePath!);
        setState(() => _playingVoiceIndex = index);
      }
    } catch (e) {
      debugPrint('【消息播放失败】index=$index: $e');
      if (mounted) setState(() => _playingVoiceIndex = null);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    color: Colors.red, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('2',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        title: Text(widget.peerName,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() {
                HapticFeedback.lightImpact();
                _showEmojiPicker = false;
                _showIconBar = false;
                _scrollToBottom(milliseconds: 280);
                _focusNode.unfocus();
              }),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const SizedBox(height: 8);
                  }
                  return _buildChatMessage(
                      context, _messages[index], index);
                },
              ),
            ),
          ),
          _buildBottomArea(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildChatMessage(BuildContext context, ChatMessage msg, int index) {
    switch (msg.type) {
      case ChatMsgType.timestamp:
        return ChatTimestamp(time: msg.time!);
      case ChatMsgType.text:
        return ChatTextBubble(
          text: msg.content!,
          isMe: msg.isMe,
          avatarUrl: msg.isMe ? _myAvatar : widget.peerAvatar,
        );
      case ChatMsgType.voice:
        return ChatVoiceBubble(
          duration: msg.duration ?? 0,
          isMe: msg.isMe,
          isPlaying: _playingVoiceIndex == index,
          avatarUrl: msg.isMe ? _myAvatar : widget.peerAvatar,
          onTap: () => _playVoiceMessage(index),
        );
      case ChatMsgType.image:
        return ChatImageBubble(
          imageUrl: msg.imageUrl!,
          isLocalImage: msg.isLocalImage,
          isMe: msg.isMe,
          avatarUrl: msg.isMe ? _myAvatar : widget.peerAvatar,
          onTap: () => Get.toNamed(Routes.imageViewer, arguments: {
            'imageUrl': msg.imageUrl,
            'isLocalImage': msg.isLocalImage,
          }),
        );
      case ChatMsgType.gift:
        return ChatGiftBubble(
          giftEmoji: msg.giftEmoji!,
          giftLabel: msg.giftLabel!,
          avatarUrl: _myAvatar,
        );
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // 底部区域
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildBottomArea(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputRow(context, colorScheme),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                    sizeFactor: animation, axisAlignment: -1.0, child: child),
              ),
              child: _showEmojiPicker
                  ? _buildEmojiPicker(context)
                  : (_showIconBar
                      ? _buildExpandedIconBar(context, colorScheme)
                      : const SizedBox(key: ValueKey('empty'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context, ColorScheme colorScheme) {
    final isVoiceMode = _recordState != ChatRecordState.idle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.comfortable,
            onPressed: _toggleVoiceMode,
            icon: Icon(
              isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic_outlined,
              size: 26,
              color: colorScheme.inverseSurface,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: isVoiceMode
                ? _buildVoiceRecordBar(colorScheme)
                : _buildTextInputField(colorScheme),
          ),
          const SizedBox(width: 2),
          if (!isVoiceMode && _recordState == ChatRecordState.idle)
            IconButton(
              visualDensity: VisualDensity.comfortable,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (_showEmojiPicker) {
                    _showEmojiPicker = false;
                    _showIconBar = false;
                  } else {
                    _showEmojiPicker = true;
                    _showIconBar = false;
                    _focusNode.unfocus();
                  }
                  _scrollToBottom(milliseconds: 280);
                });
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  key: ValueKey(_showEmojiPicker),
                  size: 26,
                  color: _showEmojiPicker
                      ? colorScheme.primary
                      : colorScheme.inverseSurface,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(isVoiceMode ? 0 : -6, 0),
            child: IconButton(
              visualDensity: VisualDensity.comfortable,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (_showIconBar) {
                    _showIconBar = false;
                    _showEmojiPicker = false;
                  } else {
                    _showIconBar = true;
                    _showEmojiPicker = false;
                    _focusNode.unfocus();
                  }
                  _scrollToBottom(milliseconds: 280);
                });
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _showIconBar
                      ? Icons.arrow_drop_down_circle
                      : Icons.add_circle_outline,
                  key: ValueKey(_showIconBar),
                  size: 26,
                  color: _showIconBar
                      ? colorScheme.primary
                      : colorScheme.inverseSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        decoration: InputDecoration(
          fillColor: colorScheme.outline,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          isDense: true,
        ),
        onSubmitted: _sendTextMessage,
      ),
    );
  }

  Widget _buildVoiceRecordBar(ColorScheme colorScheme) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.outline,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 16),
            SizedBox(width: 6),
            Text('长按录音'),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedIconBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: _expandedHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: colorScheme.outline, width: 1))),
            padding: const EdgeInsets.all(16),
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
                    }),
                _buildIconBarItem(
                    icon: Icons.camera_alt_outlined,
                    label: '拍照',
                    colorScheme: colorScheme,
                    onTap: () {}),
                _buildIconBarItem(
                    icon: Icons.card_giftcard,
                    label: '礼物',
                    colorScheme: colorScheme,
                    onTap: () {}),
                _buildIconBarItem(
                    icon: Icons.location_on_outlined,
                    label: '位置',
                    colorScheme: colorScheme,
                    onTap: () {}),
                _buildIconBarItem(
                    icon: Icons.kebab_dining,
                    label: '红包',
                    colorScheme: colorScheme,
                    onTap: () {}),
              ],
            ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: colorScheme.surfaceContainer),
            child: Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: _expandedHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border:
            Border(top: BorderSide(color: colorScheme.outline, width: 1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: EmojiList.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _sendEmojiMessage(EmojiList[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text(EmojiList[index],
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

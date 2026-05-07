import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komodo/pages/message/emojis.dart';
import 'package:record/record.dart';
import 'package:komodo/pages/music/music_player_controller.dart';

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

// 录音状态枚举
enum _RecordState {
  idle, // 文字输入模式
  ready, // 长按录音模式
  recording, // 正在录音
  preview, // 录音预览
}

class _ChatContentState extends State<_ChatContent>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = List.from(_initialMessages);

  bool _showEmojiPicker = false;
  bool _showIconBar = false;
  _RecordState _recordState = _RecordState.idle;

  // 录音
  AudioRecorder? _recorder;
  String? _recordedPath;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // 浮层
  OverlayEntry? _overlayEntry;

  // 本地播放状态标记（实际播放走 MusicPlayerController 全局单例）
  bool _previewPlaying = false;
  int? _playingVoiceIndex;

  // 波形动画
  final List<double> _waveHeights = List.generate(20, (i) => 0.3);
  Timer? _waveTimer;

  // 图片选择
  final ImagePicker _picker = ImagePicker();

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
    _ChatMessage(
      type: _MsgType.voice,
      voicePath: 'https://www.w3schools.com/html/horse.mp3',
      isMe: true,
      duration: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
    // 监听全局语音播放完成，同步本地状态
    final ctrl = Get.find<MusicPlayerController>();
    ever(ctrl.isPlayingVoice, (bool playing) {
      if (!playing && mounted) {
        setState(() {
          _previewPlaying = false;
          _playingVoiceIndex = null;
        });
        _overlayEntry?.markNeedsBuild();
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
    _recordTimer?.cancel();
    _waveTimer?.cancel();
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
      if (image != null) _sendImageMessage(image.path);
    } catch (e) {
      debugPrint('图片选择失败: $e');
    }
  }

  // ─── 录音 ────────────────────────────────────────────────────────────────

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

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    try {
      if (await _recorder!.hasPermission()) {
        final tempDir = await Directory.systemTemp.createTemp('chat_voice');
        final filePath =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder!.start(const RecordConfig(), path: filePath);
        debugPrint('【录音开始】path=$filePath');
        _recordSeconds = 0;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => _recordSeconds++);
          debugPrint('【录音计时】${_recordSeconds}s');
          if (_recordSeconds >= 60) _stopRecording();
        });
        _startWaveAnimation();
        // 停止可能正在播放的语音
        Get.find<MusicPlayerController>().stopVoice();
        setState(() {
          _recordState = _RecordState.recording;
          _recordedPath = filePath;
          _previewPlaying = false;
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
          debugPrint(
            '【录音完成】file=$_recordedPath size=$size bytes dur=${_recordSeconds}s',
          );
          if (size < 100) {
            debugPrint('【录音异常】文件过小(${size}B)，可能未正常写入');
          }
          setState(() => _recordState = _RecordState.preview);
          _overlayEntry?.markNeedsBuild();
        } else {
          debugPrint('【录音异常】文件不存在: $_recordedPath');
          _removeOverlay();
          setState(() => _recordState = _RecordState.ready);
        }
      } else {
        debugPrint('【录音异常】_recordedPath 为 null');
        _removeOverlay();
        setState(() => _recordState = _RecordState.ready);
      }
    } catch (e) {
      debugPrint('【录音失败】停止异常: $e');
      _removeOverlay();
      setState(() => _recordState = _RecordState.ready);
    }
  }

  Future<void> _sendVoiceMessage() async {
    final duration = _recordSeconds.clamp(1, 60);
    final path = _recordedPath;
    final ctrl = Get.find<MusicPlayerController>();
    await ctrl.stopVoice();
    setState(() {
      _messages.add(
        _ChatMessage(
          type: _MsgType.voice,
          isMe: true,
          duration: duration,
          voicePath: path, // 携带真实文件路径
        ),
      );
      _recordState = _RecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
      _previewPlaying = false;
    });
    _removeOverlay();
    _scrollToBottom();
    HapticFeedback.lightImpact();
    debugPrint('【发送录音】path=$path');
  }

  void _cancelRecording() {
    if (_recordedPath != null) {
      try {
        File(_recordedPath!).deleteSync();
        debugPrint('【取消录音】已删除: $_recordedPath');
      } catch (e) {
        debugPrint('【取消录音】删除失败: $e');
      }
    }
    Get.find<MusicPlayerController>().stopVoice();
    setState(() {
      _recordState = _RecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
      _previewPlaying = false;
    });
    _removeOverlay();
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
      _overlayEntry?.markNeedsBuild();
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

  // ─── Overlay 浮层 ─────────────────────────────────────────────────────────

  void _showRecordingOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(builder: (ctx) => _RecordOverlay(state: this));
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showPermissionTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请授予麦克风权限'), duration: Duration(seconds: 2)),
    );
  }

  // ─── 预览播放 ─────────────────────────────────────────────────────────────

  Future<void> _togglePreviewPlay() async {
    if (_recordedPath == null) {
      debugPrint('【预览】_recordedPath 为 null');
      return;
    }
    final ctrl = Get.find<MusicPlayerController>();
    try {
      // 读取全局播放器的真实状态
      final isGlobalPlaying = ctrl.isPlayingVoice.value;
      final globalPath = ctrl.voiceFilePath.value;
      final isThisPlaying = isGlobalPlaying && globalPath == _recordedPath;

      if (isThisPlaying) {
        await ctrl.stopVoice();
        setState(() => _previewPlaying = false);
        debugPrint('【预览播放】已停止');
      } else {
        await ctrl.playVoice(_recordedPath!);
        setState(() => _previewPlaying = true);
        debugPrint('【预览播放】开始: $_recordedPath');
      }
    } catch (e) {
      debugPrint('【预览播放失败】$e');
      setState(() => _previewPlaying = false);
    }
  }

  // ─── 消息内语音播放 ──────────────────────────────────────────────────────

  Future<void> _playVoiceMessage(int index) async {
    final msg = _messages[index];
    if (msg.type != _MsgType.voice) return;

    final ctrl = Get.find<MusicPlayerController>();
    final globalPath = ctrl.voiceFilePath.value;

    // 已经在播放这条 → 停止
    if (_playingVoiceIndex == index &&
        ctrl.isPlayingVoice.value &&
        globalPath == msg.voicePath) {
      await ctrl.stopVoice();
      setState(() => _playingVoiceIndex = null);
      debugPrint('【消息播放】停止: index=$index');
      return;
    }

    try {
      if (msg.voicePath != null) {
        // 停止其他所有播放
        await ctrl.stopVoice();
        // 播放新语音
        await ctrl.playVoice(msg.voicePath!);
        setState(() => _playingVoiceIndex = index);
        debugPrint('【消息播放】开始: index=$index path=${msg.voicePath}');
      } else {
        debugPrint('【消息播放】无文件路径(Mock): index=$index');
      }
    } catch (e) {
      debugPrint('【消息播放失败】index=$index: $e');
      if (mounted) setState(() => _playingVoiceIndex = null);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          widget.peerName,
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == _messages.length) return const SizedBox(height: 8);
                return _buildChatMessage(
                  context,
                  _messages[index],
                  index,
                  isDark,
                  widget.peerAvatar,
                );
              },
            ),
          ),
          _buildBottomArea(context, isDark, colorScheme),
        ],
      ),
    );
  }

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

  Widget _buildTimestamp(String time) => Center(
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

  Widget _buildTextMessage(_ChatMessage msg, bool isDark, String peerAvatar) {
    final isMe = msg.isMe;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatarWidget(isMe ? _myAvatar : peerAvatar, isDark),
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
          if (isMe) _buildAvatarWidget(_myAvatar, isDark),
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
    final bubbleWidth = (80.0 + (msg.duration ?? 3) * 10.0).clamp(80.0, 180.0);

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
            onTap: () => _playVoiceMessage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(
                minWidth: bubbleWidth,
                maxWidth: bubbleWidth,
              ),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: msg.isMe
                    ? (isPlaying
                          ? primaryColor
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
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                    color: msg.isMe
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 4),
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

  Widget _buildPlayingWave(bool isMe, bool isDark) {
    final color = isMe
        ? Colors.white70
        : (isDark ? Colors.white54 : Colors.black38);
    return SizedBox(
      width: 18,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          3,
          (i) => TweenAnimationBuilder<double>(
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
          ),
        ),
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

  Widget _buildImagePlaceholder(bool isDark) => Container(
    width: 180,
    height: 240,
    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
    child: Icon(
      Icons.broken_image,
      color: isDark ? Colors.white24 : Colors.grey[400],
      size: 40,
    ),
  );

  Widget _buildGiftMessage(_ChatMessage msg) => Container(
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

  Widget _buildAvatarWidget(String url, bool isDark) => CircleAvatar(
    radius: 20,
    backgroundImage: NetworkImage(url),
    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
  );

  // ════════════════════════════════════════════════════════════════════════
  // 底部区域
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomArea(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) => Container(
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
          _buildInputRow(context, isDark, colorScheme),
          if (_showEmojiPicker) _buildEmojiPicker(context, isDark),
          if (_showIconBar) _buildExpandedIconBar(context, isDark, colorScheme),
        ],
      ),
    ),
  );

  Widget _buildInputRow(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final isVoiceMode = _recordState != _RecordState.idle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.comfortable,
            onPressed: _toggleVoiceMode,
            icon: Icon(
              isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic_outlined,
              size: 26,
              color: colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 2),
          Expanded(
            child: isVoiceMode
                ? _buildVoiceRecordBar(isDark, colorScheme)
                : _buildTextInputField(isDark, colorScheme),
          ),
          const SizedBox(width: 2),
          if (!isVoiceMode)
            IconButton(
              visualDensity: VisualDensity.comfortable,
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
                size: 26,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.comfortable,
            onPressed: () {
              setState(() {
                _showIconBar = !_showIconBar;
                if (_showIconBar) {
                  _showEmojiPicker = false;
                  _focusNode.unfocus();
                }
              });
            },
            icon: Icon(
              _showIconBar
                  ? Icons.arrow_drop_down_circle_outlined
                  : Icons.add_circle_outline,
              size: 26,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputField(
    bool isDark,
    ColorScheme colorScheme,
  ) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: colorScheme.primaryContainer,
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
        hintStyle: TextStyle(fontSize: 14, color: colorScheme.primaryContainer),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        isDense: true,
      ),
      onSubmitted: _sendTextMessage,
    ),
  );

  Widget _buildVoiceRecordBar(bool isDark, ColorScheme colorScheme) =>
      GestureDetector(
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

  Widget _buildExpandedIconBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) => Container(
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

  Widget _buildIconBarItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) => GestureDetector(
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

  Widget _buildEmojiPicker(BuildContext context, bool isDark) => Container(
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
      itemCount: EmojiList.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _sendEmojiMessage(EmojiList[index]),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
          ),
          alignment: Alignment.center,
          child: Text(EmojiList[index], style: const TextStyle(fontSize: 24)),
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 录音 Overlay 浮层
// ──────────────────────────────────────────────────────────────────────────────

class _RecordOverlay extends StatelessWidget {
  final _ChatContentState state;
  const _RecordOverlay({required this.state});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Material(
      color: Colors.transparent,
      child: state._recordState == _RecordState.recording
          ? _RecordOverlayRecording(state: state)
          : _RecordOverlayPreview(state: state),
    ),
  );
}

String _fmtDur(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

class _RecordOverlayRecording extends StatelessWidget {
  final _ChatContentState state;
  const _RecordOverlayRecording({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _PulsingMic(colorScheme: cs),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: state._waveHeights
                      .map(
                        (h) => AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: 4,
                          height: 8 + h * 28,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.5 + h * 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _fmtDur(state._recordSeconds),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '松手结束录音',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RecordOverlayPreview extends StatelessWidget {
  final _ChatContentState state;
  const _RecordOverlayPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final dur = state._recordSeconds.clamp(1, 60);
    final playing = state._previewPlaying;

    final handleBar = Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );

    final playBtn = GestureDetector(
      onTap: () => state._togglePreviewPlay(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
      ),
    );

    final cancelBtn = GestureDetector(
      onTap: state._cancelRecording,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0),
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
    );

    final sendBtn = GestureDetector(
      onTap: state._sendVoiceMessage,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        // ignore: prefer_const_constructors
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
    );

    final btnRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: cancelBtn),
          const SizedBox(width: 12),
          Expanded(child: sendBtn),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            handleBar,
            const SizedBox(height: 12),
            Text(
              '录音 ${_fmtDur(dur)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            playBtn,
            Text(
              playing ? '播放中...' : '点击播放',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
            btnRow,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PulsingMic extends StatefulWidget {
  final ColorScheme colorScheme;
  const _PulsingMic({required this.colorScheme});
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacityAnim = Tween<double>(
      begin: 0.4,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    height: 80,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic, size: 32, color: widget.colorScheme.primary),
        ),
      ],
    ),
  );
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
  final String? voicePath; // 录音文件真实路径
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
    this.voicePath,
    // ignore: unused_element_parameter
    this.giftEmoji,
    // ignore: unused_element_parameter
    this.giftLabel,
    this.time,
  });
}

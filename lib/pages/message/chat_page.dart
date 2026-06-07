import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komodo/routes/app_routes.dart';
import 'package:komodo/pages/message/controllers/consumer_ws_client.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:komodo/pages/message/chat_voice_controller.dart';
import 'package:komodo/database/chat_database.dart';
import 'models/chat_models.dart';
import 'widgets/chat_timestamp.dart';
import 'widgets/chat_text_bubble.dart';
import 'widgets/chat_voice_bubble.dart';
import 'widgets/chat_image_bubble.dart';
import 'widgets/chat_gift_bubble.dart';
import 'widgets/record_overlay.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/expanded_icon_bar.dart';
import 'widgets/emoji_picker_widget.dart';

/// 聊天详情页 — 支持 WebSocket 收发 + 本地存储 + 视频通话邀请
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final peerUserId = args?['peerUserId'] as int? ?? 0;
    final peerName = args?['peerName'] as String? ?? _defaultPeerName;
    final peerAvatar = args?['peerAvatar'] as String? ?? _defaultPeerAvatar;
    return _ChatContent(
      peerUserId: peerUserId,
      peerName: peerName,
      peerAvatar: peerAvatar,
    );
  }

  static const String _defaultPeerName = '九黎❤️是美女';
  static const String _defaultPeerAvatar =
      'https://picsum.photos/seed/chatpeer/100/100';
}

class _ChatContent extends StatefulWidget {
  final int peerUserId;
  final String peerName;
  final String peerAvatar;
  const _ChatContent({
    required this.peerUserId,
    required this.peerName,
    required this.peerAvatar,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  final List<ChatMessage> _messages = [];
  int? _conversationId;

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

  String _myAvatar = 'https://picsum.photos/seed/myavatar/100/100';

  final voiceCtrl = Get.put(ChatVoiceController());

  /// 处理收到的消息：仅更新界面（数据库写入由全局监听器负责）
  void _onReceiveMessage(ChatMessage msg, String rawMessage) {
    // 添加到界面
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  // WebSocket 相关
  StreamSubscription? _chatMsgSub;
  StreamSubscription? _chatErrorSub;
  StreamSubscription? _offlineMsgSub;
  StreamSubscription? _videoCallInviteSub;
  StreamSubscription? _videoCallAcceptSub;
  StreamSubscription? _videoCallRejectSub;

  // 视频通话状态

  // ---- 数据库初始化 ----

  Future<void> _initConversation() async {
    final db = ChatDatabase.to;
    final (convId, _) = await db.getOrCreateConversation(
      widget.peerName,
      widget.peerAvatar,
    );
    _conversationId = convId;
    final msgs = await db.getMessages(convId);
    if (mounted) {
      setState(() => _messages.addAll(msgs));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
      return Future.value();
    }
    return Future.value();
  }

  Future<void> _saveMessageToDb(ChatMessage msg) async {
    if (_conversationId != null) {
      await ChatDatabase.to.insertMessage(_conversationId!, msg);
    }
  }

  // ---- WebSocket 订阅 ----

  void _setupWsListeners() {
    final ws = Get.find<ConsumerWsClient>();

    // 接收聊天消息
    _chatMsgSub = ws.onChatMessage.listen((data) {
      debugPrint(
        '[ChatPage] 收到消息 from=${data.from} peerUserId=${widget.peerUserId}',
      );
      if (data.from != widget.peerUserId) {
        debugPrint('[ChatPage] 忽略: 不是当前聊天对象的消息');
        return;
      }
      if (!mounted) return;

      final msg = ChatMessage(
        type: ChatMsgType.text,
        isMe: false,
        content: data.message,
      );

      _onReceiveMessage(msg, data.message);
    });

    // 聊天错误
    _chatErrorSub = ws.onChatError.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      }
    });

    // 离线消息（上线时服务端推送的历史消息）
    _offlineMsgSub = ws.onOfflineMessage.listen((data) {
      debugPrint(
        '[ChatPage] 收到离线消息 from=${data.from} peerUserId=${widget.peerUserId}',
      );
      if (data.from != widget.peerUserId) {
        debugPrint('[ChatPage] 忽略离线消息: 不是当前聊天对象');
        return;
      }
      if (!mounted) return;

      final msg = ChatMessage(
        type: ChatMsgType.text,
        isMe: false,
        content: data.message,
      );

      _onReceiveMessage(msg, data.message);
    });
  }

  /// 进入视频通话页面
  void _navigateToVideoCall(String roomId, {bool isCaller = true}) {
    Get.toNamed(
      Routes.chatVideoCall,
      arguments: {
        'peerUserId': widget.peerUserId,
        'peerName': widget.peerName,
        'roomId': roomId,
        'isCaller': isCaller,
      },
    );
  }

  // 播放音频
  Worker? _lisenPlaying;

  @override
  void initState() {
    super.initState();
    _initConversation();
    WidgetsBinding.instance.addObserver(this);
    _recorder = AudioRecorder();
    _focusNode.addListener(() {
      debugPrint('[_focusNode]=========================');
      if (_focusNode.hasFocus) {
        if (_showEmojiPicker || _showIconBar) {
          setState(() {
            _showEmojiPicker = false;
            _showIconBar = false;
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    });
    // 监听播放状态
    _lisenPlaying = ever(voiceCtrl.isPlaying, (bool playing) {
      if (!playing && mounted) {
        setState(() => _playingVoiceIndex = null);
        _overlayEntry?.markNeedsBuild();
      }
    });
    if (!Get.isRegistered<ChatVoiceController>()) {
      Get.put(ChatVoiceController());
    }

    // 订阅 WebSocket 事件
    _setupWsListeners();

    final box = GetStorage();

    final userAvatar =
        box.read<String>('user_avatar') ??
        'https://picsum.photos/seed/myavatar/100/100';
    setState(() {
      _myAvatar = userAvatar;
    });
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
    _chatMsgSub?.cancel();
    _chatErrorSub?.cancel();
    _offlineMsgSub?.cancel();
    _videoCallInviteSub?.cancel();
    _videoCallAcceptSub?.cancel();
    _videoCallRejectSub?.cancel();
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

  // ---- 文本消息：WebSocket 发送 + 本地存储 ----

  void _sendTextMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 发送到 WebSocket
    Get.find<ConsumerWsClient>().sendChatMessage(widget.peerUserId, trimmed);

    // 本地存储
    final msg = ChatMessage(
      type: ChatMsgType.text,
      isMe: true,
      content: trimmed,
    );
    setState(() => _messages.add(msg));
    _saveMessageToDb(msg)
        .then((_) {
          debugPrint('[ChatPage] 发出的消息已写入数据库');
        })
        .catchError((e, stack) {
          debugPrint('[ChatPage] 发出消息写入失败: $e\n$stack');
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
    final msg = ChatMessage(
      type: ChatMsgType.image,
      isMe: true,
      imageUrl: imagePath,
      isLocalImage: true,
    );
    setState(() => _messages.add(msg));
    _saveMessageToDb(msg)
        .then((_) {
          debugPrint('[ChatPage] 发出的消息已保存到数据库');
        })
        .catchError((e) {
          debugPrint('[ChatPage] 保存发出的消息失败: $e');
        });
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${appDir.path}/image_cache');
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }
        final ext = image.path.split('.').last;
        final destPath =
            '${cacheDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(image.path).copy(destPath);
        _sendImageMessage(destPath);
      }
    } catch (e) {
      debugPrint('图片选择失败: $e');
    }
  }

  // ---- 视频通话邀请（发送后立即进入等待页面） ----

  void _startVideoCall() {
    setState(() => _showIconBar = false);

    final myUserId = UserController.to.userId;
    if (myUserId <= 0 || widget.peerUserId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户信息不完整')));
      return;
    }

    // 生成唯一 roomId
    final ids = [myUserId, widget.peerUserId]..sort();
    final roomId = '${ids.first}_${ids.last}';

    // 发送视频通话邀请
    Get.find<ConsumerWsClient>().sendVideoCallInvite(widget.peerUserId, roomId);

    // 立即进入等待页面（此时对方还没接，显示"等待对方接受"）
    _navigateToVideoCall(roomId, isCaller: true);
  }

  // ---- 录音（不变） ----

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
    final msg = ChatMessage(
      type: ChatMsgType.voice,
      isMe: true,
      duration: duration,
      voicePath: path,
    );
    setState(() {
      _messages.add(msg);
      _recordState = ChatRecordState.ready;
      _recordedPath = null;
      _recordSeconds = 0;
    });
    _saveMessageToDb(msg);
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

  // ---- 波形动画 ----

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

  // ---- Overlay ----

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
      const SnackBar(content: Text('请授予麦克风权限'), duration: Duration(seconds: 2)),
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
    if (_playingVoiceIndex == index &&
        ctrl.isPlayingPath(msg.voicePath ?? '')) {
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

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                  return _buildChatMessage(context, _messages[index], index);
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
          onTap: () => Get.toNamed(
            Routes.imageViewer,
            arguments: {
              'imageUrl': msg.imageUrl,
              'isLocalImage': msg.isLocalImage,
            },
          ),
        );
      case ChatMsgType.gift:
        return ChatGiftBubble(
          giftEmoji: msg.giftEmoji!,
          giftLabel: msg.giftLabel!,
          avatarUrl: _myAvatar,
        );
    }
  }

  Widget _buildBottomArea(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatInputBar(
              recordState: _recordState,
              showEmojiPicker: _showEmojiPicker,
              showIconBar: _showIconBar,
              colorScheme: colorScheme,
              textController: _textController,
              focusNode: _focusNode,
              onToggleVoiceMode: _toggleVoiceMode,
              onToggleEmoji: () => setState(() {
                if (_showEmojiPicker) {
                  _showEmojiPicker = false;
                  _showIconBar = false;
                } else {
                  _showEmojiPicker = true;
                  _showIconBar = false;
                  _focusNode.unfocus();
                }
                _recordState = ChatRecordState.idle;
              }),
              onToggleIconBar: () => setState(() {
                if (_showIconBar) {
                  _showIconBar = false;
                  _showEmojiPicker = false;
                } else {
                  _showIconBar = true;
                  _showEmojiPicker = false;
                  _focusNode.unfocus();
                }
                _recordState = ChatRecordState.idle;
              }),
              onScrollToBottom: () => _scrollToBottom(milliseconds: 280),
              onSendTextMessage: _sendTextMessage,
              onStartRecording: (_) => _startRecording(),
              onStopRecording: (_) => _stopRecording(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                ),
              ),
              child: _showEmojiPicker
                  ? EmojiPickerWidget(
                      key: const ValueKey('emoji'),
                      height: _expandedHeight,
                      onEmojiSelected: _sendEmojiMessage,
                    )
                  : (_showIconBar
                        ? ExpandedIconBar(
                            key: const ValueKey('icons'),
                            colorScheme: colorScheme,
                            height: _expandedHeight,
                            onImageTap: () {
                              _pickAndSendImage();
                              setState(() => _showIconBar = false);
                            },
                            onVideoCallTap: _startVideoCall,
                          )
                        : const SizedBox(key: ValueKey('empty'))),
            ),
          ],
        ),
      ),
    );
  }
}

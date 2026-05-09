import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_models.dart';

/// 聊天输入栏（语音/文字切换 + 输入框 + 表情/功能按钮）
class ChatInputBar extends StatelessWidget {
  final ChatRecordState recordState;
  final bool showEmojiPicker;
  final bool showIconBar;
  final ColorScheme colorScheme;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onToggleVoiceMode;
  final VoidCallback onToggleEmoji;
  final VoidCallback onToggleIconBar;
  final VoidCallback onScrollToBottom;
  final ValueChanged<String> onSendTextMessage;
  final GestureLongPressStartCallback onStartRecording;
  final GestureLongPressEndCallback onStopRecording;

  const ChatInputBar({
    super.key,
    required this.recordState,
    required this.showEmojiPicker,
    required this.showIconBar,
    required this.colorScheme,
    required this.textController,
    required this.focusNode,
    required this.onToggleVoiceMode,
    required this.onToggleEmoji,
    required this.onToggleIconBar,
    required this.onScrollToBottom,
    required this.onSendTextMessage,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final isVoiceMode = recordState != ChatRecordState.idle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.comfortable,
            onPressed: onToggleVoiceMode,
            icon: Icon(
              isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic_outlined,
              size: 26,
              color: colorScheme.inverseSurface,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: isVoiceMode
                ? _VoiceRecordBar(
                    colorScheme: colorScheme,
                    onStartRecording: onStartRecording,
                    onStopRecording: onStopRecording,
                  )
                : _ChatTextInputField(
                    colorScheme: colorScheme,
                    controller: textController,
                    focusNode: focusNode,
                    onSubmitted: onSendTextMessage,
                  ),
          ),
          const SizedBox(width: 2),
          if (!isVoiceMode && recordState == ChatRecordState.idle)
            IconButton(
              visualDensity: VisualDensity.comfortable,
              onPressed: () {
                HapticFeedback.lightImpact();
                onToggleEmoji();
                onScrollToBottom();
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  showEmojiPicker
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  key: ValueKey(showEmojiPicker),
                  size: 26,
                  color: showEmojiPicker
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
                onToggleIconBar();
                onScrollToBottom();
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  showIconBar
                      ? Icons.arrow_drop_down_circle
                      : Icons.add_circle_outline,
                  key: ValueKey(showIconBar),
                  size: 26,
                  color: showIconBar
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
}

/// 文字输入框
class _ChatTextInputField extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  const _ChatTextInputField({
    required this.colorScheme,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        decoration: InputDecoration(
          fillColor: colorScheme.outline,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          isDense: true,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// 长按录音条
class _VoiceRecordBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final GestureLongPressStartCallback onStartRecording;
  final GestureLongPressEndCallback onStopRecording;

  const _VoiceRecordBar({
    required this.colorScheme,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onStartRecording,
      onLongPressEnd: onStopRecording,
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
}

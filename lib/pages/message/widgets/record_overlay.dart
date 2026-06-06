import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/message/chat_voice_controller.dart';
import '../models/chat_models.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 录音 Overlay 浮层
// ──────────────────────────────────────────────────────────────────────────────

String _fmtDur(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// 录音浮层入口
class RecordOverlay extends StatelessWidget {
  final ChatRecordState recordState;
  final List<double> waveHeights;
  final int recordSeconds;
  final String? recordedPath;
  final VoidCallback onTogglePreviewPlay;
  final VoidCallback onCancelRecording;
  final VoidCallback onSendVoiceMessage;
  final ColorScheme colorScheme;

  const RecordOverlay({
    super.key,
    required this.recordState,
    required this.waveHeights,
    required this.recordSeconds,
    this.recordedPath,
    required this.onTogglePreviewPlay,
    required this.onCancelRecording,
    required this.onSendVoiceMessage,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: recordState == ChatRecordState.recording
            ? _RecordOverlayRecording(
                waveHeights: waveHeights,
                recordSeconds: recordSeconds,
                colorScheme: colorScheme,
              )
            : _RecordOverlayPreview(
                recordSeconds: recordSeconds,
                recordedPath: recordedPath,
                colorScheme: colorScheme,
                onTogglePreviewPlay: onTogglePreviewPlay,
                onCancelRecording: onCancelRecording,
                onSendVoiceMessage: onSendVoiceMessage,
              ),
      ),
    );
  }
}

/// 录音中
class _RecordOverlayRecording extends StatelessWidget {
  final List<double> waveHeights;
  final int recordSeconds;
  final ColorScheme colorScheme;

  const _RecordOverlayRecording({
    required this.waveHeights,
    required this.recordSeconds,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _PulsingMic(colorScheme: colorScheme),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: waveHeights
                      .map((h) => AnimatedContainer(
                            duration: const Duration(milliseconds: 80),
                            width: 4,
                            height: 8 + h * 28,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.5 + h * 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_fmtDur(recordSeconds),
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: colorScheme.onSurface,
                    letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('松手结束录音',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 录音预览
class _RecordOverlayPreview extends StatelessWidget {
  final int recordSeconds;
  final String? recordedPath;
  final ColorScheme colorScheme;
  final VoidCallback onTogglePreviewPlay;
  final VoidCallback onCancelRecording;
  final VoidCallback onSendVoiceMessage;

  const _RecordOverlayPreview({
    required this.recordSeconds,
    this.recordedPath,
    required this.colorScheme,
    required this.onTogglePreviewPlay,
    required this.onCancelRecording,
    required this.onSendVoiceMessage,
  });

  @override
  Widget build(BuildContext context) {
    final dur = recordSeconds.clamp(1, 60);
    final ctr = Get.find<ChatVoiceController>();

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('录音 ${_fmtDur(dur)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTogglePreviewPlay,
            child: Container(
              width: 56, height: 56,
              decoration:
                  BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
              child: Obx(
                () => ctr.isPlaying.value
                    ? Icon(Icons.pause, color: colorScheme.onPrimary, size: 28)
                    : Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onCancelRecording,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18,
                              color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text('取消',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onSendVoiceMessage,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
                          const SizedBox(width: 6),
                          Text('发送',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 脉冲麦克风动画
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim =
        Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacityAnim =
        Tween<double>(begin: 0.4, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, height: 80,
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
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: widget.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 64, height: 64,
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
}

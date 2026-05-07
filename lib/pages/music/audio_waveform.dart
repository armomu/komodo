import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 音频波形可视化组件
// 支持两种模式：
// 1. 模拟波形 - 基于播放状态和时间的平滑动画
// 2. 真实频率 - 接入系统 AudioVisualizer（需要录音权限）
// ══════════════════════════════════════════════════════════════════════════════

class AudioWaveform extends StatefulWidget {
  /// 波形条数量
  final int barCount;

  /// 波形条宽度
  final double barWidth;

  /// 波形条之间的间距
  final double barSpacing;

  /// 波形条圆角
  final double barRadius;

  /// 波形条颜色（低频）
  final Color lowColor;

  /// 波形条颜色（高频）
  final Color highColor;

  /// 最大跳动高度
  final double maxHeight;

  /// 波形宽度
  final double? width;

  /// 波形高度
  final double? height;

  /// 是否正在播放
  final bool isPlaying;

  /// 使用真实频率数据（需要录音权限）
  final bool useRealFrequency;

  const AudioWaveform({
    super.key,
    this.barCount = 32,
    this.barWidth = 4,
    this.barSpacing = 3,
    this.barRadius = 2,
    this.lowColor = Colors.cyanAccent,
    this.highColor = Colors.purpleAccent,
    this.maxHeight = 24,
    this.width,
    this.height,
    this.isPlaying = false,
    this.useRealFrequency = false,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _frequencyController;
  late Animation<double> _frequencyAnimation;
  final math.Random _random = math.Random();
  StreamSubscription? _visualizerSubscription;
  List<double> _realWaveData = [];

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();

    if (widget.useRealFrequency) {
      _initRealVisualizer();
    }
  }

  void _initAnimationControllers() {
    // 主波形动画控制器
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 频率变化动画控制器
    _frequencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _frequencyAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _frequencyController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  /// 初始化真实可视化数据（预留接口）
  ///
  /// 注意：Android 系统的 AudioVisualizer API 只能获取系统媒体应用的音频数据，
  /// 无法直接监听第三方播放器（如 just_audio）的输出。
  /// 如需实现真实频率可视化，可考虑：
  /// 1. 使用原生平台通道直接读取 AudioSession
  /// 2. 使用音频分析库（如 ffmpeg）解码音频文件
  /// 3. 使用 Oboe/OpenSL ES 等底层 API（仅 Android）
  Future<void> _initRealVisualizer() async {
    // 预留：目前使用模拟波形
    debugPrint('[AudioWaveform] 使用模拟波形（真实频率数据需要原生实现）');
  }

  void _startAnimations() {
    _waveController.repeat();
    _frequencyController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _waveController.stop();
    _frequencyController.stop();
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _frequencyController.dispose();
    _visualizerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.width ?? 200.0;

    return SizedBox(
      width: totalWidth,
      height: widget.maxHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _frequencyController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveformPainter(
              waveData: _realWaveData.isNotEmpty ? _realWaveData : null,
              barCount: widget.barCount,
              barWidth: widget.barWidth,
              barSpacing: widget.barSpacing,
              barRadius: widget.barRadius,
              lowColor: widget.lowColor,
              highColor: widget.highColor,
              maxHeight: widget.maxHeight,
              isPlaying: widget.isPlaying,
              waveProgress: _waveController.value,
              frequencyFactor: _frequencyAnimation.value,
              random: _random,
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 波形绘制器
// ══════════════════════════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final List<double>? waveData;
  final int barCount;
  final double barWidth;
  final double barSpacing;
  final double barRadius;
  final Color lowColor;
  final Color highColor;
  final double maxHeight;
  final bool isPlaying;
  final double waveProgress;
  final double frequencyFactor;
  final math.Random random;

  _WaveformPainter({
    this.waveData,
    required this.barCount,
    required this.barWidth,
    required this.barSpacing,
    required this.barRadius,
    required this.lowColor,
    required this.highColor,
    required this.maxHeight,
    required this.isPlaying,
    required this.waveProgress,
    required this.frequencyFactor,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    // 计算每个条形的宽度和位置
    final double totalBarWidth = barWidth + barSpacing;
    final double totalWidth = barCount * totalBarWidth - barSpacing;
    final double startX = (width - totalWidth) / 2;

    for (int i = 0; i < barCount; i++) {
      double barHeight;

      if (waveData != null && waveData!.isNotEmpty && isPlaying) {
        // 使用真实频率数据
        int dataIdx = (i * waveData!.length / barCount).floor();
        dataIdx = dataIdx.clamp(0, waveData!.length - 1);
        double magnitude = waveData![dataIdx].abs().clamp(0.0, 1.0);
        barHeight = magnitude * maxHeight * 0.9;
      } else if (isPlaying) {
        // 模拟波形：基于正弦波 + 随机扰动
        final phaseOffset = i * 0.15 + waveProgress * 2 * math.pi;
        final waveValue = math.sin(phaseOffset);
        final noise = (random.nextDouble() - 0.5) * 0.3;
        final normalizedValue = ((waveValue + 1) / 2 + noise).clamp(0.0, 1.0);
        barHeight = normalizedValue * maxHeight * frequencyFactor;
      } else {
        // 暂停状态：静态低高度
        final baseHeight = 0.15 + random.nextDouble() * 0.1;
        barHeight = maxHeight * baseHeight;
      }

      barHeight = barHeight.clamp(4.0, maxHeight);

      final double x = startX + i * totalBarWidth;
      final double y = (height - barHeight) / 2;

      // 颜色根据高度渐变（低频青色 -> 高频紫色）
      final magnitude = (barHeight / maxHeight).clamp(0.0, 1.0);
      paint.color = Color.lerp(lowColor, highColor, magnitude)!
          .withValues(alpha: 0.6 + magnitude * 0.4);

      // 绘制圆角矩形条
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(barRadius),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 简化版波形组件（推荐用于播放页面）
// ══════════════════════════════════════════════════════════════════════════════

class SimpleAudioWaveform extends StatefulWidget {
  /// 波形条数量
  final int barCount;

  /// 最大高度
  final double maxHeight;

  /// 基础颜色
  final Color color;

  /// 是否播放中
  final bool isPlaying;

  const SimpleAudioWaveform({
    super.key,
    this.barCount = 5,
    this.maxHeight = 24,
    this.color = Colors.white70,
    this.isPlaying = false,
  });

  @override
  State<SimpleAudioWaveform> createState() => _SimpleAudioWaveformState();
}

class _SimpleAudioWaveformState extends State<SimpleAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SimpleAudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            return _buildBar(index);
          }),
        );
      },
    );
  }

  Widget _buildBar(int index) {
    // 相位偏移，让每个条跳动节奏略有不同
    final phaseOffset = index * 0.2 + _random.nextDouble() * 0.15;
    final waveValue = math.sin((_controller.value * 2 * math.pi) + phaseOffset);
    final normalizedValue = (waveValue + 1) / 2; // 0-1

    // 根据波形值计算高度
    final barHeight = (widget.maxHeight * normalizedValue * 0.8)
        .clamp(4.0, widget.maxHeight);

    // 透明度随高度变化
    final opacity = 0.4 + (normalizedValue * 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 4,
      height: barHeight,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

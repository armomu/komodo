import 'dart:math' as math;
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 音频波形可视化组件
// 根据音调频率动态跳动的音频波形动画
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

  /// 波形条颜色
  final Color barColor;

  /// 最大跳动高度
  final double maxHeight;

  /// 当前音调频率 (0.0 - 1.0)，影响跳动幅度
  final double frequency;

  /// 是否正在播放
  final bool isPlaying;

  /// 宽度（自动计算或指定）
  final double? width;

  /// 高度（自动计算或指定）
  final double? height;

  const AudioWaveform({
    super.key,
    this.barCount = 5,
    this.barWidth = 4,
    this.barSpacing = 3,
    this.barRadius = 2,
    this.barColor = Colors.white70,
    this.maxHeight = 24,
    this.frequency = 0.5,
    this.isPlaying = false,
    this.width,
    this.height,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + _random.nextInt(200)),
      ),
    );

    _animations = List.generate(widget.barCount, (index) {
      // 每个条有不同的相位偏移和基础高度
      final baseHeight = 0.3 + _random.nextDouble() * 0.3;
      return Tween<double>(
        begin: baseHeight,
        end: 0.1 + _random.nextDouble() * 0.9,
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      );
    });

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
    }
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听播放状态变化
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }

    // 如果音调变化，更新动画目标
    if (widget.frequency != oldWidget.frequency) {
      _updateAnimationTargets();
    }
  }

  void _updateAnimationTargets() {
    for (int i = 0; i < _controllers.length; i++) {
      final baseHeight = 0.2 + _random.nextDouble() * 0.2;
      final maxAdd = widget.frequency * 0.6;
      _animations[i] = Tween<double>(
        begin: _animations[i].value,
        end: baseHeight + _random.nextDouble() * maxAdd,
      ).animate(
        CurvedAnimation(
          parent: _controllers[i],
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.width ??
        (widget.barCount * widget.barWidth +
            (widget.barCount - 1) * widget.barSpacing);
    final totalHeight = widget.height ?? widget.maxHeight;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return _buildBar(index, totalHeight);
        }),
      ),
    );
  }

  Widget _buildBar(int index, double maxHeight) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        // 根据动画值计算当前高度，考虑频率的影响
        final animValue = widget.isPlaying
            ? _animations[index].value
            : 0.2 + _random.nextDouble() * 0.1;
        final heightFactor = animValue * widget.frequency.clamp(0.3, 1.0);
        final barHeight = (maxHeight * heightFactor).clamp(4.0, maxHeight);

        return Container(
          width: widget.barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: widget.barColor,
            borderRadius: BorderRadius.circular(widget.barRadius),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 封装版本：与 MusicPlayerController 集成的波形组件
// ══════════════════════════════════════════════════════════════════════════════

class MusicWaveform extends StatefulWidget {
  /// 波形条数量
  final int barCount;

  /// 波形条颜色
  final Color barColor;

  /// 最大高度
  final double maxHeight;

  const MusicWaveform({
    super.key,
    this.barCount = 5,
    this.barColor = Colors.white70,
    this.maxHeight = 24,
  });

  @override
  State<MusicWaveform> createState() => _MusicWaveformState();
}

class _MusicWaveformState extends State<MusicWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final math.Random _random = math.Random();
  double _frequency = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void updateFrequency(double frequency) {
    setState(() {
      _frequency = frequency.clamp(0.3, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
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
    final phaseOffset = index * 0.15 + _random.nextDouble() * 0.1;
    final waveValue = math.sin((_animation.value * 2 * math.pi) + phaseOffset);
    final normalizedValue = (waveValue + 1) / 2; // 0-1

    // 根据频率和波形计算高度
    final heightFactor = normalizedValue * _frequency;
    final barHeight = (widget.maxHeight * heightFactor).clamp(4.0, widget.maxHeight);

    // 相邻条用不同透明度增加层次感
    final opacity = 0.5 + (normalizedValue * 0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 4,
      height: barHeight,
      decoration: BoxDecoration(
        color: widget.barColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

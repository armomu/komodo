import 'package:flutter/material.dart';

/// 飞行弹幕 Widget —— 每条独立管理动画，飞出屏幕即销毁
class FlyingDanmakuItem extends StatefulWidget {
  final String text;
  final Color color;
  final double topPercent;
  final VoidCallback onComplete;

  const FlyingDanmakuItem({
    required this.text,
    required this.color,
    required this.topPercent,
    required this.onComplete,
    super.key,
  });

  @override
  State<FlyingDanmakuItem> createState() => _FlyingDanmakuItemState();
}

class _FlyingDanmakuItemState extends State<FlyingDanmakuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final textWidth = _estimateTextWidth();
        final totalDistance = screenWidth + textWidth;
        final currentX = screenWidth - _ctrl.value * totalDistance;

        return Positioned(
          left: currentX,
          top: widget.topPercent * MediaQuery.of(context).size.height,
          child: _buildContent(),
        );
      },
    );
  }

  double _estimateTextWidth() {
    const charWidth = 14.0;
    return (widget.text.length * charWidth + 24).clamp(60, 300);
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 底部圆形操作按钮（礼物、购物车、分享等）
class BottomActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const BottomActionButton({
    super.key,
    required this.icon,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: color, size: 22)),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 标签徽章（如 SQ / MV / 视频）
class MusicTag extends StatelessWidget {
  final String label;

  const MusicTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white60,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

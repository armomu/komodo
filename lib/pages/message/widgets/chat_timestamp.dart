import 'package:flutter/material.dart';

/// 时间戳气泡
class ChatTimestamp extends StatelessWidget {
  final String time;

  const ChatTimestamp({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(time,
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

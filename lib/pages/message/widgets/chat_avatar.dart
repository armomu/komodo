import 'package:flutter/material.dart';

/// 聊天头像
class ChatAvatar extends StatelessWidget {
  final String url;
  final double radius;

  const ChatAvatar({
    super.key,
    required this.url,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url),
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
}

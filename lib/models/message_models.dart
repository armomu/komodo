import 'package:flutter/material.dart';

enum MessageType { system, private }

class MessageItem {
  final MessageType type;
  final String title;
  final String subtitle;
  final String time;
  final String? avatarUrl;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool showBadge;
  final int? unread;

  const MessageItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.avatarUrl,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.showBadge = false,
    this.unread,
  });
}

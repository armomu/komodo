import 'package:flutter/material.dart';

class CommentItem {
  final String username;
  final IconData avatar;
  final String content;
  final String time;
  final int likes;

  const CommentItem({
    required this.username,
    required this.avatar,
    required this.content,
    required this.time,
    required this.likes,
  });
}

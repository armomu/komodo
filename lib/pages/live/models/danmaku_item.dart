import 'package:flutter/material.dart';

/// 弹幕消息数据模型
class DanmakuItem {
  final String username;
  final String content;
  final Color color;

  const DanmakuItem(this.username, this.content, this.color);
}

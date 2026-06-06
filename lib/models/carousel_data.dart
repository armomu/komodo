import 'package:flutter/material.dart';

/// 轮播卡片数据
class CarouselCardData {
  final String imageUrl;
  final String tag;
  final int currentIndex;
  final int totalCount;
  final String tagSub;
  final String thumbnailUrl;
  final String duration;
  final String viewCount;
  final String title;
  final Color accentColor;
  final List<Color> stackColors;

  const CarouselCardData({
    required this.imageUrl,
    required this.tag,
    required this.currentIndex,
    required this.totalCount,
    required this.tagSub,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.title,
    required this.accentColor,
    required this.stackColors,
  });
}

/// 黑话歌词卡片数据
class SlangCardData {
  final String songName;
  final String artist;
  final String lyrics;
  final String avatarUrl;
  final String bgBlurUrl;
  final Color accentColor;

  const SlangCardData({
    required this.songName,
    required this.artist,
    required this.lyrics,
    required this.avatarUrl,
    required this.bgBlurUrl,
    required this.accentColor,
  });
}

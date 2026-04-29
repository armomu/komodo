import 'package:flutter/material.dart';

/// 播放列表数据模型（全局共享）
class PlaylistItem {
  final String id;
  final String title;
  final String artist;
  final String audioPath;
  final String lrcPath;
  final Color accentColor;

  const PlaylistItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioPath,
    required this.lrcPath,
    required this.accentColor,
  });
}

/// 歌词数据模型
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}

/// 本地播放列表（热歌榜）
const List<PlaylistItem> localPlaylist = [
  PlaylistItem(
    id: '1',
    title: 'Manta',
    artist: '刘柏辛Lexie',
    audioPath: 'sounds/Manta-刘柏辛.aac',
    lrcPath: 'sounds/Manta-刘柏辛.lrc',
    accentColor: Color(0xFF1A6BAF),
  ),
  PlaylistItem(
    id: '2',
    title: '离家出走',
    artist: '卫兰',
    audioPath: 'sounds/离家出走-卫兰.mp3',
    lrcPath: 'sounds/离家出走-卫兰.lrc',
    accentColor: Color(0xFF9B59B6),
  ),
];

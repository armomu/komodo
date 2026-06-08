import 'package:flutter/material.dart';

/// 播放列表数据模型（全局共享）
class PlaylistItem {
  final String id;
  final String title;
  final String artist;
  final String audioPath;
  final String lrcPath;
  final String avatarUrl;
  final Color accentColor;

  /// 网络歌曲下载到本地的缓存路径，null 表示尚未缓存
  String? cachedPath;

  PlaylistItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioPath,
    required this.lrcPath,
    required this.avatarUrl,
    required this.accentColor,
    this.cachedPath,
  });
}

/// 歌词数据模型
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({required this.timestamp, required this.text});
}

/// 本地播放列表（热歌榜）
final List<PlaylistItem> localPlaylist = [
  PlaylistItem(
    id: '1',
    title: 'Manta',
    artist: '刘柏辛Lexie',
    audioPath: 'sounds/Manta-刘柏辛.aac',
    lrcPath: 'sounds/Manta-刘柏辛.lrc',
    avatarUrl: 'https://picsum.photos/id/238/200/200',
    accentColor: const Color(0xFF1A6BAF),
  ),
  PlaylistItem(
    id: '2',
    title: '离家出走',
    artist: '卫兰',
    audioPath: 'sounds/离家出走-卫兰.mp3',
    lrcPath: 'sounds/离家出走-卫兰.lrc',
    avatarUrl: 'https://picsum.photos/id/239/200/200',
    accentColor: const Color(0xFF9B59B6),
  ),
  PlaylistItem(
    id: '3',
    title: 'SoundHelix',
    artist: 'Song',
    audioPath: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    lrcPath: '',
    avatarUrl: 'https://picsum.photos/id/241/200/200',
    accentColor: const Color.fromARGB(255, 0, 222, 177),
  ),
  PlaylistItem(
    id: '5',
    title: 'Horse',
    artist: '无名',
    audioPath: 'https://www.w3schools.com/html/horse.mp3',
    lrcPath: '',
    avatarUrl: 'https://picsum.photos/id/1/200/200',
    accentColor: const Color.fromARGB(255, 77, 255, 109),
  ),
];

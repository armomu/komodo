import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:komodo/pages/music/music_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 全局音乐播放器控制器
//
// 生命周期：在 main() 中 Get.put，全局单例，跨页面保持状态。
// 系统集成：使用 just_audio_background，自动显示系统通知栏/锁屏/控制中心
//           的媒体播放组件，并响应耳机按键/蓝牙设备控制。
// ══════════════════════════════════════════════════════════════════════════════

class MusicPlayerController extends GetxController {
  // 播放列表
  static const List<PlaylistItem> playlist = localPlaylist;

  // 播放器（just_audio_background 包装 just_audio，额外处理系统媒体通知）
  late final AudioPlayer _audioPlayer;

  // ── 可观察状态 ──────────────────────────────────────────────────────────────
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxList<LyricLine> lyrics = <LyricLine>[].obs;
  final RxInt currentLyricIndex = (-1).obs;
  final RxBool isLoading = false.obs;

  // 当前歌曲
  PlaylistItem? get currentTrack => playlist[currentIndex.value];

  // ── 生命周期 ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _loadCurrentTrack();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  // ── 内部初始化 ───────────────────────────────────────────────────────────────

  void _initAudioPlayer() {
    // 播放状态
    _audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

    // 播放位置
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
      _updateCurrentLyricIndex(pos);
    });

    // 总时长
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) duration.value = dur;
    });

    // 播放完成 → 自动下一首
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        nextTrack();
      }
    });
  }

  /// 构建系统媒体通知所需的 AudioSource
  ///
  /// just_audio_background 通过 [MediaItem] 传递给系统：
  ///   - 标题、艺术家显示在通知栏 / 锁屏 / 控制中心
  ///   - artUri 显示专辑封面（支持 http/https）
  AudioSource _buildAudioSource(PlaylistItem track) {
    final mediaItem = MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: Uri.parse(track.avatarUrl),
      album: 'Komodo Music',
    );

    final String src = track.audioPath;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return AudioSource.uri(Uri.parse(src), tag: mediaItem);
    } else {
      // asset 文件
      return AudioSource.asset(src, tag: mediaItem);
    }
  }

  Future<void> _loadCurrentTrack() async {
    isLoading.value = true;
    try {
      final source = _buildAudioSource(currentTrack);
      await _audioPlayer.setAudioSource(source);

      // 加载歌词
      if (currentTrack.lrcPath.isNotEmpty) {
        await _loadLyrics(currentTrack.lrcPath);
      } else {
        lyrics.value = [];
        currentLyricIndex.value = -1;
      }
    } catch (e) {
      debugPrint('[MusicPlayer] 加载音频失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLyrics(String lrcPath) async {
    try {
      final String content = await rootBundle.loadString(lrcPath);
      lyrics.value = _parseLrc(content);
      currentLyricIndex.value = -1;
    } catch (e) {
      debugPrint('[MusicPlayer] 加载歌词失败: $e');
      lyrics.value = [];
    }
  }

  List<LyricLine> _parseLrc(String content) {
    final List<LyricLine> result = [];
    final lines = LineSplitter.split(content);
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lines) {
      final matches = regex.allMatches(line);
      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!;
        final millis = millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          result.add(
            LyricLine(
              timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: millis,
              ),
              text: text,
            ),
          );
        }
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  void _updateCurrentLyricIndex(Duration pos) {
    if (lyrics.isEmpty) {
      currentLyricIndex.value = -1;
      return;
    }

    int index = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (lyrics[i].timestamp <= pos) {
        index = i;
      } else {
        break;
      }
    }

    if (index != currentLyricIndex.value) {
      currentLyricIndex.value = index;
    }
  }

  // ── 公开控制接口 ────────────────────────────────────────────────────────────

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlay() async {
    isPlaying.value ? await pause() : await play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> nextTrack() async {
    currentIndex.value = (currentIndex.value + 1) % playlist.length;
    await _loadCurrentTrack();
    await play();
  }

  Future<void> previousTrack() async {
    currentIndex.value =
        (currentIndex.value - 1 + playlist.length) % playlist.length;
    await _loadCurrentTrack();
    await play();
  }

  Future<void> selectTrack(int index) async {
    if (index == currentIndex.value) {
      // 已是当前曲，切换播放/暂停
      await togglePlay();
      return;
    }
    currentIndex.value = index;
    await _loadCurrentTrack();
    await play();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

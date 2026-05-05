import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komodo/pages/music/music_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 播放器控制器
// ══════════════════════════════════════════════════════════════════════════════

class MusicPlayerController extends GetxController {
  // 播放列表（使用全局定义的本地播放列表）
  static const List<PlaylistItem> playlist = localPlaylist;

  // 播放器
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 状态
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxList<LyricLine> lyrics = <LyricLine>[].obs;
  final RxInt currentLyricIndex = (-1).obs;
  final RxBool isLoading = false.obs;

  // 当前歌曲
  PlaylistItem get currentTrack => playlist[currentIndex.value];

  @override
  void onInit() {
    super.onInit();
    _initAudioPlayer();
    _loadCurrentTrack();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  void _initAudioPlayer() {
    // 监听播放状态
    _audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

    // 监听播放位置
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
      _updateCurrentLyricIndex(pos);
    });

    // 监听总时长
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });

    // 监听播放完成
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        nextTrack();
      }
    });
  }

  Future<void> _loadCurrentTrack() async {
    isLoading.value = true;
    try {
      // 加载音频
      await _audioPlayer.setAsset(currentTrack.audioPath);

      // 解析歌词
      await _loadLyrics(currentTrack.lrcPath);
    } catch (e) {
      debugPrint('加载音频失败: $e');
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
      debugPrint('加载歌词失败: $e');
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
        // 处理毫秒可能是2位或3位
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

    // 按时间排序
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

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> nextTrack() async {
    if (currentIndex.value < playlist.length - 1) {
      currentIndex.value++;
    } else {
      currentIndex.value = 0;
    }
    await _loadCurrentTrack();
    await play();
  }

  Future<void> previousTrack() async {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    } else {
      currentIndex.value = playlist.length - 1;
    }
    await _loadCurrentTrack();
    await play();
  }

  Future<void> selectTrack(int index) async {
    if (index == currentIndex.value) return;
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

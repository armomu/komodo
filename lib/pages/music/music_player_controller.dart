import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:komodo/pages/music/music_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 全局音乐播放器控制器
//
// 生命周期：在 main() 中 Get.put，全局单例，跨页面保持状态。
// 系统集成：使用 just_audio_background，自动显示系统通知栏/锁屏/控制中心
//           的媒体播放组件，并响应耳机按键/蓝牙设备控制。
//
// 关键设计：用 setAudioSources(完整列表) 一次性加载所有曲目。
//   just_audio_background 才能感知 hasNext/hasPrevious，
//   通知栏 compact view 才会显示上一首/下一首按钮。
// ═════════════════════════════════════════════════════════════════════════════

class MusicPlayerController extends GetxController {
  // 播放列表
  static const List<PlaylistItem> playlist = localPlaylist;

  // 播放器（just_audio_background 包装 just_audio，额外处理系统媒体通知）
  late final AudioPlayer _audioPlayer;

  /// 暴露 audioPlayer 供可视化组件获取 androidAudioSessionId
  AudioPlayer get audioPlayer => _audioPlayer;

  // ── 可观察状态 ──────────────────────────────────────────────────────
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  // 是否已播过歌：避免初始状态（currentIndex=0 且 isPlaying=false）被误认为「已暂停」
  final RxBool hasStartedPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxList<LyricLine> lyrics = <LyricLine>[].obs;
  final RxInt currentLyricIndex = (-1).obs;
  final RxBool isLoading = false.obs;

  // 当前歌曲
  PlaylistItem get currentTrack => playlist[currentIndex.value];

  // ── 生命周期 ────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _loadPlaylist();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  // ── 内部初始化 ─────────────────────────────────────────────────────────

  void loadCurrentLyricIndex() {
    if (_audioPlayer.playing == false && position.value != Duration.zero) {
      _updateCurrentLyricIndex(position.value);
    }
  }

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

    // 当前曲目索引变化（用户点通知栏上下首、或自动播完）
    _audioPlayer.currentIndexStream.listen((idx) {
      if (idx != null && idx != currentIndex.value) {
        currentIndex.value = idx;
        _loadLyricsForCurrentTrack();
      }
    });

    // 播放完成 → 循环到第一首
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero, index: 0);
      }
    });
  }

  /// 构建系统媒体通知所需的 AudioSource
  ///
  /// just_audio_background 通过 [MediaItem] 传递给系统：
  ///   - 标题、艺术家显示在通知栏 / 锁屏 / 控制中心
  ///   - artUri 显示专辑封面（支持 http/https）
  IndexedAudioSource _buildAudioSource(PlaylistItem track) {
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

  /// 一次性加载完整播放列表（只调用一次）
  ///
  /// 使用 setAudioSources 而非 setAudioSource，让 just_audio_background
  /// 能感知完整队列，从而在通知栏显示上/下一首按钮。
  Future<void> _loadPlaylist() async {
    isLoading.value = true;
    try {
      await _audioPlayer.setAudioSources(
        playlist.map(_buildAudioSource).toList(),
        initialIndex: currentIndex.value,
        initialPosition: Duration.zero,
      );
      await _loadLyricsForCurrentTrack();
    } catch (e) {
      debugPrint('[MusicPlayer] 加载播放列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLyricsForCurrentTrack() async {
    final lrcPath = currentTrack.lrcPath;
    if (lrcPath.isNotEmpty) {
      await _loadLyrics(lrcPath);
    } else {
      lyrics.value = [];
      currentLyricIndex.value = -1;
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
        // debugPrint('Lyric: ${lyrics[i].text}$pos 索引=======$i');
        index = i;
      } else {
        break;
      }
    }

    if (index != currentLyricIndex.value) {
      currentLyricIndex.value = index;
    }
  }

  // ── 公开控制接口 ────────────────────────────────────────────────────

  Future<void> play() async {
    hasStartedPlaying.value = true; // 标记已播过歌，UI 才能显示状态
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
    await _audioPlayer.seekToNext();
    await _audioPlayer.play();
  }

  Future<void> previousTrack() async {
    await _audioPlayer.seekToPrevious();
    await _audioPlayer.play();
  }

  /// 点击播放列表中某首曲目
  Future<void> selectTrack(int index) async {
    if (index == currentIndex.value) {
      // 已是当前曲，切换播放/暂停
      await togglePlay();
      return;
    }
    // seek 到指定索引，just_audio 会自动触发 currentIndexStream 更新歌词
    await _audioPlayer.seek(Duration.zero, index: index);
    await play();
  }

  // ── 语音消息播放（复用全局单例 AudioPlayer）─────────────────────────────
  // 状态
  final RxBool isPlayingVoice = false.obs;
  final Rx<String?> voiceFilePath = Rx<String?>(null);

  // 恢复音乐所需的上下文
  int? _savedIndex;
  Duration? _savedPosition;
  bool _wasPlaying = false;

  /// 播放语音文件（支持本地路径和网络 URL），播放完成后自动恢复音乐
  Future<void> playVoice(String filePath) async {
    try {
      // 1. 保存当前音乐播放状态
      _savedIndex = currentIndex.value;
      _savedPosition = position.value;
      _wasPlaying = isPlaying.value;

      // 2. 停止当前音乐
      await _audioPlayer.stop();

      // 3. 根据路径类型选择加载方式
      final isNetwork = filePath.startsWith('http://') || filePath.startsWith('https://');
      if (isNetwork) {
        // 网络 URL
        debugPrint('【VoicePlayer】加载网络音频: $filePath');
        await _audioPlayer.setUrl(filePath);
      } else {
        // 本地文件
        debugPrint('【VoicePlayer】加载本地音频: $filePath');
        await _audioPlayer.setFilePath(filePath);
      }
      voiceFilePath.value = filePath;
      isPlayingVoice.value = true;

      // 4. 播放
      await _audioPlayer.play();
      debugPrint('【VoicePlayer】开始: $filePath');

      // 5. 监听播放完成 → 恢复音乐
      _audioPlayer.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).then((_) async {
        if (!isPlayingVoice.value) return; // 已被外部停止
        debugPrint('【VoicePlayer】播放完成，恢复音乐');
        await _restoreMusic();
      });
    } catch (e) {
      debugPrint('【VoicePlayer】播放失败: $e');
      isPlayingVoice.value = false;
      voiceFilePath.value = null;
      await _restoreMusic();
    }
  }

  /// 停止语音播放
  Future<void> stopVoice() async {
    if (!isPlayingVoice.value) return;
    isPlayingVoice.value = false;
    voiceFilePath.value = null;
    await _audioPlayer.stop();
    debugPrint('【VoicePlayer】停止');
    await _restoreMusic();
  }

  Future<void> _restoreMusic() async {
    if (_savedIndex == null) return;
    final savedIdx = _savedIndex!;
    final savedPos = _savedPosition ?? Duration.zero;
    isPlayingVoice.value = false;
    voiceFilePath.value = null;
    _savedIndex = null;
    _savedPosition = null;

    try {
      // 重新加载播放列表
      await _audioPlayer.setAudioSources(
        playlist.map(_buildAudioSource).toList(),
        initialIndex: savedIdx,
        initialPosition: savedPos,
      );
      if (_wasPlaying) {
        await _audioPlayer.play();
        debugPrint('【VoicePlayer】音乐已恢复: index=$savedIdx');
      }
    } catch (e) {
      debugPrint('【VoicePlayer】恢复音乐失败: $e');
    }
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

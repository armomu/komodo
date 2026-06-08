import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:komodo/pages/music/music_cache_service.dart';
import 'package:komodo/pages/music/music_models.dart';
import 'package:permission_handler/permission_handler.dart';

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
//
// 启动优化：onInit 仅创建 AudioPlayer 和流监听，_loadPlaylist 延后到
//   首次 play() 时触发；JustAudioBackground 和通知权限在首帧后延迟请求。
// ═════════════════════════════════════════════════════════════════════════════

class MusicPlayerController extends GetxController {
  // 播放列表（可变，用于支持 cachedPath 更新）
  final List<PlaylistItem> playlist = List.of(localPlaylist);

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
  // 缓冲中：仅对网络歌曲在播放前需要加载数据时触发
  final RxBool isBuffering = false.obs;

  // 播放列表是否已加载（懒初始化标记）
  bool _playlistLoaded = false;

  // JustAudioBackground 是否已初始化
  static bool _backgroundInitDone = false;

  // 是否已扫描过所有网络歌曲的本地缓存
  bool _cacheChecked = false;

  /// 正在缓存中的歌曲 audioPath 集合，防止重复下载
  final Set<String> _cachingInProgress = {};

  // 当前歌曲
  PlaylistItem get currentTrack => playlist[currentIndex.value];

  // ── 生命周期 ────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    // 播放列表延后到首次 play() 时懒加载
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  // ── 内部初始化 ─────────────────────────────────────────────────────────

  /// Android 13+ 通知权限请求（静态方法，供 main.dart 首帧后调用）
  static Future<void> requestNotificationPermission() async {
    await Permission.notification.request();
  }

  /// 初始化 just_audio_background（静态方法，供首次 play 时懒调用）
  static Future<void> _ensureBackgroundInit() async {
    if (_backgroundInitDone) return;
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.komodo.music.channel.audio',
      androidNotificationChannelName: 'Komodo 音乐播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
    _backgroundInitDone = true;
  }

  /// 确保播放列表已加载（首次 play/selectTrack 时触发懒加载）
  Future<void> _ensurePlaylistLoaded() async {
    if (_playlistLoaded) return;
    _playlistLoaded = true;

    // 首次播放前完成 just_audio_background 初始化
    await _ensureBackgroundInit();

    // 扫描所有网络歌曲的本地缓存
    await _scanCachedPaths();

    isLoading.value = true;
    try {
      await _audioPlayer.setAudioSources(
        playlist.map(_buildAudioSource).toList(),
        initialIndex: currentIndex.value,
        initialPosition: Duration.zero,
      );
      await _loadLyricsForCurrentTrack();
    } catch (e) {
      _playlistLoaded = false; // 加载失败，允许重试
      debugPrint('[MusicPlayer] 加载播放列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 扫描所有网络歌曲是否有本地缓存，并填充 cachedPath
  Future<void> _scanCachedPaths() async {
    if (_cacheChecked) return;
    _cacheChecked = true;

    for (final track in playlist) {
      final path = track.audioPath;
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        continue;
      }
      try {
        final cached = await MusicCacheService.getCachedPath(path);
        if (cached != null) {
          track.cachedPath = cached;
          debugPrint('[MusicCache] 命中缓存: ${track.title} -> $cached');
        }
      } catch (e) {
        debugPrint('[MusicCache] 扫描缓存失败: $path, $e');
      }
    }
  }

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

    // 缓冲状态（网络歌曲需要加载时出现）
    _audioPlayer.processingStateStream.listen((state) {
      isBuffering.value = state == ProcessingState.buffering;
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
      // ── 优先使用本地缓存 ──────────────────────────────────────────
      if (track.cachedPath != null) {
        final cachedFile = File(track.cachedPath!);
        if (cachedFile.existsSync()) {
          debugPrint(
            '[MusicCache] 播放缓存: ${track.title} <- ${track.cachedPath}',
          );
          return AudioSource.uri(
            Uri.file(track.cachedPath!),
            tag: mediaItem,
          );
        } else {
          // 缓存文件已被删除，清除无效路径
          track.cachedPath = null;
        }
      }
      return AudioSource.uri(Uri.parse(src), tag: mediaItem);
    } else {
      // asset 文件
      return AudioSource.asset(src, tag: mediaItem);
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

  /// 如果当前歌曲是网络歌曲且尚未缓存，在后台下载缓存
  Future<void> _cacheCurrentTrackIfNeeded() async {
    final track = currentTrack;
    final path = track.audioPath;

    // 只处理网络歌曲
    if (!path.startsWith('http://') && !path.startsWith('https://')) {
      return;
    }
    // 已有缓存则跳过
    if (track.cachedPath != null) {
      final cachedFile = File(track.cachedPath!);
      if (cachedFile.existsSync()) return;
    }
    // 已在下载中则跳过，防止并发重复下载
    if (_cachingInProgress.contains(path)) {
      debugPrint('[MusicCache] 正在下载中，跳过: ${track.title}');
      return;
    }

    _cachingInProgress.add(path);
    try {
      debugPrint('[MusicCache] 开始后台缓存: ${track.title}');
      final cached = await MusicCacheService.cacheSong(path);
      track.cachedPath = cached;
      debugPrint('[MusicCache] 缓存完成: ${track.title} -> $cached');
    } catch (e) {
      debugPrint('[MusicCache] 缓存失败: ${track.title}, $e');
    } finally {
      _cachingInProgress.remove(path);
    }
  }

  // ── 公开控制接口 ────────────────────────────────────────────────────

  Future<void> play() async {
    await _ensurePlaylistLoaded(); // 懒加载：首次播放时才加载列表
    hasStartedPlaying.value = true; // 标记已播过歌，UI 才能显示状态
    await _audioPlayer.play();
    // 首次播放时后台缓存当前网络歌曲（后续切歌由 next/prev/select 触发）
    _cacheCurrentTrackIfNeeded();
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
    final nextIndex = (currentIndex.value + 1) % playlist.length;
    // 立即显示缓冲状态（网络歌曲需要加载时间）
    hasStartedPlaying.value = true;
    if (playlist[nextIndex].audioPath.startsWith('http')) {
      isBuffering.value = true;
    }
    await _audioPlayer.seekToNext();
    await _audioPlayer.play();
    // 后台缓存当前网络歌曲
    _cacheCurrentTrackIfNeeded();
  }

  Future<void> previousTrack() async {
    final prevIndex =
        (currentIndex.value - 1 + playlist.length) % playlist.length;
    // 立即显示缓冲状态（网络歌曲需要加载时间）
    hasStartedPlaying.value = true;
    if (playlist[prevIndex].audioPath.startsWith('http')) {
      isBuffering.value = true;
    }
    await _audioPlayer.seekToPrevious();
    await _audioPlayer.play();
    // 后台缓存当前网络歌曲
    _cacheCurrentTrackIfNeeded();
  }

  /// 点击播放列表中某首曲目
  Future<void> selectTrack(int index) async {
    // 立即显示 MiniPlayerBar，不等待列表加载或缓冲完成
    hasStartedPlaying.value = true;

    await _ensurePlaylistLoaded(); // 懒加载：首次切歌时才加载列表
    if (index == currentIndex.value) {
      // 已是当前曲，切换播放/暂停（不触发缓冲状态）
      await togglePlay();
      return;
    }
    // 切换到不同曲目：若是网络歌曲立即显示缓冲中
    if (playlist[index].audioPath.startsWith('http')) {
      isBuffering.value = true;
    }
    // seek 到指定索引，just_audio 会自动触发 currentIndexStream 更新歌词
    await _audioPlayer.seek(Duration.zero, index: index);
    await play();
    // 后台缓存当前网络歌曲
    _cacheCurrentTrackIfNeeded();
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
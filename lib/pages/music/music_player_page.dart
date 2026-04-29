import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

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

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 播放器控制器
// ══════════════════════════════════════════════════════════════════════════════

class MusicPlayerController extends GetxController {
  // 播放列表
  static const List<PlaylistItem> playlist = [
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

  // 播放器
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 状态
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> bufferedPosition = Duration.zero.obs;
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

    // 监听缓冲位置
    _audioPlayer.bufferedPositionStream.listen((buf) {
      bufferedPosition.value = buf;
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
          result.add(LyricLine(
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: millis,
            ),
            text: text,
          ));
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

// ══════════════════════════════════════════════════════════════════════════════
// 音乐播放器页面
// ══════════════════════════════════════════════════════════════════════════════

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  late final MusicPlayerController _controller;
  late final PageController _pageController;
  late final TabController _tabController;

  // 歌词滚动控制器
  final ScrollController _lyricsScrollController = ScrollController();
  final double _lyricLineHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MusicPlayerController());
    _pageController = PageController(initialPage: 0);
    _tabController = TabController(length: 2, vsync: this);

    // 监听歌词索引变化，自动滚动
    ever(_controller.currentLyricIndex, (index) {
      if (index >= 0 && _lyricsScrollController.hasClients) {
        _scrollToCurrentLyric(index);
      }
    });

    // Tab 和 PageView 同步
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    Get.delete<MusicPlayerController>();
    super.dispose();
  }

  void _scrollToCurrentLyric(int index) {
    final targetOffset = index * _lyricLineHeight -
        MediaQuery.of(context).size.height / 3 +
        _lyricLineHeight;

    _lyricsScrollController.animateTo(
      targetOffset.clamp(0, _lyricsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final track = _controller.currentTrack;
      const Color bgDark = Color(0xFF061524);
      const Color bgMid = Color(0xFF0D2338);

      return Scaffold(
        backgroundColor: bgDark,
        body: Stack(
          children: [
            // ── 背景渐变 ──
            _buildBackground(track.accentColor, bgDark, bgMid),

            // ── 主内容 ──
            SafeArea(
              child: Column(
                children: [
                  // ① 顶部导航栏
                  _buildTopBar(context),

                  // ② Tab 指示器
                  _buildTabIndicator(),

                  // ③ 可滑动内容区
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [
                        _buildSongTab(),
                        _buildLyricsTab(),
                      ],
                    ),
                  ),

                  // ④ 播放列表
                  _buildPlaylistBar(),

                  // ⑤ 进度条
                  _buildProgressBar(),

                  // ⑥ 播放控制区
                  _buildPlaybackControls(),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 加载指示器
            if (_controller.isLoading.value)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 背景
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBackground(Color accent, Color top, Color bottom) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.35),
              top,
              bottom,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 顶部导航栏
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 返回
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            color: Colors.white70,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // 歌曲信息（居中）
          Expanded(
            child: Obx(() {
              final track = _controller.currentTrack;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),

          // 分享
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_rounded, size: 22),
            color: Colors.white70,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tab 指示器
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTabIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 40),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: '歌曲'),
          Tab(text: '歌词'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 歌曲 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSongTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 歌曲信息
          _buildSongInfo(),
          const SizedBox(height: 32),

          // 功能按钮行
          _buildFunctionBar(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSongInfo() {
    return Obx(() {
      final track = _controller.currentTrack;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Expanded(
                child: Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
                color: Colors.white54,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 歌手
          Text(
            track.artist,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // 标签
          Wrap(
            spacing: 8,
            children: [
              _buildTag('SQ'),
              _buildTag('MV'),
              _buildTag('视频'),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white60,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 功能按钮行
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFunctionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFuncBtn(
          icon: Icons.graphic_eq,
          label: '音效',
        ),
        _buildFuncBtn(
          icon: Icons.tune,
          label: '定时',
        ),
        _buildFuncBtn(
          icon: Icons.download_for_offline_outlined,
          label: '下载',
        ),
        _buildFuncBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: '评论',
        ),
        _buildFuncBtn(
          icon: Icons.more_horiz,
          label: '更多',
        ),
      ],
    );
  }

  Widget _buildFuncBtn({
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 歌词 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLyricsTab() {
    return Obx(() {
      if (_controller.lyrics.isEmpty) {
        return const Center(
          child: Text(
            '暂无歌词',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        );
      }

      return ListView.builder(
        controller: _lyricsScrollController,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 3,
          horizontal: 32,
        ),
        itemCount: _controller.lyrics.length,
        itemBuilder: (context, index) {
          final line = _controller.lyrics[index];
          final isCurrent = index == _controller.currentLyricIndex.value;

          return GestureDetector(
            onTap: () => _controller.seek(line.timestamp),
            child: Container(
              height: _lyricLineHeight,
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isCurrent ? 17 : 14,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? Colors.white : Colors.white38,
                  height: 1.5,
                ),
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 播放列表栏
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaylistBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MusicPlayerController.playlist.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final track = MusicPlayerController.playlist[index];
          final isCurrent = index == _controller.currentIndex.value;

          return GestureDetector(
            onTap: () => _controller.selectTrack(index),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? track.accentColor.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
                    ? Border.all(
                        color: track.accentColor.withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCurrent ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? Colors.white70 : Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 进度条
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    return Obx(() {
      final duration = _controller.duration.value;
      final position = _controller.position.value;

      double progress = 0;
      if (duration.inMilliseconds > 0) {
        progress = position.inMilliseconds / duration.inMilliseconds;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          children: [
            // 进度滑块
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  final newPosition = Duration(
                    milliseconds: (v * duration.inMilliseconds).round(),
                  );
                  _controller.seek(newPosition);
                },
              ),
            ),

            // 时间显示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _controller.formatDuration(position),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  Text(
                    _controller.formatDuration(duration),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 播放控制区
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 播放模式
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.repeat_rounded),
            color: Colors.white54,
            iconSize: 22,
          ),

          // 上一首
          IconButton(
            onPressed: _controller.previousTrack,
            icon: const Icon(Icons.skip_previous_rounded),
            color: Colors.white,
            iconSize: 32,
          ),

          // 播放/暂停
          Obx(() => GestureDetector(
                onTap: _controller.togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    _controller.isPlaying.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              )),

          // 下一首
          IconButton(
            onPressed: _controller.nextTrack,
            icon: const Icon(Icons.skip_next_rounded),
            color: Colors.white,
            iconSize: 32,
          ),

          // 播放列表
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.queue_music_rounded),
            color: Colors.white54,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}

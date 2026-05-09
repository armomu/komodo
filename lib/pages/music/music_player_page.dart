import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_player_controller.dart';
import 'package:komodo/pages/music/playlist_bottom_sheet.dart';
import 'package:komodo/pages/music/vinyl_record_player.dart';
import 'package:komodo/pages/music/widgets/music_tab_bar.dart';
import 'package:komodo/pages/music/widgets/music_tag.dart';
import 'package:komodo/pages/music/widgets/music_function_button.dart';
import 'package:komodo/pages/music/widgets/music_progress_bar.dart';
import 'package:komodo/pages/music/widgets/music_playback_controls.dart';
import 'package:komodo/pages/music/widgets/full_lyrics_view.dart';
import 'package:komodo/pages/music/widgets/mini_lyrics_view.dart';

// 导出数据模型以便其他文件使用
export 'package:komodo/pages/music/music_models.dart';

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
  int _topTabIndex = 0; // 默认「精选」

  // 歌词滚动控制器
  final ScrollController _lyricsScrollController = ScrollController();
  final double _lyricLineHeight = 40.0;
  // Mini 歌词滚动控制器
  final ScrollController _miniLyricsScrollController = ScrollController();
  static const double _miniLyricLineHeight = 32.0;
  static const double _miniLyricVisibleHeight = 94.0;
  Worker? _lyricIndexWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MusicPlayerController>();
    _pageController = PageController(initialPage: 0);
    _tabController = TabController(length: 2, vsync: this);
    _controller.loadCurrentLyricIndex();
    // 监听歌词索引变化，自动滚动（歌词Tab + Mini歌词）
    _lyricIndexWorker = ever(_controller.currentLyricIndex, (index) {
      if (index >= 0) {
        if (_lyricsScrollController.hasClients) {
          _scrollToCurrentLyric(index);
        }
        if (_miniLyricsScrollController.hasClients) {
          _scrollMiniLyricToCenter(index);
        }
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
    _miniLyricsScrollController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _lyricIndexWorker?.dispose();
    super.dispose();
  }

  void _scrollToCurrentLyric(int index) {
    if (!_lyricsScrollController.hasClients) return;

    final paddingTop = MediaQuery.of(context).size.height / 3;
    final viewportHeight = _lyricsScrollController.position.viewportDimension;

    final targetOffset =
        paddingTop +
        index * _lyricLineHeight +
        _lyricLineHeight / 2 -
        viewportHeight / 2;

    _lyricsScrollController.animateTo(
      targetOffset.clamp(0, _lyricsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Mini歌词滚动：让当前行对齐到3行视口的中间行
  void _scrollMiniLyricToCenter(int index) {
    final controller = _miniLyricsScrollController;
    if (!controller.hasClients) return;

    const padLineHeight = _miniLyricLineHeight;
    final targetOffset =
        padLineHeight +
        index * _miniLyricLineHeight +
        _miniLyricLineHeight / 2 -
        _miniLyricVisibleHeight / 2;

    controller.animateTo(
      targetOffset.clamp(0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    _tabController.animateTo(index);
    setState(() => _topTabIndex = index);
  }

  /// 显示播放列表底部弹窗
  void _showPlaylistSheet() {
    PlaylistBottomSheet.show(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildTopBarWithTabs(),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [_buildSongTab(), _buildLyricsTab()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFunctionBar(),
                  const SizedBox(height: 8),
                  _buildProgressBar(),
                  _buildPlaybackControls(),
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
  // 顶部导航栏
  // ══════════════════════════════════════════════════════════════════════════

  AppBar _buildTopBarWithTabs() {
    return AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
        color: Colors.white70,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      title: MusicTabBar(
        currentIndex: _topTabIndex,
        onTabChanged: (index) {
          _tabController.animateTo(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
          color: Colors.white70,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 歌曲 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSongTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: _buildSongInfo(),
          ),
        );
      },
    );
  }

  Widget _buildSongInfo() {
    return Obx(() {
      final track = _controller.currentTrack;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              VinylRecordPlayer(
                size: MediaQuery.of(context).size.width * 0.50,
              ),
              const SizedBox(height: 24),
              // Mini 歌词展示
              MiniLyricsView(
                lyrics: _controller.lyrics,
                currentLyricIndex: _controller.currentLyricIndex.value,
                scrollController: _miniLyricsScrollController,
                lineHeight: _miniLyricLineHeight,
                visibleHeight: _miniLyricVisibleHeight,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          const Wrap(
            spacing: 8,
            children: [
              MusicTag(label: 'SQ'),
              MusicTag(label: 'MV'),
              MusicTag(label: '视频'),
            ],
          ),
        ],
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 歌词 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLyricsTab() {
    return FullLyricsView(
      lyrics: _controller.lyrics,
      currentLyricIndex: _controller.currentLyricIndex.value,
      scrollController: _lyricsScrollController,
      onSeek: _controller.seek,
      lineHeight: _lyricLineHeight,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 功能按钮行
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFunctionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          MusicFunctionButton(icon: Icons.graphic_eq, label: '音效'),
          MusicFunctionButton(icon: Icons.tune, label: '定时'),
          MusicFunctionButton(icon: Icons.download_for_offline_outlined, label: '下载'),
          MusicFunctionButton(icon: Icons.chat_bubble_outline_rounded, label: '评论'),
          MusicFunctionButton(icon: Icons.live_tv, label: '直播'),
          MusicFunctionButton(icon: Icons.more_vert, label: '更多'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 进度条
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    return Obx(
      () => MusicProgressBar(
        position: _controller.position.value,
        duration: _controller.duration.value,
        onSeek: _controller.seek,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 播放控制区
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaybackControls() {
    return Obx(
      () => MusicPlaybackControls(
        isPlaying: _controller.isPlaying.value,
        onTogglePlay: _controller.togglePlay,
        onPrevious: _controller.previousTrack,
        onNext: _controller.nextTrack,
        onPlaylist: _showPlaylistSheet,
      ),
    );
  }
}
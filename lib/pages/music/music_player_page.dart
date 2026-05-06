import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_player_controller.dart';
import 'package:komodo/pages/music/playlist_bottom_sheet.dart';

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
  Worker? _lyricIndexWorker;

  @override
  void initState() {
    super.initState();
    // 使用全局单例控制器，不再局部 put
    _controller = Get.find<MusicPlayerController>();
    _pageController = PageController(initialPage: 0);
    _tabController = TabController(length: 2, vsync: this);
    _controller.loadCurrentLyricIndex();
    // 监听歌词索引变化，自动滚动
    _lyricIndexWorker = ever(_controller.currentLyricIndex, (index) {
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
    _lyricIndexWorker?.dispose();
    // 全局控制器不在这里 delete，由 Get.put(permanent: true) 管理
    super.dispose();
  }

  void _scrollToCurrentLyric(int index) {
    if (!_lyricsScrollController.hasClients) return;

    // ListView 的 vertical padding（与 _buildLyricsTab 中保持一致）
    final paddingTop = MediaQuery.of(context).size.height / 3;
    final viewportHeight = _lyricsScrollController.position.viewportDimension;

    // 让当前高亮行的中心对准 viewport 的中心
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
        // ① 顶部导航栏（含Tab）
        appBar: _buildTopBarWithTabs(),
        body: Stack(
          children: [
            // ── 主内容 ──
            SafeArea(
              child: Column(
                children: [
                  // ② 可滑动内容区（歌曲/歌词）
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,

                      children: [_buildSongTab(), _buildLyricsTab()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 功能按钮行
                  _buildFunctionBar(),
                  const SizedBox(height: 8),
                  // ③ 进度条
                  _buildProgressBar(),

                  // ④ 播放控制区
                  _buildPlaybackControls(context),
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
  // 顶部导航栏（含Tab切换）
  // ══════════════════════════════════════════════════════════════════════════

  AppBar _buildTopBarWithTabs() {
    return AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: // 返回
      IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
        color: Colors.white70,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      title: _buildTabIndicator(),
      actions: [
        // 分享
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded),
          color: Colors.white70,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
      // child: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     // 第一行：返回 + 歌曲信息 + 分享
      //     Row(
      //       children: [

      //         // 第二行：Tab 指示器（歌曲/歌词）
      //         _buildTabIndicator(),

      //       ],
      //     ),
      //   ],
      // ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tab 指示器
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTabIndicator() {
    const titles = ['歌曲', '歌词'];
    return Expanded(
      // decoration: BoxDecoration(
      //   color: Colors.white.withValues(alpha: 0.1),
      //   borderRadius: BorderRadius.circular(20),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: titles.asMap().entries.map((e) {
          final active = e.key == _topTabIndex;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(
                e.key,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: active ? 16 : 15,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 20,
                    height: 2,
                    color: active ? Colors.white : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
              minHeight: constraints.maxHeight, // 使用父容器高度
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
          const Text('这里是播放动画'),
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
            children: [_buildTag('SQ'), _buildTag('MV'), _buildTag('视频')],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFuncBtn(icon: Icons.graphic_eq, label: '音效'),
          _buildFuncBtn(icon: Icons.tune, label: '定时'),
          _buildFuncBtn(icon: Icons.download_for_offline_outlined, label: '下载'),
          _buildFuncBtn(icon: Icons.chat_bubble_outline_rounded, label: '评论'),
          _buildFuncBtn(icon: Icons.live_tv, label: '直播'),
          _buildFuncBtn(icon: Icons.more_vert, label: '更多'),
        ],
      ),
    );
  }

  Widget _buildFuncBtn({
    required IconData icon,
    required String label,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
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
          // debugPrint(
          //   'line: ${line.timestamp}, $index==${_controller.currentLyricIndex.value}',
          // );
          return GestureDetector(
            onTap: () => _controller.seek(line.timestamp),
            child: Obx(() {
              final isCurrent = index == _controller.currentLyricIndex.value;
              return Container(
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
              );
            }),
          );
        },
      );
    });
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildPlaybackControls(BuildContext context) {
    final buttonSize = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: buttonSize > 0 ? buttonSize + 8 : 28,
      ),
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
          Obx(
            () => GestureDetector(
              onTap: _controller.togglePlay,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(color: Colors.white, width: 2),
                  color: Colors.white10,
                ),
                child: Icon(
                  _controller.isPlaying.value
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),

          // 下一首
          IconButton(
            onPressed: _controller.nextTrack,
            icon: const Icon(Icons.skip_next_rounded),
            color: Colors.white,
            iconSize: 32,
          ),

          // 播放列表 - 点击弹出底部弹窗
          IconButton(
            onPressed: _showPlaylistSheet,
            icon: const Icon(Icons.queue_music_rounded),
            color: Colors.white54,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}

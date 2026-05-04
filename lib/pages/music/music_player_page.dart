import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/music_player_controller.dart';

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
    final targetOffset =
        index * _lyricLineHeight -
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

  /// 显示播放列表底部弹窗
  void _showPlaylistSheet() {
    Get.bottomSheet(
      _PlaylistBottomSheet(controller: _controller),
      backgroundColor: const Color(0xFF0D2338),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: Stack(
          children: [
            // ── 主内容 ──
            SafeArea(
              child: Column(
                children: [
                  // ① 顶部导航栏（含Tab）
                  _buildTopBarWithTabs(context),

                  // ② 可滑动内容区（歌曲/歌词）
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: [_buildSongTab(), _buildLyricsTab()],
                    ),
                  ),
                  // 功能按钮行
                  _buildFunctionBar(),
                  const SizedBox(height: 16),
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

  Widget _buildTopBarWithTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：返回 + 歌曲信息 + 分享
          Row(
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

          const SizedBox(height: 8),

          // 第二行：Tab 指示器（歌曲/歌词）
          _buildTabIndicator(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tab 指示器
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTabIndicator() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
      child: _buildSongInfo(),
    );
  }

  Widget _buildSongInfo() {
    return Obx(() {
      final track = _controller.currentTrack;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // const Expanded(child: Text('Expanded')),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFuncBtn(icon: Icons.graphic_eq, label: '音效'),
          _buildFuncBtn(icon: Icons.tune, label: '定时'),
          _buildFuncBtn(icon: Icons.download_for_offline_outlined, label: '下载'),
          _buildFuncBtn(icon: Icons.chat_bubble_outline_rounded, label: '评论'),
          _buildFuncBtn(icon: Icons.more_horiz, label: '更多'),
        ],
      ),
    );
  }

  Widget _buildFuncBtn({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
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

  Widget _buildPlaybackControls(BuildContext context) {
    final buttonSize = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
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

// ══════════════════════════════════════════════════════════════════════════════
// 播放列表底部弹窗
// ══════════════════════════════════════════════════════════════════════════════

class _PlaylistBottomSheet extends StatelessWidget {
  final MusicPlayerController controller;

  const _PlaylistBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.queue_music, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
                const Text(
                  '播放列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    '${controller.currentIndex.value + 1}/${MusicPlayerController.playlist.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分割线
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.1)),

          // 播放列表
          Flexible(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: MusicPlayerController.playlist.length,
                itemBuilder: (context, index) {
                  final track = MusicPlayerController.playlist[index];
                  final isCurrent = index == controller.currentIndex.value;

                  return ListTile(
                    onTap: () {
                      controller.selectTrack(index);
                      Get.back();
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: track.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isCurrent
                            ? const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              )
                            : Icon(
                                Icons.music_note,
                                color: track.accentColor,
                                size: 20,
                              ),
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCurrent ? Colors.white : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent
                            ? Colors.white70
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: track.accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.equalizer,
                              color: Colors.white,
                              size: 14,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ),

          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

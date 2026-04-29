import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

class MusicTrack {
  final int rank;
  final String title;
  final String artist;
  final String coverUrl;
  final String duration;
  final int trendValue;
  final Color accentColor;

  const MusicTrack({
    required this.rank,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
    required this.trendValue,
    required this.accentColor,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 音乐播放器页面 — 仿QQ音乐深蓝沉浸风格
// ══════════════════════════════════════════════════════════════════════════════

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  // ── 播放状态 ──
  bool _isPlaying = false;
  double _progress = 0.14 / 4.35; // 00:14 / 04:21
  bool _isLiked = false;

  // ── Tab 索引（歌曲 / 歌词） ──
  int _tabIndex = 0;

  // ── 当前曲目 ──
  final MusicTrack _currentTrack = const MusicTrack(
    rank: 1,
    title: 'Letting Go (伤痛版)',
    artist: '徐且慢',
    coverUrl: 'https://picsum.photos/seed/qqmusic1/400/400',
    duration: '4:21',
    trendValue: 1,
    accentColor: Color(0xFF1A6BAF),
  );

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _prevTrack() {
    // 上一首逻辑
  }

  void _nextTrack() {
    // 下一首逻辑
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // 背景颜色来自当前曲目
    const Color bgDark = Color(0xFF061524);
    const Color bgMid = Color(0xFF0D2338);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // ── 背景渐变 ──
          _buildBackground(bgDark, bgMid),

          // ── 主内容 ──
          SafeArea(
            child: Column(
              children: [
                // ① 顶部导航栏
                _buildTopBar(context),

                // 内容区域（随 tab 切换）
                Expanded(
                  child: _tabIndex == 0
                      ? _buildSongTabContent()
                      : _buildLyricsTabContent(),
                ),

                // ⑤ 进度条
                _buildProgressBar(),

                // ⑥ 播放控制区
                _buildPlaybackControls(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 背景
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBackground(Color top, Color bottom) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _currentTrack.accentColor.withValues(alpha: 0.35),
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
  // ① 顶部导航栏
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context) {
    final tabs = ['歌曲', '歌词'];
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

          // Tab 切换
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final label = entry.value;
                final isSelected = _tabIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isSelected ? 15 : 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 20 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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
  // 歌曲 Tab — 歌曲信息 + 功能按钮
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSongTabContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 歌曲信息
          _buildSongInfo(),
          const SizedBox(height: 24),

          // 功能按钮行
          _buildFunctionBar(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ④ 歌曲信息区
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentTrack.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isLiked = !_isLiked),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? const Color(0xFFFF4D6D)
                            : Colors.white54,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.favorite_border,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '50w+',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _currentTrack.artist,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSmallTag('关注'),
                    const SizedBox(width: 6),
                    _buildSmallTag('3k人'),
                    const SizedBox(width: 6),
                    _buildSmallTag('标准'),
                    const SizedBox(width: 6),
                    _buildSmallTag('视频'),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'OP：TANGY MUSIC PUBLISHING',
                  style: TextStyle(fontSize: 11, color: Colors.white30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⑤ 功能按钮行
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFunctionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFuncBtn(
            icon: Icons.graphic_eq,
            label: '99+',
            badge: true,
          ),
          _buildFuncBtn(
            icon: Icons.tune,
            label: 'off',
          ),
          _buildFuncBtn(
            icon: Icons.download_for_offline_outlined,
            label: '下载',
          ),
          _buildFuncBtn(
            icon: Icons.chat_bubble_outline_rounded,
            label: '999+',
            badge: true,
          ),
          _buildFuncBtn(
            icon: Icons.more_horiz,
            label: '更多',
          ),
        ],
      ),
    );
  }

  Widget _buildFuncBtn({
    required IconData icon,
    required String label,
    bool badge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            if (badge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!badge)
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 歌词 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLyricsTabContent() {
    final lines = [
      '每次靠近你，我心跳加速',
      '你的笑容是我最美的风景',
      '',
      '★  letting go  ★',
      '',
      '放手让爱自由飞翔',
      '不再执着于过去的时光',
      'letting go, letting go...',
      '',
      '记忆里你的模样',
      '清晰却又如此遥远',
    ];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isHighlight = line.contains('★');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isHighlight ? 17 : 14,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
              color: isHighlight ? Colors.white : Colors.white54,
              height: 1.6,
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 进度条
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    final total = _parseDuration(_currentTrack.duration);
    final currentSecs = (_progress * total).round();
    final currentMin = currentSecs ~/ 60;
    final currentSec = currentSecs % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
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
              value: _progress.clamp(0.0, 1.0),
              onChanged: (v) => setState(() => _progress = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentMin.toString().padLeft(2, '0')}:${currentSec.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
                Text(
                  _currentTrack.duration,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _parseDuration(String d) {
    final parts = d.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ⑥ 播放控制区
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 循环
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.repeat_rounded),
            color: Colors.white54,
            iconSize: 22,
          ),
          // 上一首
          IconButton(
            onPressed: _prevTrack,
            icon: const Icon(Icons.skip_previous_rounded),
            color: Colors.white,
            iconSize: 32,
          ),
          // 播放/暂停
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.transparent,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          // 下一首
          IconButton(
            onPressed: _nextTrack,
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

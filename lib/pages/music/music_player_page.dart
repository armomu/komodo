import 'dart:math' as math;

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

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  // ── 播放状态 ──
  bool _isPlaying = false;
  double _progress = 0.14 / 4.35; // 00:14 / 04:21
  bool _isLiked = false;

  // ── Tab 索引（推荐 / 歌曲 / 歌词） ──
  int _tabIndex = 1;

  // ── 当前曲目索引 ──
  int _currentTrackIndex = 0;

  // ── 黑胶旋转动画 ──
  late AnimationController _vinylController;

  // ── 榜单数据 ──
  static const List<MusicTrack> _tracks = [
    MusicTrack(
      rank: 1,
      title: 'Letting Go (伤痛版)',
      artist: '徐且慢',
      coverUrl: 'https://picsum.photos/seed/qqmusic1/400/400',
      duration: '4:21',
      trendValue: 1,
      accentColor: Color(0xFF1A6BAF),
    ),
    MusicTrack(
      rank: 2,
      title: 'APT.',
      artist: 'Bruno Mars / 兔龙',
      coverUrl: 'https://picsum.photos/seed/qqmusic2/400/400',
      duration: '3:10',
      trendValue: 3,
      accentColor: Color(0xFF9B59B6),
    ),
    MusicTrack(
      rank: 3,
      title: 'HAPPY',
      artist: 'DAY6',
      coverUrl: 'https://picsum.photos/seed/qqmusic3/400/400',
      duration: '3:45',
      trendValue: 2,
      accentColor: Color(0xFFE67E22),
    ),
    MusicTrack(
      rank: 4,
      title: 'Die With A Smile',
      artist: 'Lady Gaga / Bruno Mars',
      coverUrl: 'https://picsum.photos/seed/qqmusic4/400/400',
      duration: '4:15',
      trendValue: 5,
      accentColor: Color(0xFFE74C3C),
    ),
    MusicTrack(
      rank: 5,
      title: 'Pink Venom',
      artist: 'BLACKPINK',
      coverUrl: 'https://picsum.photos/seed/qqmusic5/400/400',
      duration: '3:02',
      trendValue: 0,
      accentColor: Color(0xFFE91E8C),
    ),
    MusicTrack(
      rank: 6,
      title: 'Fortnight',
      artist: 'Taylor Swift',
      coverUrl: 'https://picsum.photos/seed/qqmusic6/400/400',
      duration: '3:49',
      trendValue: 4,
      accentColor: Color(0xFF3498DB),
    ),
    MusicTrack(
      rank: 7,
      title: 'Yes, And?',
      artist: 'Ariana Grande',
      coverUrl: 'https://picsum.photos/seed/qqmusic7/400/400',
      duration: '3:22',
      trendValue: 2,
      accentColor: Color(0xFFF39C12),
    ),
    MusicTrack(
      rank: 8,
      title: 'Espresso',
      artist: 'Sabrina Carpenter',
      coverUrl: 'https://picsum.photos/seed/qqmusic8/400/400',
      duration: '2:55',
      trendValue: 6,
      accentColor: Color(0xFF1ABC9C),
    ),
    MusicTrack(
      rank: 9,
      title: 'Beautiful Things',
      artist: 'Benson Boone',
      coverUrl: 'https://picsum.photos/seed/qqmusic9/400/400',
      duration: '3:32',
      trendValue: 1,
      accentColor: Color(0xFF2ECC71),
    ),
    MusicTrack(
      rank: 10,
      title: 'Narcissism',
      artist: 'SUNMI',
      coverUrl: 'https://picsum.photos/seed/qqmusic10/400/400',
      duration: '3:18',
      trendValue: 3,
      accentColor: Color(0xFFCCFF00),
    ),
  ];

  MusicTrack get _currentTrack => _tracks[_currentTrackIndex];

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _vinylController.repeat();
    } else {
      _vinylController.stop();
    }
  }

  void _selectTrack(int index) {
    setState(() {
      _currentTrackIndex = index;
      _progress = 0;
      _isPlaying = true;
    });
    _vinylController.repeat();
  }

  void _prevTrack() {
    _selectTrack(
      (_currentTrackIndex - 1 + _tracks.length) % _tracks.length,
    );
  }

  void _nextTrack() {
    _selectTrack((_currentTrackIndex + 1) % _tracks.length);
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
                  child: _tabIndex == 1
                      ? _buildSongTabContent()
                      : _tabIndex == 2
                      ? _buildLyricsTabContent()
                      : _buildRecommendTabContent(),
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
              _currentTrack.accentColor.withOpacity(0.35),
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
    final tabs = ['推荐', '歌曲', '歌词'];
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
  // 歌曲 Tab — 主视觉 + 歌曲信息 + 功能按钮 + 榜单列表
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSongTabContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ③ 主视觉区（3D黑胶唱机 + 封面）
          _buildMainVisual(),
          const SizedBox(height: 16),

          // ④ 歌曲信息
          _buildSongInfo(),
          const SizedBox(height: 12),

          // ⑤ 功能按钮行
          _buildFunctionBar(),
          const SizedBox(height: 16),

          // ── 榜单列表 ──
          _buildTrackList(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ③ 主视觉区 — 3D黑胶唱机 + 层叠封面卡 + 频谱
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMainVisual() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 频谱背景
          Positioned(
            left: 16,
            top: 20,
            bottom: 20,
            width: 88,
            child: _SpectrumWidget(color: _currentTrack.accentColor),
          ),

          // 后层专辑封面（专辑背景卡）
          Positioned(
            right: 24,
            top: 8,
            child: _buildAlbumCard(small: true),
          ),

          // 3D黑胶唱机（前景主角）
          Positioned(
            bottom: 0,
            child: _buildVinylDeck(),
          ),

          // 前景封面（叠在唱机上方）
          Positioned(
            right: 30,
            top: 16,
            child: _buildAlbumCard(small: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard({required bool small}) {
    final size = small ? 100.0 : 130.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: _currentTrack.accentColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _currentTrack.coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _currentTrack.accentColor.withOpacity(0.3),
              child: const Icon(Icons.music_note, color: Colors.white54),
            ),
          ),
          if (!small)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'QQ音乐 · 银河计划',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVinylDeck() {
    return AnimatedBuilder(
      animation: _vinylController,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 唱机底座
              Positioned(
                bottom: 0,
                child: Container(
                  width: 190,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A3060),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1A5090),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // 旋转黑胶
              Positioned(
                bottom: 8,
                child: Transform.rotate(
                  angle: _vinylController.value * 2 * math.pi,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF041230),
                      border: Border.all(
                        color: _currentTrack.accentColor.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 黑胶纹路
                        ...List.generate(4, (i) {
                          final r = 12.0 + i * 8.0;
                          return Container(
                            width: r * 2,
                            height: r * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                          );
                        }),
                        // 中心圆孔
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentTrack.accentColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 唱针臂
              Positioned(
                right: 20,
                top: 4,
                child: Transform.rotate(
                  angle: _isPlaying ? -0.3 : -0.5,
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF90C8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              // 唱针小圆球
              Positioned(
                right: 22,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFB0D8F8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
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
  // 榜单列表（热歌榜全部 10 首）
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTrackList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            '热歌榜 TOP 10',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ..._tracks.asMap().entries.map((entry) {
          final index = entry.key;
          final track = entry.value;
          final isActive = index == _currentTrackIndex;
          return _TrackListItem(
            track: track,
            isActive: isActive,
            onTap: () => _selectTrack(index),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 推荐 Tab
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRecommendTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 64,
            color: _currentTrack.accentColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            '为你推荐',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '根据你的听歌口味智能推荐',
            style: TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
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
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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

// ══════════════════════════════════════════════════════════════════════════════
// 榜单列表单项
// ══════════════════════════════════════════════════════════════════════════════

class _TrackListItem extends StatelessWidget {
  final MusicTrack track;
  final bool isActive;
  final VoidCallback onTap;

  const _TrackListItem({
    required this.track,
    required this.isActive,
    required this.onTap,
  });

  Color get _rankColor {
    switch (track.rank) {
      case 1:
        return const Color(0xFF32CD32);
      case 2:
        return const Color(0xFFFF9500);
      case 3:
        return const Color(0xFF9B59B6);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? track.accentColor.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: track.accentColor.withOpacity(0.35),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          children: [
            // 排名
            SizedBox(
              width: 28,
              child: isActive
                  ? Icon(
                      Icons.equalizer_rounded,
                      size: 18,
                      color: track.accentColor,
                    )
                  : Text(
                      '${track.rank}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _rankColor,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                track.coverUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  color: track.accentColor.withOpacity(0.3),
                  child: Icon(Icons.music_note, color: track.accentColor, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 趋势
            if (track.trendValue > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF32CD32).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Color(0xFF32CD32),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${track.trendValue}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF32CD32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(width: 40),

            // 时长
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                track.duration,
                style: const TextStyle(fontSize: 11, color: Colors.white30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 频谱动效组件
// ══════════════════════════════════════════════════════════════════════════════

class _SpectrumWidget extends StatefulWidget {
  final Color color;

  const _SpectrumWidget({required this.color});

  @override
  State<_SpectrumWidget> createState() => _SpectrumWidgetState();
}

class _SpectrumWidgetState extends State<_SpectrumWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.45, 0.75];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _SpectrumPainter(
            progress: _controller.value,
            baseHeights: _baseHeights,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final double progress;
  final List<double> baseHeights;
  final Color color;

  _SpectrumPainter({
    required this.progress,
    required this.baseHeights,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final barCount = baseHeights.length;
    final barWidth = size.width / (barCount * 2 - 1);

    for (int i = 0; i < barCount; i++) {
      final multiplier =
          baseHeights[i] + (math.sin(progress * math.pi * 2 + i * 0.8) * 0.2);
      final barHeight = size.height * multiplier.clamp(0.2, 1.0);
      final x = i * barWidth * 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) =>
      old.progress != progress || old.color != color;
}

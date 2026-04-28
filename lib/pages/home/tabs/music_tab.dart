import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:komodo/routes/app_routes.dart';

/// 发现页 — 深色主题，堆叠轮播卡片设计（基于 card_swiper）
class MusicTab extends StatefulWidget {
  const MusicTab({super.key});

  @override
  State<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<MusicTab> {
  /// Swiper 控制器
  final SwiperController _swiperController = SwiperController();

  // ════════════════════════════════════════════════════════════════════════
  // 模拟数据 — 正方形专辑封面图
  // ════════════════════════════════════════════════════════════════════════

  static const List<_CarouselCardData> _carouselCards = [
    _CarouselCardData(
      imageUrl: 'https://picsum.photos/seed/mv1/600/600',
      tag: 'MV',
      currentIndex: 1,
      totalCount: 10,
      tagSub: '抢先看',
      thumbnailUrl: 'https://picsum.photos/seed/mv1thumb/200/200',
      duration: '00:10',
      viewCount: '284.7万',
      title: 'SUNMI · Narcissism',
      accentColor: Color(0xFFCCFF00),
      stackColors: [Color(0xFF9B59B6), Color(0xFFCCFF00), Color(0xFFE74C3C)],
    ),
    _CarouselCardData(
      imageUrl: 'https://picsum.photos/seed/mv2/600/600',
      tag: 'MV',
      currentIndex: 2,
      totalCount: 10,
      tagSub: '新上线',
      thumbnailUrl: 'https://picsum.photos/seed/mv2thumb/200/200',
      duration: '03:45',
      viewCount: '156.2万',
      title: 'BLACKPINK · Pink Venom',
      accentColor: Color(0xFF9B59B6),
      stackColors: [Color(0xFF3498DB), Color(0xFF9B59B6), Color(0xFFF39C12)],
    ),
    _CarouselCardData(
      imageUrl: 'https://picsum.photos/seed/mv3/600/600',
      tag: 'MV',
      currentIndex: 3,
      totalCount: 10,
      tagSub: '独家',
      thumbnailUrl: 'https://picsum.photos/seed/mv3thumb/200/200',
      duration: '04:20',
      viewCount: '98.5万',
      title: 'Bruno Mars · Die With A Smile',
      accentColor: Color(0xFFE74C3C),
      stackColors: [Color(0xFFCCFF00), Color(0xFFE74C3C), Color(0xFF2ECC71)],
    ),
    _CarouselCardData(
      imageUrl: 'https://picsum.photos/seed/mv4/600/600',
      tag: 'MV',
      currentIndex: 4,
      totalCount: 10,
      tagSub: '热播中',
      thumbnailUrl: 'https://picsum.photos/seed/mv4thumb/200/200',
      duration: '03:12',
      viewCount: '320.8万',
      title: 'Taylor Swift · Fortnight',
      accentColor: Color(0xFF3498DB),
      stackColors: [Color(0xFFE74C3C), Color(0xFF3498DB), Color(0xFF9B59B6)],
    ),
    _CarouselCardData(
      imageUrl: 'https://picsum.photos/seed/mv5/600/600',
      tag: 'MV',
      currentIndex: 5,
      totalCount: 10,
      tagSub: '推荐',
      thumbnailUrl: 'https://picsum.photos/seed/mv5thumb/200/200',
      duration: '02:58',
      viewCount: '67.3万',
      title: 'Ariana Grande · Yes, And?',
      accentColor: Color(0xFFF39C12),
      stackColors: [Color(0xFF9B59B6), Color(0xFFF39C12), Color(0xFFCCFF00)],
    ),
  ];

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool _) {
        return <Widget>[
          SliverAppBar(
            // backgroundColor: Colors.black,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            backgroundColor: Theme.of(context).colorScheme.surface,
            expandedHeight: 80,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KOMODO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.toNamed(Routes.live);
                    },
                    icon: Icon(
                      Icons.live_tv,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              titlePadding: const EdgeInsets.fromLTRB(16, 16, 3, 0),
            ),
          ),
        ];
      },
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          // ========== ② 堆叠轮播卡片（card_swiper） ==========
          _buildCarouselCards(context),
          const SizedBox(height: 20),
          // ========== ③ 音乐歌词卡片（新UI设计） ==========
          _buildMusicLyricsCard(context),
          const SizedBox(height: 20),
          // ========== ④ 音乐排行榜（Top榜单） ==========
          _buildMusicRankingCard(context),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ② 堆叠轮播卡片 — 基于 card_swiper 的自定义堆叠动画
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildCarouselCards(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width;
    final double itemHeight = itemWidth * 0.60;
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        return _MainCardContent(data: _carouselCards[index]);
        // return _MainCardContent(data: _carouselCards[index]);
      },
      axisDirection: AxisDirection.right,
      itemWidth: itemWidth - 32,
      itemHeight: itemHeight,
      layout: SwiperLayout.STACK,
      controller: _swiperController,
      itemCount: _carouselCards.length,
    );
  }
  // ════════════════════════════════════════════════════════════════════════
  // ③ 音乐歌词卡片 — 黑色主题卡片设计，可左右滑动，两侧露出相邻卡片
  // ════════════════════════════════════════════════════════════════════════

  static const List<_SlangCardData> _slangCards = [
    _SlangCardData(
      songName: 'Narcissism',
      artist: 'SUNMI(이선미)',
      lyrics: '当愚昧成为主流，清醒就是犯罪。',
      avatarUrl: 'https://picsum.photos/id/237/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music/72/72',
      accentColor: Color(0xFF32CD32),
    ),
    _SlangCardData(
      songName: 'Pink Venom',
      artist: 'BLACKPINK',
      lyrics: 'This that pink venom, get \'em get \'em get \'em',
      avatarUrl: 'https://picsum.photos/id/238/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music2/72/72',
      accentColor: Color.fromARGB(255, 30, 176, 50),
    ),
    _SlangCardData(
      songName: 'Die With A Smile',
      artist: 'Bruno Mars',
      lyrics: 'If the world was ending, I\'d wanna be next to you.',
      avatarUrl: 'https://picsum.photos/id/239/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music3/72/72',
      accentColor: Color(0xFFE74C3C),
    ),
    _SlangCardData(
      songName: 'Fortnight',
      artist: 'Taylor Swift',
      lyrics: 'And for a fortnight there, we were forever.',
      avatarUrl: 'https://picsum.photos/id/240/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music4/72/72',
      accentColor: Color(0xFF3498DB),
    ),
    _SlangCardData(
      songName: 'Yes, And?',
      artist: 'Ariana Grande',
      lyrics: 'Say that shit with your chest, and be your own fan.',
      avatarUrl: 'https://picsum.photos/id/241/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music5/72/72',
      accentColor: Color(0xFFF39C12),
    ),
  ];

  Widget _buildMusicLyricsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题区域
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '黑话 Slang',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          _buildMusicSlangCard(context),
        ],
      ),
    );
  }

  Widget _buildMusicSlangCard(BuildContext context) {
    // viewportFraction < 1.0 让左右两侧露出相邻卡片边缘
    const double viewportFraction = 0.92;
    const double cardHorizontalMargin = 6.0; // 卡片之间视觉间距
    return SizedBox(
      height: 120,
      child: PageView.builder(
        itemCount: _slangCards.length,
        padEnds: false, // 关键：让第一页和最后一页也能贴边，两侧露出
        controller: PageController(
          viewportFraction: viewportFraction,
          initialPage: 0,
        ),
        itemBuilder: (context, index) {
          final data = _slangCards[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: cardHorizontalMargin,
            ),
            child: _SlangCardItem(data: data),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ④ 音乐排行榜 — Top 1/2/3 排名卡片
  // ════════════════════════════════════════════════════════════════════════

  static const List<_RankingCardData> _rankingCards = [
    _RankingCardData(
      rank: 1,
      songName: 'APT.',
      artist: 'Bruno Mars / 兔龙',
      coverUrl: 'https://picsum.photos/seed/rank1/200/200',
      trendValue: 1,
    ),
    _RankingCardData(
      rank: 2,
      songName: 'HAPPY',
      artist: 'DAY6',
      coverUrl: 'https://picsum.photos/seed/rank2/200/200',
      trendValue: 3,
    ),
    _RankingCardData(
      rank: 3,
      songName: 'APT.',
      artist: 'Rosé',
      coverUrl: 'https://picsum.photos/seed/rank3/200/200',
      trendValue: 2,
    ),
  ];

  Widget _buildMusicRankingCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题区域
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '热歌榜 TOP',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          // margin: const EdgeInsets.all(0),
          borderOnForeground: true,
          child: Column(
            children: _rankingCards.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final isLast = index == _rankingCards.length - 1;
              return _RankingListItem(data: data, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 主卡片内容 — 图片 + 标签 + 底部信息
// ══════════════════════════════════════════════════════════════════════════════

class _MainCardContent extends StatelessWidget {
  final _CarouselCardData data;

  const _MainCardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // border: Border.all(color: Colors.blue, width: 1),
        color: data.accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ====== 封面图（正方形 BoxFit.cover） ======
          Image.network(
            data.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A2E),
              child: const Icon(
                Icons.music_video,
                size: 56,
                color: Colors.white12,
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF1A1A2E),
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: data.accentColor,
                  ),
                ),
              );
            },
          ),

          // ====== 底部渐变遮罩 ======
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),

          // ====== 左上角荧光标签 ======
          Positioned(left: 13, top: 13, child: _buildTag()),

          // ====== 底部信息栏 ======
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomInfo()),
        ],
      ),
    );
  }

  /// 左上角标签
  Widget _buildTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.tag,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${data.currentIndex}/${data.totalCount}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Text(
            data.tagSub,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// 底部信息区
  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 分割线
          Container(height: 0.7, color: Colors.white30),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildThumbnail(),
              const SizedBox(width: 11),
              Expanded(child: _buildTextInfo()),
            ],
          ),
        ],
      ),
    );
  }

  /// 缩略图 + 播放按钮 + 时长
  Widget _buildThumbnail() {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              data.thumbnailUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[850]),
            ),
          ),
          // 播放遮罩
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black38,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          // 时长标签
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                data.duration,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 文字信息
  Widget _buildTextInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${data.viewCount}人看过',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          data.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════════
// Slang 卡片单项 — 保持原有视觉风格
// ══════════════════════════════════════════════════════════════════════════════

class _SlangCardItem extends StatelessWidget {
  final _SlangCardData data;

  const _SlangCardItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      child: Stack(
        children: [
          Row(
            children: [
              // 音乐图标
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              // 歌曲信息
              Text(
                data.songName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '- ${data.artist}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          // 歌词展示区域
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 34),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图片（带高斯模糊）
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Image.network(
                      data.bgBlurUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF1A1A2E)),
                    ),
                  ),
                  // 遮罩提升可读性
                  Container(color: Colors.black.withOpacity(0.3)),
                  // 前景歌词内容
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            data.lyrics,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.songName} · ${data.artist}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右侧头像
          Positioned(
            right: 10,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(width: 2, color: Colors.white),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: data.accentColor,
                backgroundImage: NetworkImage(data.avatarUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════════

class _SlangCardData {
  final String songName;
  final String artist;
  final String lyrics;
  final String avatarUrl;
  final String bgBlurUrl;
  final Color accentColor;

  const _SlangCardData({
    required this.songName,
    required this.artist,
    required this.lyrics,
    required this.avatarUrl,
    required this.bgBlurUrl,
    required this.accentColor,
  });
}

class _CarouselCardData {
  final String imageUrl;
  final String tag;
  final int currentIndex;
  final int totalCount;
  final String tagSub;
  final String thumbnailUrl;
  final String duration;
  final String viewCount;
  final String title;
  final Color accentColor;
  final List<Color> stackColors; // 堆叠层的颜色

  const _CarouselCardData({
    required this.imageUrl,
    required this.tag,
    required this.currentIndex,
    required this.totalCount,
    required this.tagSub,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewCount,
    required this.title,
    required this.accentColor,
    required this.stackColors,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 排行榜数据模型 & 单项组件
// ══════════════════════════════════════════════════════════════════════════════

class _RankingCardData {
  final int rank;
  final String songName;
  final String artist;
  final String coverUrl;
  final int trendValue;

  const _RankingCardData({
    required this.rank,
    required this.songName,
    required this.artist,
    required this.coverUrl,
    required this.trendValue,
  });
}

class _RankingListItem extends StatelessWidget {
  final _RankingCardData data;
  final bool isLast;

  const _RankingListItem({required this.data, required this.isLast});

  /// 获取排名对应的颜色
  Color get _rankColor {
    switch (data.rank) {
      case 1:
        return const Color(0xFF32CD32); // 绿色
      case 2:
        return const Color(0xFFFF9500); // 橙色
      case 3:
        return const Color(0xFF9B59B6); // 紫色
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 排名标签
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${data.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _rankColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 圆形封面
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _rankColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.network(
                data.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: Icon(Icons.music_note, color: _rankColor, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 歌曲信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.songName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    // color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.artist,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 排名趋势
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF32CD32).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 14,
                  color: Color(0xFF32CD32),
                ),
                const SizedBox(width: 2),
                Text(
                  '${data.trendValue}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF32CD32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';

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
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            // backgroundColor: Colors.black,
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
                    onPressed: () {},
                    icon: Icon(
                      Icons.all_inclusive,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              titlePadding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
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
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ② 堆叠轮播卡片 — 基于 card_swiper 的自定义堆叠动画
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildCarouselCards(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width;
    final double itemHeight = itemWidth * 0.5625;
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
  // ③ 音乐歌词卡片 — 黑色主题卡片设计
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMusicLyricsCard(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width;
    final double itemHeight = itemWidth * 0.5625;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区域
          const Text(
            '黑话经典',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Row(
                children: [
                  // 音乐图标
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32CD32), // 绿色
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
                  const Text(
                    'Narcissism',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    '- SUNMI(이선미)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                  ),

                  // 圆形头像
                ],
              ),
              // 歌词展示区域
              Container(
                height: 60,
                margin: const EdgeInsets.only(top: 34),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
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
                          'https://picsum.photos/seed/music/72/72',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // 可选：加一层遮罩提升可读性
                      Container(color: Colors.black.withOpacity(0.3)),
                      // 其他前景内容放这里
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '当愚昧成为主流，清醒就是犯罪。',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Narcissism · SUNMI',
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

              Positioned(
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 26, // 半径（不是直径）
                    // 如果图片加载失败，可显示占位背景
                    backgroundColor: Color(0xFF32CD32),
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/seed/user/60/60',
                    ), // 可选：fallback 图标
                  ),
                ),
              ),
            ],
          ),

          // 歌曲信息行
        ],
      ),
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

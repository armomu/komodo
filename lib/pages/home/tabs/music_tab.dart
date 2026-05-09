import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:komodo/pages/music/music_player_controller.dart';
import 'package:komodo/pages/music/music_models.dart';
import 'package:komodo/pages/test/test.dart';
import 'models/carousel_data.dart';
import 'widgets/main_card_content.dart';
import 'widgets/slang_card_item.dart';
import 'widgets/local_ranking_item.dart';

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

  static const List<CarouselCardData> _carouselCards = [
    CarouselCardData(
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
    CarouselCardData(
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
    CarouselCardData(
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
    CarouselCardData(
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
    CarouselCardData(
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

  static const List<SlangCardData> _slangCards = [
    SlangCardData(
      songName: 'Narcissism',
      artist: 'SUNMI(이선미)',
      lyrics: '当愚昧成为主流，清醒就是犯罪。',
      avatarUrl: 'https://picsum.photos/id/237/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music/72/72',
      accentColor: Color(0xFF32CD32),
    ),
    SlangCardData(
      songName: 'Pink Venom',
      artist: 'BLACKPINK',
      lyrics: 'This that pink venom, get \'em get \'em get \'em',
      avatarUrl: 'https://picsum.photos/id/238/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music2/72/72',
      accentColor: Color.fromARGB(255, 30, 176, 50),
    ),
    SlangCardData(
      songName: 'Die With A Smile',
      artist: 'Bruno Mars',
      lyrics: 'If the world was ending, I\'d wanna be next to you.',
      avatarUrl: 'https://picsum.photos/id/239/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music3/72/72',
      accentColor: Color(0xFFE74C3C),
    ),
    SlangCardData(
      songName: 'Fortnight',
      artist: 'Taylor Swift',
      lyrics: 'And for a fortnight there, we were forever.',
      avatarUrl: 'https://picsum.photos/id/240/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music4/72/72',
      accentColor: Color(0xFF3498DB),
    ),
    SlangCardData(
      songName: 'Yes, And?',
      artist: 'Ariana Grande',
      lyrics: 'Say that shit with your chest, and be your own fan.',
      avatarUrl: 'https://picsum.photos/id/241/200/200',
      bgBlurUrl: 'https://picsum.photos/seed/music5/72/72',
      accentColor: Color(0xFFF39C12),
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
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            backgroundColor: Theme.of(context).colorScheme.surface,
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: GestureDetector(
                onTap: () => Get.to(const TestPage()),
                child: const Text(
                  'Komodo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 3, 12),
            ),
          ),
        ];
      },
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          _buildCarouselCards(context),
          const SizedBox(height: 20),
          _buildMusicLyricsCard(context),
          const SizedBox(height: 20),
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
        return MainCardContent(data: _carouselCards[index]);
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

  Widget _buildMusicLyricsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
    const double viewportFraction = 0.92;
    const double cardHorizontalMargin = 6.0;
    return SizedBox(
      height: 120,
      child: PageView.builder(
        itemCount: _slangCards.length,
        padEnds: false,
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
            child: SlangCardItem(data: data),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ④ 音乐排行榜 — 本地热歌榜
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMusicRankingCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '热歌榜 TOP',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Card(
            borderOnForeground: true,
            child: Column(
              children: localPlaylist.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final isLast = index == localPlaylist.length - 1;
                return LocalRankingItem(
                  data: data,
                  rank: index + 1,
                  isLast: isLast,
                  onTap: () {
                    Get.find<MusicPlayerController>().selectTrack(index);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

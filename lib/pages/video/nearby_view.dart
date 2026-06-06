import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// ════════════════════════════════════════════════════════════════════════
// 数据模型
// ════════════════════════════════════════════════════════════════════════

class NearbyPost {
  final String title;
  final String subtitle;
  final String coverUrl;

  const NearbyPost({
    required this.title,
    required this.subtitle,
    required this.coverUrl,
  });
}

// 同城模拟图文数据
final List<NearbyPost> nearbyPosts = [
  const NearbyPost(
    title: '街头美食探店',
    subtitle: '@吃货小王 · 2.3km',
    coverUrl: 'https://picsum.photos/seed/food1/400/300',
  ),
  const NearbyPost(
    title: '城市夜景摄影',
    subtitle: '@摄影师老李 · 1.8km',
    coverUrl: 'https://picsum.photos/seed/night1/400/500',
  ),
  const NearbyPost(
    title: '周末骑行记录',
    subtitle: '@骑行侠 · 5.1km',
    coverUrl: 'https://picsum.photos/seed/bike1/400/350',
  ),
  const NearbyPost(
    title: '公园跑步日常',
    subtitle: '@运动达人 · 0.8km',
    coverUrl: 'https://picsum.photos/seed/run1/400/450',
  ),
  const NearbyPost(
    title: '手工咖啡分享',
    subtitle: '@咖啡控 · 3.2km',
    coverUrl: 'https://picsum.photos/seed/coffee1/400/380',
  ),
  const NearbyPost(
    title: '萌宠日常',
    subtitle: '@铲屎官 · 1.5km',
    coverUrl: 'https://picsum.photos/seed/pet1/400/420',
  ),
  const NearbyPost(
    title: '读书笔记分享',
    subtitle: '@书虫 · 4.0km',
    coverUrl: 'https://picsum.photos/seed/book1/400/360',
  ),
  const NearbyPost(
    title: '手绘涂鸦作品',
    subtitle: '@画手小白 · 2.7km',
    coverUrl: 'https://picsum.photos/seed/art1/400/480',
  ),
  const NearbyPost(
    title: '健身打卡记录',
    subtitle: '@肌肉小哥 · 1.2km',
    coverUrl: 'https://picsum.photos/seed/gym1/400/320',
  ),
  const NearbyPost(
    title: '街头音乐现场',
    subtitle: '@民谣歌手 · 3.8km',
    coverUrl: 'https://picsum.photos/seed/music1/400/400',
  ),
];

// ════════════════════════════════════════════════════════════════════════
// 同城视图 — 瀑布流布局
// ════════════════════════════════════════════════════════════════════════

class NearbyView extends StatelessWidget {
  // 不规则图片高度列表（营造瀑布流效果）
  final List<double> _imageHeights = [
    120,
    180,
    140,
    200,
    160,
    150,
    190,
    130,
    170,
    145,
  ];

  NearbyView({super.key});

  @override
  Widget build(BuildContext context) {
    // 顶部占位：
    //   MediaQuery.padding.top  → 状态栏高度
    //   + kToolbarHeight        → AppBar 标准高度(56)
    //   + 12                   → 额外间距（AppBar 底部到内容的空隙）
    // final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    // debugPrint(
    //     'topPadding: ${MediaQuery.of(context).padding.top}=================================');

    return Container(
      color: Colors.black,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.of(context).padding.top,
          8,
          8,
        ),
        itemCount: nearbyPosts.length,
        itemBuilder: (context, index) {
          final post = nearbyPosts[index];
          final imageHeight = _imageHeights[index % _imageHeights.length];
          return _NearbyCard(post: post, imageHeight: imageHeight);
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 同城卡片
// ════════════════════════════════════════════════════════════════════════

class _NearbyCard extends StatelessWidget {
  final NearbyPost post;
  final double imageHeight;

  const _NearbyCard({required this.post, required this.imageHeight});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.grey[850],
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 封面图（不规则高度）
          Image.network(
            post.coverUrl,
            height: imageHeight,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: imageHeight,
              color: Colors.grey[800],
              child: const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: imageHeight,
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              );
            },
          ),
          // 文字信息（深色主题）
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  post.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

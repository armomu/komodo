class VideoData {
  final String url;
  final String username;
  final String desc;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;

  const VideoData({
    required this.url,
    required this.username,
    required this.desc,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
  });
}

// 视频数据列表
final List<VideoData> videoList = [
  const VideoData(
    url: 'https://www.w3schools.com/html/movie.mp4',
    username: '@海边的风',
    desc: '海浪声是最好的白噪音 🌊',
    likes: 19200,
    comments: 7600,
    favorites: 4500,
    shares: 3200,
  ),
  const VideoData(
    url: 'https://www.w3schools.com/html/mov_bbb.mp4',
    username: '@蝴蝶记录者',
    desc: '诗和远方，一起去旅行吧~ 🌊',
    likes: 12800,
    comments: 5200,
    favorites: 3300,
    shares: 2100,
  ),
];

/// 格式化数字：超过 1 万显示 x.xw
String formatCount(int count) {
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}w';
  }
  return count.toString();
}

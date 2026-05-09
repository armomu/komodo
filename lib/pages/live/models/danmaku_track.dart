/// 弹幕飞行轨迹记录，用于轨道碰撞检测
class DanmakuTrack {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double topPercent;

  const DanmakuTrack({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.topPercent,
  });
}

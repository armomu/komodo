import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/pages/music/music_player_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 黑胶唱片播放器组件
// 白色方形专辑封面（右侧有半圆缺口）+ 右侧半露的黑胶唱片
// 唱片内部有圆形专辑图，中心有透明小圆孔
// ══════════════════════════════════════════════════════════════════════════════

class VinylRecordPlayer extends StatefulWidget {
  final double size;
  final String? coverUrl;

  const VinylRecordPlayer({super.key, this.size = 360, this.coverUrl});

  @override
  State<VinylRecordPlayer> createState() => _VinylRecordPlayerState();
}

class _VinylRecordPlayerState extends State<VinylRecordPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late MusicPlayerController _musicController;

  Worker? _trackChangeWorker;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _musicController = Get.find<MusicPlayerController>();

    _trackChangeWorker = ever(_musicController.isPlaying, (isPlaying) {
      if (isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    if (_musicController.isPlaying.value) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _trackChangeWorker?.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverSize = widget.size;
    // 唱片比封面略小
    final recordSize = coverSize * 0.88;
    // 唱片向右偏移，露出约一半
    final recordOffset = coverSize * 0.5;
    // 封面右侧半圆缺口的半径
    final notchRadius = coverSize * 0.03;

    return Obx(() {
      final track = _musicController.currentTrack;
      final imageUrl = widget.coverUrl ?? track.avatarUrl;

      return SizedBox(
        width: coverSize + recordOffset * 0.8,
        height: coverSize,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // ====== 黑胶唱片（底层，可旋转） ======
            Positioned(
              left: recordOffset,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: child,
                  );
                },
                child: _buildVinylRecord(recordSize, imageUrl),
              ),
            ),

            // ====== 白色方形专辑封面（带右侧半圆缺口） ======
            _buildCoverWithNotch(coverSize, notchRadius, imageUrl),
          ],
        ),
      );
    });
  }

  /// 构建带半圆缺口的封面
  Widget _buildCoverWithNotch(
    double size,
    double notchRadius,
    String imageUrl,
  ) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CoverNotchPainter(notchRadius: notchRadius),
      child: ClipPath(
        clipper: _CoverNotchClipper(notchRadius: notchRadius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _buildLoadingPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  /// 构建黑胶唱片（含内部圆形专辑图和中心孔）
  Widget _buildVinylRecord(double size, String imageUrl) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1a1a1a),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 唱片沟槽纹理
            _buildGrooves(size),

            // 内部圆形专辑图（占唱片大部分区域）
            Container(
              width: size * 0.62,
              height: size * 0.62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2a2a2a), width: 3),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCenterPlaceholder(),
                      )
                    : _buildCenterPlaceholder(),
              ),
            ),

            // 中心透明小圆孔（spindle hole）
            Container(
              width: size * 0.06,
              height: size * 0.06,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: const Color(0xFF3a3a3a), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 唱片沟槽纹理
  Widget _buildGrooves(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          colors: [
            Color(0xFF2a2a2a),
            Color(0xFF1a1a1a),
            Color(0xFF0a0a0a),
            Color(0xFF1a1a1a),
            Color(0xFF2a2a2a),
            Color(0xFF1a1a1a),
          ],
          stops: [0.2, 0.35, 0.5, 0.65, 0.8, 1.0],
        ),
      ),
      child: CustomPaint(size: Size(size, size), painter: _GroovePainter()),
    );
  }

  /// 中心占位图
  Widget _buildCenterPlaceholder() {
    return Container(
      color: const Color(0xFF2a2a2a),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white24, size: 40),
      ),
    );
  }

  /// 封面占位图
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2a2a2a),
      child: const Center(
        child: Icon(Icons.album, size: 60, color: Colors.white24),
      ),
    );
  }

  /// 加载中占位
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0xFF2a2a2a),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 封面半圆缺口裁剪器
// ══════════════════════════════════════════════════════════════════════════════

class _CoverNotchClipper extends CustomClipper<Path> {
  final double notchRadius;

  _CoverNotchClipper({required this.notchRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchCenter = Offset(size.width, size.height / 2);

    // 绘制带缺口的矩形路径
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
    );

    // 在右侧中间挖去一个半圆
    final notchPath = Path()
      ..addOval(Rect.fromCircle(center: notchCenter, radius: notchRadius));

    // 使用差集运算挖去缺口
    return Path.combine(PathOperation.difference, path, notchPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// 封面缺口绘制器（绘制阴影效果）
// ══════════════════════════════════════════════════════════════════════════════

class _CoverNotchPainter extends CustomPainter {
  final double notchRadius;

  _CoverNotchPainter({required this.notchRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final notchCenter = Offset(size.width, size.height / 2);

    // 绘制缺口边缘的阴影效果，增加立体感
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: notchCenter, radius: notchRadius),
      -pi / 2,
      pi,
      false,
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// 唱片沟槽绘制器
// ══════════════════════════════════════════════════════════════════════════════

class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 绘制同心圆沟槽（从外向内）
    for (double r = maxRadius * 0.35; r < maxRadius * 0.95; r += 2.5) {
      final brightness = ((r / maxRadius) * 25).toInt();
      paint.color = Color.fromARGB(
        255,
        35 + brightness,
        35 + brightness,
        35 + brightness,
      );
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

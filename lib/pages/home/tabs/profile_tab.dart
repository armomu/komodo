import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: theme.scaffoldBackgroundColor,
      //   title: const Text(
      //     '',
      //     style: TextStyle(
      //       fontSize: 32,
      //     ),
      //   ),
      //   iconTheme: const IconThemeData(color: Colors.black),
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 54),
            _buildUserInfo(context),
            // const SizedBox(height: 16),
            // _buildFeatureGrid(context),
            const SizedBox(height: 20),
            _buildPersonalization(context),
            const SizedBox(height: 12),
            _buildDeviceInfo(context),
            const SizedBox(height: 12),
            _buildBatteryManager(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          // 左侧：用户信息
          Container(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名
                const Text(
                  'Candy Teacher',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // 糖果币标签行
                Row(
                  children: [
                    // 糖果图标
                    const Icon(Icons.ice_skating, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '糖果币',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 糖果币数值 + 提现按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 数值
                    const Text(
                      '1923',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    // 立即提现按钮
                    _buildWithdrawButton(context),
                  ],
                ),
              ],
            ),
          ),
          // 右上角：头像
          Positioned(
            top: 0,
            right: 10,
            child: GestureDetector(
              onTap: () => Get.toNamed(Routes.settings),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.grey[200],
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://picsum.photos/seed/user/200/200',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('立即提现')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ¥ 图标（圆形背景）
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE84D7B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '立即提现',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      // 第一项：直播
      _FeatureItem(
        icon: Icons.live_tv,
        label: '直播',
        onTap: () => Get.toNamed(Routes.live),
      ),
      // 第二项：生命周期 Demo
      _FeatureItem(
        icon: Icons.recycling,
        label: '生命周期',
        onTap: () => Get.toNamed(Routes.lifecycleDemo),
      ),
      // 第三项：蓝牙示例
      _FeatureItem(
        icon: Icons.bluetooth,
        label: '蓝牙示例',
        onTap: () => Get.toNamed(Routes.bleDemo),
      ),
      _FeatureItem(
        icon: Icons.favorite_border,
        label: '收藏',
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('点击了 收藏'))),
      ),
      _FeatureItem(
        icon: Icons.history,
        label: '历史',
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('点击了 历史'))),
      ),
      _FeatureItem(
        icon: Icons.bookmark_border,
        label: '书签',
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('点击了 书签'))),
      ),
      _FeatureItem(
        icon: Icons.share_outlined,
        label: '分享',
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('点击了 分享'))),
      ),
      _FeatureItem(
        icon: Icons.download_outlined,
        label: '下载',
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('点击了 下载'))),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '常用功能',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              return _buildFeatureCell(context, features[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCell(BuildContext context, _FeatureItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== 个性化区域 ====================
  Widget _buildPersonalization(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // 标题行
              GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.settings);
                },
                behavior: HitTestBehavior.translucent,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '设置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // 两个功能项
              Row(
                children: [
                  _buildPersonalizationItem(
                    context,
                    icon: Icons.shield_outlined,
                    label: '权限管理',
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('权限管理'))),
                  ),
                  const SizedBox(width: 24),
                  _buildPersonalizationItem(
                    context,
                    icon: Icons.mic_outlined,
                    label: '语音助手',
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('语音助手'))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ==================== 设备信息卡片 ====================
  Widget _buildDeviceInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // 标题行
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '设备信息',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              // 三列数据
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDeviceMetric(
                    context,
                    icon: Icons.memory,
                    label: 'CPU占用',
                    value: '1%',
                    valueColor: const Color(0xFF333333),
                  ),
                  _buildDeviceMetricDivider(context),
                  _buildDeviceMetric(
                    context,
                    icon: Icons.speed,
                    label: '内存占用',
                    value: '95%',
                    valueColor: Colors.orange,
                  ),
                  _buildDeviceMetricDivider(context),
                  _buildDeviceMetric(
                    context,
                    icon: Icons.storage_outlined,
                    label: '剩余存储',
                    value: '52.7 GB',
                    valueColor: const Color(0xFF333333),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 22, color: isDark ? Colors.white70 : Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? _adaptColor(valueColor) : valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceMetricDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Color _adaptColor(Color color) {
    // 简单适配深色模式：橙色保持，黑色变白
    if (color == const Color(0xFF333333)) return Colors.white;
    return color;
  }

  // ==================== 电池管家卡片 ====================
  Widget _buildBatteryManager(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    const batteryPercent = 79;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // 标题行
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '电池管家',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              // 顶部信息行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '电池剩余 $batteryPercent%',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '预计可用: 19小时37分钟',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 半圆环进度条 + 百分比
              SizedBox(
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 半圆环
                    SizedBox(
                      width: 140,
                      height: 80,
                      child: CustomPaint(
                        painter: _SemiCircleProgressPainter(
                          progress: batteryPercent / 100,
                          progressColor: const Color(0xFF4CAF50),
                          trackColor: isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFEEEEEE),
                          strokeWidth: 12,
                        ),
                      ),
                    ),
                    // 百分比数字（圆环下方）
                    const Positioned(
                      bottom: 0,
                      child: Text(
                        '$batteryPercent%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// 半圆环进度条 Painter
class _SemiCircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _SemiCircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - strokeWidth) / 2;

    // 背景轨道（半圆弧）
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    // 进度弧（从左到右，即 π → 0 方向）
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

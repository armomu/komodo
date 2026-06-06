import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 礼物数据结构
// ═══════════════════════════════════════════════════════════════════════════

class GiftData {
  /// 礼物名称
  final String name;

  /// Lottie 动画文件路径（相对于 assets 目录）
  final String lottiePath;

  /// 礼物图标（用于选择面板）
  final String iconName;

  const GiftData({
    required this.name,
    required this.lottiePath,
    required this.iconName,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 礼物配置列表（对应 assets/lotties/ 下的四个动画）
// ═══════════════════════════════════════════════════════════════════════════

const List<GiftData> kGiftList = [
  GiftData(name: '闭眼入', lottiePath: 'assets/lotties/闭眼入.json', iconName: '💰'),
  GiftData(name: '潮范儿', lottiePath: 'assets/lotties/潮范儿.json', iconName: '🔥'),
  GiftData(name: '买它', lottiePath: 'assets/lotties/买它.json', iconName: '🛒'),
  GiftData(name: '清仓', lottiePath: 'assets/lotties/清仓.json', iconName: '💎'),
];

// ═══════════════════════════════════════════════════════════════════════════
// Lottie 动画全屏覆盖组件（Overlay Entry 方式）
// ═══════════════════════════════════════════════════════════════════════════

class LottieOverlayManager {
  static OverlayEntry? _overlayEntry;

  /// 显示礼物动画（自动关闭）
  static void playGiftAnimation(BuildContext context, GiftData gift) {
    // 关闭已有的
    hideAnimation();

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          _LottieFullScreenOverlay(gift: gift, onComplete: hideAnimation),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏动画
  static void hideAnimation() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _LottieFullScreenOverlay extends StatefulWidget {
  final GiftData gift;
  final VoidCallback onComplete;

  const _LottieFullScreenOverlay({
    required this.gift,
    required this.onComplete,
  });

  @override
  State<_LottieFullScreenOverlay> createState() =>
      _LottieFullScreenOverlayState();
}

class _LottieFullScreenOverlayState extends State<_LottieFullScreenOverlay> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Lottie.asset(
            widget.gift.lottiePath,
            width: 280,
            height: 280,
            fit: BoxFit.contain,
            repeat: false, // 只播放一次
            onLoaded: (composition) {
              // composition
              // 动画播放完成后延迟关闭
              Future.delayed(const Duration(milliseconds: 3000), () {
                if (mounted) widget.onComplete();
              });
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 礼物选择 BottomSheet
// ═══════════════════════════════════════════════════════════════════════════

class GiftBottomSheet extends StatelessWidget {
  final void Function(GiftData gift) onGiftSelected;

  const GiftBottomSheet({super.key, required this.onGiftSelected});

  /// 显示礼物选择面板
  static void show(
    BuildContext context,
    void Function(GiftData gift) onSelected,
  ) {
    Get.bottomSheet(
      GiftBottomSheet(onGiftSelected: onSelected),
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4列
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85, // 宽高比：礼物卡片更扁一些
        ),
        itemCount: kGiftList.length,
        itemBuilder: (context, index) {
          final gift = kGiftList[index];
          return _GiftButton(
            gift: gift,
            onTap: () {
              onGiftSelected(gift);
              Get.back(); // 关闭 bottomSheet
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 单个礼物按钮
// ═══════════════════════════════════════════════════════════════════════════

class _GiftButton extends StatelessWidget {
  final GiftData gift;
  final VoidCallback onTap;

  const _GiftButton({required this.gift, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 礼物图标 emoji
            Text(gift.iconName, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            // 礼物名称
            Text(
              gift.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

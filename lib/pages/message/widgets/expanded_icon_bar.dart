import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 图标扩展栏（图片/拍照/礼物/位置/红包）
class ExpandedIconBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final double height;
  final VoidCallback? onImageTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGiftTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onRedPacketTap;

  const ExpandedIconBar({
    super.key,
    required this.colorScheme,
    this.height = 260.0,
    this.onImageTap,
    this.onCameraTap,
    this.onGiftTap,
    this.onLocationTap,
    this.onRedPacketTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: colorScheme.outline, width: 1))),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(Icons.image_outlined, '图片', onImageTap),
                _buildItem(Icons.camera_alt_outlined, '拍照', onCameraTap),
                _buildItem(Icons.card_giftcard, '礼物', onGiftTap),
                _buildItem(Icons.location_on_outlined, '位置', onLocationTap),
                _buildItem(Icons.kebab_dining, '红包', onRedPacketTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: colorScheme.surfaceContainer),
            child: Icon(icon, size: 24, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

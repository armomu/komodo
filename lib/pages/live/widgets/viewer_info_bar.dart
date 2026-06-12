import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 直播间顶部右侧：在线观众头像堆叠 + 人数 + 关闭按钮
/// viewerAvatars 从 WS 实时推送更新
class ViewerInfoBar extends StatelessWidget {
  final int viewerCount;
  final List<String> viewerAvatars;
  final VoidCallback onClose;

  const ViewerInfoBar({
    super.key,
    this.viewerCount = 0,
    this.viewerAvatars = const [],
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final displayAvatars = viewerAvatars.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: (displayAvatars.length * 12.0 + 16).clamp(28, 54),
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < displayAvatars.length; i++)
                Positioned(
                  left: i * 12.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[600],
                    backgroundImage: displayAvatars[i].isNotEmpty
                        ? NetworkImage(displayAvatars[i])
                        : null,
                    child: displayAvatars[i].isEmpty
                        ? Icon(Icons.person, size: 14, color: Colors.grey[300])
                        : null,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$viewerCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            onClose();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

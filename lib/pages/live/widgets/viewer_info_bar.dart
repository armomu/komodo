import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 直播间顶部右侧：观众头像 + 人数 + 关闭按钮
class ViewerInfoBar extends StatelessWidget {
  final VoidCallback onClose;

  const ViewerInfoBar({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 12.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [Colors.purple[200], Colors.teal[200], Colors.orange[200]][i],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(Icons.person, size: 14, color: Colors.grey[700]),
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
          child: const Text(
            '8888',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

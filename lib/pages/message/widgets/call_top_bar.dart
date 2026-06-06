import 'package:flutter/material.dart';

/// 视频通话页面顶部栏（返回按钮 + 对方昵称）
class CallTopBar extends StatelessWidget {
  final String peerName;
  final VoidCallback onBack;

  const CallTopBar({super.key, required this.peerName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(height: 36, width: 36, child: BackButton(onPressed: onBack)),
        // const SizedBox(width: 8),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        //   decoration: BoxDecoration(
        //     color: Colors.black26,
        //     borderRadius: BorderRadius.circular(16),
        //   ),
        //   child: Text(
        //     peerName,
        //     style: const TextStyle(color: Colors.white, fontSize: 12),
        //   ),
        // ),
      ],
    );
  }
}

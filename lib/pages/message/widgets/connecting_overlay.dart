import 'package:flutter/material.dart';

/// 视频通话连接中的覆盖层
class ConnectingOverlay extends StatelessWidget {
  final String peerName;

  const ConnectingOverlay({
    super.key,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            '正在连接...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待 $peerName 加入...',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

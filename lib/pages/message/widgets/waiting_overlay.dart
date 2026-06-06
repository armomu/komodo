import 'package:flutter/material.dart';

/// 等待对方接受视频通话的覆盖层
class WaitingOverlay extends StatelessWidget {
  final String peerName;
  final VoidCallback onHangUp;

  const WaitingOverlay({
    super.key,
    required this.peerName,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          Text(
            '正在呼叫 $peerName...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '等待对方接受视频通话',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: IconButton(
              onPressed: onHangUp,
              icon: const Icon(Icons.call_end, color: Colors.white, size: 36),
              iconSize: 36,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频通话已结束的覆盖层
class CallEndedOverlay extends StatelessWidget {
  const CallEndedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call_end, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          const Text(
            '通话已结束',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

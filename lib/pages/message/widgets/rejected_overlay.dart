import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 对方拒绝通话的覆盖层（2秒后自动返回）
class RejectedOverlay extends StatefulWidget {
  final String peerName;

  const RejectedOverlay({super.key, required this.peerName});

  @override
  State<RejectedOverlay> createState() => _RejectedOverlayState();
}

class _RejectedOverlayState extends State<RejectedOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Get.back();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_disabled, color: Colors.white54, size: 64),
          const SizedBox(height: 24),
          Text(
            '${widget.peerName} 拒绝了通话',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '即将返回...',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

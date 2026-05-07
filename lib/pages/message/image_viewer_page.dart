import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

/// 图片查看页面
/// 支持缩放、分享
class ImageViewerPage extends StatelessWidget {
  final String imageUrl;
  final bool isLocalImage;

  const ImageViewerPage({
    super.key,
    required this.imageUrl,
    this.isLocalImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
            onPressed: () => _shareImage(context),
            tooltip: '分享',
          ),
        ],
      ),
      body:
          // 图片查看器
          PhotoView(
            imageProvider: isLocalImage
                ? FileImage(File(imageUrl))
                : NetworkImage(imageUrl) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                color: Colors.white,
              ),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text('图片加载失败', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      if (isLocalImage) {
        // 本地图片分享
        await Share.shareXFiles([XFile(imageUrl)], text: '分享图片');
      } else {
        // 网络图片分享（只分享链接）
        await Share.share(imageUrl);
      }
    } catch (e) {
      debugPrint('【图片分享失败】$e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享失败')));
      }
    }
  }
}

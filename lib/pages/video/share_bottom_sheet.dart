import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'share_data.dart';

void showShareBottomSheet() {
  final shareItems = [
    const ShareItem(icon: Icons.link, label: '复制链接', color: Colors.blue),
    const ShareItem(icon: Icons.chat, label: '微信', color: Colors.green),
    const ShareItem(icon: Icons.wechat, label: '朋友圈', color: Colors.green),
    const ShareItem(icon: Icons.qr_code, label: '二维码', color: Colors.purple),
    const ShareItem(
      icon: Icons.shape_line,
      label: '系统分享',
      color: Colors.grey,
    ),
    const ShareItem(
      icon: Icons.bookmark_border,
      label: '收藏',
      color: Colors.amber,
    ),
    const ShareItem(icon: Icons.report, label: '举报', color: Colors.red),
  ];

  AppBottomSheet.show(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: shareItems.length,
            itemBuilder: (context, index) =>
                ShareItemWidget(item: shareItems[index]),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: const Center(
              child: Text(
                '取消',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 分享选项格子
// ─────────────────────────────────────────────────────────────────────────────

class ShareItemWidget extends StatelessWidget {
  final ShareItem item;

  const ShareItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.snackbar(
          '分享',
          '已选择${item.label}',
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

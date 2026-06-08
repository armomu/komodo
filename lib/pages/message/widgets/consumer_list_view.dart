import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/pages/message/controllers/consumer_list_controller.dart';
import 'package:komodo/pages/message/widgets/consumer_list_tile.dart';

/// 消费者列表视图
///
/// 包含：下拉刷新、上拉加载更多、未登录空状态、空列表状态。
class ConsumerListView extends StatelessWidget {
  final controller = ConsumerListController.to;

  ConsumerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        // 未登录
        if (!Get.find<UserController>().isLoggedIn) {
          return _buildNotLoggedIn();
        }

        // 首次加载中
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 空列表
        if (controller.consumers.isEmpty && !controller.isLoading.value) {
          return _buildEmpty();
        }

        // 列表
        return RefreshIndicator(
          onRefresh: () => controller.refreshList(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: controller.consumers.length + 1, // +1 for loading more indicator
            itemBuilder: (context, index) {
              // 最后一项：加载更多指示器
              if (index == controller.consumers.length) {
                return _buildLoadMoreIndicator();
              }
              final item = controller.consumers[index];
              return ConsumerListTile(
                item: item,
                onTap: () => controller.openChat(item),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('请先登录', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无聊天', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (!controller.isLoadingMore.value) {
        return const SizedBox.shrink();
      }
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    });
  }
}

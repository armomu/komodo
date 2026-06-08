import 'package:flutter/material.dart';
import 'package:komodo/pages/message/controllers/consumer_list_controller.dart';
import 'package:komodo/pages/message/widgets/consumer_list_view.dart';

/// 消息 Tab（消费者列表页）
///
/// 纯 UI 壳，所有状态由 ConsumerListController 驱动。
class MessageTab extends StatelessWidget {
  final controller = ConsumerListController.to;

  MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
      ),
      body: ConsumerListView(),
    );
  }
}

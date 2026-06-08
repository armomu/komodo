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
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool _) {
        return <Widget>[
          const SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Messages',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              titlePadding: EdgeInsets.fromLTRB(16, 16, 3, 12),
            ),
          ),
        ];
      },
      body: ConsumerListView(),
    );
  }
}

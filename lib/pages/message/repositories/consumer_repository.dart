import 'package:komodo/database/chat_database.dart';
import 'package:komodo/pages/message/models/consumer_list_item.dart';
import 'package:komodo/utils/request.dart';

/// 消费者列表数据仓库
///
/// 封装 API 拉取 + DB 查询，为 Controller 提供干净的数据接口。
class ConsumerRepository {
  /// 拉取消费者分页列表（API）
  /// 返回 (List<ConsumerListItem> items, int totalPages, int total)
  Future<(List<ConsumerListItem>, int, int)> fetchConsumerPage(int page, int pageSize) async {
    final resp = await appDio<Map<String, dynamic>>(
      '/consumer/auth/list',
      method: 'get',
      params: {'page': '$page', 'pageSize': '$pageSize'},
    );

    if (!resp.isSuccess || resp.data == null) {
      return (<ConsumerListItem>[], 0, 0);
    }

    final data = resp.data!;
    final List<dynamic> listJson = data['list'] as List<dynamic>? ?? [];
    final int total = data['total'] as int? ?? 0;
    final int totalPages = data['totalPages'] as int? ?? 0;

    // 转为 ConsumerListItem（先不带 lastMessage/unread/isOnline）
    final items = <ConsumerListItem>[];
    for (final json in listJson) {
      final j = json as Map<String, dynamic>;
      items.add(ConsumerListItem(
        id: j['id'] as int,
        nickname: j['nickname'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
        enable: j['enable'] as bool? ?? true,
      ));
    }

    // 从 DB 补充 lastMessage 和 unread
    final db = ChatDatabase.to;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final (content, time) = await db.getLastMessageByPeerId(item.id);
      final unread = await db.getUnreadCountByPeerId(item.id);
      items[i] = item.copyWith(
        lastMessage: content,
        lastTime: time,
        unread: unread,
      );
    }

    return (items, totalPages, total);
  }
}

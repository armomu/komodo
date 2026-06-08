
/// 消费者列表项 ViewModel（不可变）
///
/// 承载消息 Tab 列表项展示所需的全部字段，
/// 任何属性变化 = 创建新实例替换 RxList 中的旧项。
class ConsumerListItem {
  final int id;
  final String nickname;
  final String avatar;
  final bool enable;

  /// 最后一条消息内容（从 DB 查询）
  final String? lastMessage;

  /// 最后消息时间
  final String? lastTime;

  /// 未读数（内存维护，进入聊天页清 0）
  final int unread;

  /// 是否在线
  final bool isOnline;

  const ConsumerListItem({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.enable,
    this.lastMessage,
    this.lastTime,
    this.unread = 0,
    this.isOnline = false,
  });

  /// 创建新实例（不可变更新）
  ConsumerListItem copyWith({
    int? id,
    String? nickname,
    String? avatar,
    bool? enable,
    String? lastMessage,
    String? lastTime,
    int? unread,
    bool? isOnline,
  }) {
    return ConsumerListItem(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      enable: enable ?? this.enable,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

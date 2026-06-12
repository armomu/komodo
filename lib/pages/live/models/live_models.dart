/// 直播状态
enum LiveRoomStatus {
  waiting,
  live,
  ended,
}

/// 直播间
class LiveRoom {
  final String id;
  final int hostId;
  final String? hostNickname;
  final String? hostAvatar;
  final String title;
  final String coverUrl;
  final String announcement;
  final String status;
  final String rtmpKey;
  final int viewerCount;
  final int totalViews;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  LiveRoom({
    required this.id,
    required this.hostId,
    this.hostNickname,
    this.hostAvatar,
    required this.title,
    this.coverUrl = '',
    this.announcement = '',
    required this.status,
    required this.rtmpKey,
    this.viewerCount = 0,
    this.totalViews = 0,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  bool get isLive => status == 'live';

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    final host = json['host'] as Map<String, dynamic>?;
    return LiveRoom(
      id: json['id'] as String,
      hostId: json['hostId'] as int,
      hostNickname: host?['nickname'] as String?,
      hostAvatar: host?['avatar'] as String?,
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      announcement: json['announcement'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      rtmpKey: json['rtmpKey'] as String? ?? '',
      viewerCount: json['viewerCount'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'] as String) : null,
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 在线观众
class LiveViewer {
  final int userId;
  final String nickname;
  final String avatar;

  LiveViewer({
    required this.userId,
    this.nickname = '',
    this.avatar = '',
  });

  factory LiveViewer.fromJson(Map<String, dynamic> json) {
    return LiveViewer(
      userId: json['userId'] as int,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// 直播间评论/弹幕
class LiveComment {
  final int id;
  final int userId;
  final String nickname;
  final String avatar;
  final String message;
  final DateTime createdAt;

  LiveComment({
    required this.id,
    required this.userId,
    this.nickname = '',
    this.avatar = '',
    required this.message,
    required this.createdAt,
  });

  factory LiveComment.fromJson(Map<String, dynamic> json) {
    return LiveComment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 礼物
class LiveGift {
  final int id;
  final int senderId;
  final String senderNickname;
  final String senderAvatar;
  final String giftName;
  final String giftIcon;
  final String lottiePath;
  final DateTime createdAt;

  LiveGift({
    required this.id,
    required this.senderId,
    this.senderNickname = '',
    this.senderAvatar = '',
    required this.giftName,
    this.giftIcon = '',
    this.lottiePath = '',
    required this.createdAt,
  });

  factory LiveGift.fromJson(Map<String, dynamic> json) {
    return LiveGift(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      senderNickname: json['senderNickname'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String? ?? '',
      giftName: json['giftName'] as String? ?? '',
      giftIcon: json['giftIcon'] as String? ?? '',
      lottiePath: json['lottiePath'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 直播历史
class LiveRoomHistory {
  final int id;
  final String roomId;
  final int hostId;
  final String title;
  final String coverUrl;
  final String announcement;
  final int totalViews;
  final int peakViewers;
  final int commentCount;
  final int giftCount;
  final DateTime startedAt;
  final DateTime endedAt;
  final int duration;
  final DateTime createdAt;

  LiveRoomHistory({
    required this.id,
    required this.roomId,
    required this.hostId,
    this.title = '',
    this.coverUrl = '',
    this.announcement = '',
    this.totalViews = 0,
    this.peakViewers = 0,
    this.commentCount = 0,
    this.giftCount = 0,
    required this.startedAt,
    required this.endedAt,
    this.duration = 0,
    required this.createdAt,
  });

  String get durationText {
    final h = duration ~/ 3600;
    final m = (duration % 3600) ~/ 60;
    final s = duration % 60;
    if (h > 0) return '$h时$m分$s秒';
    if (m > 0) return '$m分$s秒';
    return '$s秒';
  }

  factory LiveRoomHistory.fromJson(Map<String, dynamic> json) {
    return LiveRoomHistory(
      id: json['id'] as int,
      roomId: json['roomId'] as String,
      hostId: json['hostId'] as int,
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      announcement: json['announcement'] as String? ?? '',
      totalViews: json['totalViews'] as int? ?? 0,
      peakViewers: json['peakViewers'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      giftCount: json['giftCount'] as int? ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      duration: json['duration'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 历史详情（含评论和礼物）
class LiveHistoryDetail {
  final LiveRoomHistory history;
  final List<LiveComment> comments;
  final List<LiveGift> gifts;

  LiveHistoryDetail({
    required this.history,
    required this.comments,
    required this.gifts,
  });

  factory LiveHistoryDetail.fromJson(Map<String, dynamic> json) {
    return LiveHistoryDetail(
      history: LiveRoomHistory.fromJson(json['history'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => LiveComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((e) => LiveGift.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

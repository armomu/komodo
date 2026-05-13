import 'dart:convert';

/// 信令消息体——解码/编码统一的 JSON 消息格式。
///
/// 协议格式：{ "event": String, "data": Object }
/// 服务端地址：ws://{host}:3002
class SignalingMessage {
  final String event;
  final Map<String, dynamic> data;

  SignalingMessage({required this.event, required this.data});

  factory SignalingMessage.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return SignalingMessage(
      event: map['event'] as String? ?? '',
      data: (map['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  String toJson() => jsonEncode({'event': event, 'data': data});

  @override
  String toString() => 'SignalingMessage(event: $event, data: $data)';
}

// ==================== 服务端事件（接收） ====================

/// 服务端发来的连接确认，包含分配的 uid
///
/// event: "connected", data: { uid: String }
class ConnectedMessage {
  final String uid;
  ConnectedMessage({required this.uid});

  factory ConnectedMessage.fromData(Map<String, dynamic> data) =>
      ConnectedMessage(uid: data['uid'] as String? ?? '');
}

/// 新用户加入房间
///
/// event: "user-joined", data: { uid: String }
class UserJoinedMessage {
  final String uid;
  UserJoinedMessage({required this.uid});

  factory UserJoinedMessage.fromData(Map<String, dynamic> data) =>
      UserJoinedMessage(uid: data['uid'] as String? ?? '');
}

/// 用户离开房间
///
/// event: "user-left", data: { uid: String }
class UserLeftMessage {
  final String uid;
  UserLeftMessage({required this.uid});

  factory UserLeftMessage.fromData(Map<String, dynamic> data) =>
      UserLeftMessage(uid: data['uid'] as String? ?? '');
}

/// 房间用户列表（加入房间后服务端回复）
///
/// event: "room-users", data: { roomId: String, users: [{ uid: String }] }
class RoomUsersMessage {
  final String roomId;
  final List<String> users;

  RoomUsersMessage({required this.roomId, required this.users});

  factory RoomUsersMessage.fromData(Map<String, dynamic> data) {
    final list = (data['users'] as List<dynamic>?)
            ?.map((e) => (e as Map<String, dynamic>)['uid'] as String)
            .toList() ??
        [];
    return RoomUsersMessage(
      roomId: data['roomId'] as String? ?? '',
      users: list,
    );
  }
}

/// 收到对端传来的 SDP Offer
///
/// event: "offer", data: { from: String, sdp: String }
class OfferMessage {
  final String from;
  final String sdp;
  OfferMessage({required this.from, required this.sdp});

  factory OfferMessage.fromData(Map<String, dynamic> data) =>
      OfferMessage(
        from: data['from'] as String? ?? '',
        sdp: data['sdp'] as String? ?? '',
      );
}

/// 收到对端传来的 SDP Answer
///
/// event: "answer", data: { from: String, sdp: String }
class AnswerMessage {
  final String from;
  final String sdp;
  AnswerMessage({required this.from, required this.sdp});

  factory AnswerMessage.fromData(Map<String, dynamic> data) =>
      AnswerMessage(
        from: data['from'] as String? ?? '',
        sdp: data['sdp'] as String? ?? '',
      );
}

/// 收到对端传来的 ICE Candidate
///
/// event: "ice-candidate", data: { from: String, candidate: String }
class IceCandidateMessage {
  final String from;
  final String candidate;
  IceCandidateMessage({required this.from, required this.candidate});

  factory IceCandidateMessage.fromData(Map<String, dynamic> data) =>
      IceCandidateMessage(
        from: data['from'] as String? ?? '',
        candidate: data['candidate'] as String? ?? '',
      );
}

/// 对端挂断
///
/// event: "call-ended", data: { from: String }
class CallEndedMessage {
  final String from;
  CallEndedMessage({required this.from});

  factory CallEndedMessage.fromData(Map<String, dynamic> data) =>
      CallEndedMessage(from: data['from'] as String? ?? '');
}

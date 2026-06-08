enum ChatMsgType { timestamp, text, voice, image, gift }

class ChatMessage {
  final ChatMsgType type;
  final bool isMe;
  final String? content;
  final String? imageUrl;
  final bool isLocalImage;
  final int? duration;
  final String? voicePath;
  final String? giftEmoji;
  final String? giftLabel;
  final String? time;

  const ChatMessage({
    required this.type,
    this.isMe = false,
    this.content,
    this.imageUrl,
    this.isLocalImage = false,
    this.duration,
    this.voicePath,
    this.giftEmoji,
    this.giftLabel,
    this.time,
  });
}

enum ChatRecordState { idle, ready, recording, preview }

/// 在线用户信息
class OnlineUser {
  final int userId;
  final String nickname;
  final String avatar;

  const OnlineUser({
    required this.userId,
    required this.nickname,
    required this.avatar,
  });

  factory OnlineUser.fromJson(Map<String, dynamic> json) {
    return OnlineUser(
      userId: json['userId'] as int,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// 离线消息事件数据（服务端推送，含 id）
class OfflineMessageData {
  final int id;
  final int from;
  final String nickname;
  final String avatar;
  final String message;
  final int timestamp;

  const OfflineMessageData({
    required this.id,
    required this.from,
    required this.nickname,
    required this.avatar,
    required this.message,
    required this.timestamp,
  });
}

/// 聊天消息事件数据
class ChatMessageData {
  final int from;
  final String nickname;
  final String avatar;
  final String message;
  final int timestamp;

  const ChatMessageData({
    required this.from,
    required this.nickname,
    required this.avatar,
    required this.message,
    required this.timestamp,
  });
}

/// WebRTC 信令事件数据
class SdpData {
  final int from;
  final String sdp;
  const SdpData({required this.from, required this.sdp});
}

class IceData {
  final int from;
  final String candidate;
  const IceData({required this.from, required this.candidate});
}

class PeerReadyData {
  final String roomId;
  final List<int> peers;
  const PeerReadyData({required this.roomId, required this.peers});
}

class RoomUsersData {
  final String roomId;
  final List<int> users;
  const RoomUsersData({required this.roomId, required this.users});
}

class VideoCallInviteData {
  final int from;
  final String nickname;
  final String avatar;
  final String roomId;
  const VideoCallInviteData({
    required this.from,
    required this.nickname,
    required this.avatar,
    required this.roomId,
  });
}

class VideoCallAcceptData {
  final int from;
  final String roomId;
  const VideoCallAcceptData({required this.from, required this.roomId});
}

class VideoCallRejectData {
  final int from;
  final String roomId;
  const VideoCallRejectData({required this.from, required this.roomId});
}

/// 通话状态
enum CallState {
  /// 空闲
  idle,

  /// 呼叫中（正在给对端发 offer）
  calling,

  /// 收到来电（收到对端 offer）
  incoming,

  /// 正在连接（交换 ICE）
  connecting,

  /// 已连接（视频通话中）
  connected,

  /// 已挂断
  ended,

  /// 错误
  error,
  waiting,
}

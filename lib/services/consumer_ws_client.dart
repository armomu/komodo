import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

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

/// Consumer WebSocket 统一客户端
///
/// 连接到 cubeverse 后端 (ws://host:8085)
/// 功能：JWT 认证 / 在线列表 / 文本聊天 / WebRTC 信令 / 视频通话邀请
class ConsumerWsClient extends GetxService {
  WebSocket? _ws;
  bool _connected = false;

  /// 后端主机地址
  String _host = '192.168.1.38';
  final int _port = 8085;

  Timer? _heartbeatTimer;

  // ===================== Rx 响应式状态 =====================

  final isConnected = false.obs;
  final isAuthenticated = false.obs;
  final onlineUsers = <OnlineUser>[].obs;

  // ===================== Stream 控制器 =====================

  final _onChatMessage = StreamController<ChatMessageData>.broadcast();
  final _onChatError = StreamController<String>.broadcast();
  final _onKicked = StreamController<String>.broadcast();

  // WebRTC 信令
  final _onRoomUsers = StreamController<RoomUsersData>.broadcast();
  final _onPeerReady = StreamController<PeerReadyData>.broadcast();
  final _onUserJoined = StreamController<String>.broadcast(); // room-level
  final _onUserLeft = StreamController<String>.broadcast(); // room-level
  final _onOffer = StreamController<SdpData>.broadcast();
  final _onAnswer = StreamController<SdpData>.broadcast();
  final _onIceCandidate = StreamController<IceData>.broadcast();
  final _onCallEnded = StreamController<int>.broadcast();

  // 视频通话邀请
  final _onVideoCallInvite = StreamController<VideoCallInviteData>.broadcast();
  final _onVideoCallAccept = StreamController<VideoCallAcceptData>.broadcast();
  final _onVideoCallReject = StreamController<VideoCallRejectData>.broadcast();

  // ===================== 公开 Stream =====================

  Stream<ChatMessageData> get onChatMessage => _onChatMessage.stream;
  Stream<String> get onChatError => _onChatError.stream;
  Stream<String> get onKicked => _onKicked.stream;
  Stream<RoomUsersData> get onRoomUsers => _onRoomUsers.stream;
  Stream<PeerReadyData> get onPeerReady => _onPeerReady.stream;
  Stream<String> get onUserJoined => _onUserJoined.stream;
  Stream<String> get onUserLeft => _onUserLeft.stream;
  Stream<SdpData> get onOffer => _onOffer.stream;
  Stream<SdpData> get onAnswer => _onAnswer.stream;
  Stream<IceData> get onIceCandidate => _onIceCandidate.stream;
  Stream<int> get onCallEnded => _onCallEnded.stream;
  Stream<VideoCallInviteData> get onVideoCallInvite => _onVideoCallInvite.stream;
  Stream<VideoCallAcceptData> get onVideoCallAccept => _onVideoCallAccept.stream;
  Stream<VideoCallRejectData> get onVideoCallReject => _onVideoCallReject.stream;

  // ===================== 连接 / 断开 =====================

  /// 连接 WebSocket 并认证
  Future<void> connect(String token, {String? host}) async {
    // 如果已有连接先断开
    if (_connected) {
      disconnect();
      // 等一小段时间确保旧连接清理
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (host != null) _host = host;

    final url = 'ws://$_host:$_port';
    debugPrint('[WS] 连接: $url');

    try {
      _ws = await WebSocket.connect(url);
      _connected = true;
      isConnected.value = true;

      _ws!.listen(
        (data) => _handleMessage(data as String),
        onError: (error) {
          debugPrint('[WS] 错误: $error');
          _onChatError.add('连接错误: $error');
          _resetState();
        },
        onDone: () {
          debugPrint('[WS] 连接关闭');
          _resetState();
        },
      );

      // 开始心跳
      _startHeartbeat();

      // 发送认证
      _send('auth', {'token': token});
    } catch (e) {
      _connected = false;
      isConnected.value = false;
      _onChatError.add('连接失败: $e');
      rethrow;
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _ws?.close();
    _resetState();
  }

  void _resetState() {
    _connected = false;
    isConnected.value = false;
    isAuthenticated.value = false;
    onlineUsers.clear();
  }

  // ===================== 发送消息 =====================

  /// 发送聊天消息
  void sendChatMessage(int toUserId, String message) {
    _send('chat-message', {'to': toUserId, 'message': message});
  }

  /// WebRTC 房间
  void joinRoom(String roomId) {
    _send('join-room', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _send('leave-room', {'roomId': roomId});
  }

  void sendOffer(String roomId, int to, String sdp) {
    _send('offer', {'roomId': roomId, 'to': to, 'sdp': sdp});
  }

  void sendAnswer(String roomId, int to, String sdp) {
    _send('answer', {'roomId': roomId, 'to': to, 'sdp': sdp});
  }

  void sendIceCandidate(String roomId, int to, String candidate) {
    _send('ice-candidate', {'roomId': roomId, 'to': to, 'candidate': candidate});
  }

  void sendEndCall(String roomId, int to) {
    _send('end-call', {'roomId': roomId, 'to': to});
  }

  /// 视频通话邀请
  void sendVideoCallInvite(int toUserId, String roomId) {
    _send('video-call-invite', {'to': toUserId, 'roomId': roomId});
  }

  void sendVideoCallAccept(int toUserId, String roomId) {
    _send('video-call-accept', {'to': toUserId, 'roomId': roomId});
  }

  void sendVideoCallReject(int toUserId, String roomId) {
    _send('video-call-reject', {'to': toUserId, 'roomId': roomId});
  }

  // ===================== 内部 =====================

  void _send(String event, Map<String, dynamic> data) {
    if (_ws != null && _ws!.readyState == WebSocket.open) {
      _ws!.add(jsonEncode({'event': event, 'data': data}));
    }
  }

  void _handleMessage(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final event = map['event'] as String? ?? '';
      final data = (map['data'] as Map<String, dynamic>?) ?? {};
      debugPrint('[WS] 收到: $event $data');

      switch (event) {
        // ---- 认证 ----
        case 'auth-success':
          isAuthenticated.value = true;
          debugPrint('[WS] 认证成功');
          break;

        case 'auth-error':
          isAuthenticated.value = false;
          _onChatError.add(data['message'] as String? ?? '认证失败');
          break;

        case 'kicked':
          _onKicked.add(data['message'] as String? ?? '账号在其他设备登录');
          disconnect();
          break;

        // ---- 在线列表 ----
        case 'online-list':
          final list = (data['users'] as List<dynamic>?)
                  ?.map((e) => OnlineUser.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          onlineUsers.assignAll(list);
          break;

        case 'user-joined':
          // 全局在线列表（data.user 存在）或房间级别（data.userId 直接）
          final globalUser = data['user'] as Map<String, dynamic>?;
          if (globalUser != null) {
            final user = OnlineUser.fromJson(globalUser);
            onlineUsers.addIf(
                !onlineUsers.any((u) => u.userId == user.userId), user);
          } else if (data['userId'] != null) {
            _onUserJoined.add(data['userId'].toString());
          }
          break;

        case 'user-left':
          // 全局在线列表或房间级别
          final leftUserId = data['userId'] as int?;
          if (leftUserId != null) {
            onlineUsers.removeWhere((u) => u.userId == leftUserId);
          } else {
            _onUserLeft.add(data['userId']?.toString() ?? '');
          }
          break;

        // ---- 聊天 ----
        case 'chat-message':
          _onChatMessage.add(ChatMessageData(
            from: data['from'] as int,
            nickname: data['nickname'] as String? ?? '',
            avatar: data['avatar'] as String? ?? '',
            message: data['message'] as String? ?? '',
            timestamp: data['timestamp'] as int? ?? 0,
          ));
          break;

        case 'chat-error':
          _onChatError.add(data['message'] as String? ?? '');
          break;

        // ---- WebRTC 房间 ----
        case 'room-users':
          final roomId = data['roomId'] as String? ?? '';
          final users = (data['users'] as List<dynamic>?)
                  ?.map((e) => (e as Map<String, dynamic>)['userId'] as int)
                  .toList() ??
              [];
          _onRoomUsers.add(RoomUsersData(roomId: roomId, users: users));
          break;

        case 'peer-ready':
          final prRoomId = data['roomId'] as String? ?? '';
          final peers = (data['peers'] as List<dynamic>?)
                  ?.map((e) => (e as Map<String, dynamic>)['userId'] as int)
                  .toList() ??
              [];
          _onPeerReady.add(PeerReadyData(roomId: prRoomId, peers: peers));
          break;

        // ---- WebRTC 信令 ----
        case 'offer':
          _onOffer.add(SdpData(
            from: data['from'] as int,
            sdp: data['sdp'] as String? ?? '',
          ));
          break;

        case 'answer':
          _onAnswer.add(SdpData(
            from: data['from'] as int,
            sdp: data['sdp'] as String? ?? '',
          ));
          break;

        case 'ice-candidate':
          _onIceCandidate.add(IceData(
            from: data['from'] as int,
            candidate: data['candidate'] as String? ?? '',
          ));
          break;

        case 'call-ended':
          _onCallEnded.add(data['from'] as int? ?? 0);
          break;

        // ---- 视频通话邀请 ----
        case 'video-call-invite':
          _onVideoCallInvite.add(VideoCallInviteData(
            from: data['from'] as int,
            nickname: data['nickname'] as String? ?? '',
            avatar: data['avatar'] as String? ?? '',
            roomId: data['roomId'] as String? ?? '',
          ));
          break;

        case 'video-call-accept':
          _onVideoCallAccept.add(VideoCallAcceptData(
            from: data['from'] as int,
            roomId: data['roomId'] as String? ?? '',
          ));
          break;

        case 'video-call-reject':
          _onVideoCallReject.add(VideoCallRejectData(
            from: data['from'] as int,
            roomId: data['roomId'] as String? ?? '',
          ));
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[WS] 消息解析错误: $e');
    }
  }

  // ===================== 心跳 =====================

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send('ping', {});
    });
  }

  @override
  void onClose() {
    disconnect();
    _onChatMessage.close();
    _onChatError.close();
    _onKicked.close();
    _onRoomUsers.close();
    _onPeerReady.close();
    _onUserJoined.close();
    _onUserLeft.close();
    _onOffer.close();
    _onAnswer.close();
    _onIceCandidate.close();
    _onCallEnded.close();
    _onVideoCallInvite.close();
    _onVideoCallAccept.close();
    _onVideoCallReject.close();
    super.onClose();
  }
}

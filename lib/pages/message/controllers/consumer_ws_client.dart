import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/components/show_snackbar.dart';
import 'package:komodo/config/base_url.dart';
import 'package:komodo/database/chat_database.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import 'package:komodo/routes/app_routes.dart';

/// Consumer WebSocket 统一客户端
///
/// 连接到 cubeverse 后端 (ws://host:8085)
/// 功能：JWT 认证 / 在线列表 / 文本聊天 / WebRTC 信令 / 视频通话邀请
class ConsumerWsClient extends GetxService {
  WebSocket? _ws;
  bool _connected = false;

  Timer? _heartbeatTimer;

  // ===================== Rx 响应式状态 =====================

  final isConnected = false.obs;
  final isAuthenticated = false.obs;
  final onlineUsers = <OnlineUser>[].obs;

  /// 当前正在聊天的 peerId（null 表示不在聊天页）
  final currentChatPeerId = Rx<int?>(null);

  // ===================== Stream 控制器 =====================

  final _onChatMessage = StreamController<ChatMessageData>.broadcast();
  final _onChatError = StreamController<String>.broadcast();
  final _onKicked = StreamController<String>.broadcast();
  final _onOfflineMessage = StreamController<ChatMessageData>.broadcast();

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
  Stream<ChatMessageData> get onOfflineMessage => _onOfflineMessage.stream;
  Stream<RoomUsersData> get onRoomUsers => _onRoomUsers.stream;
  Stream<PeerReadyData> get onPeerReady => _onPeerReady.stream;
  Stream<String> get onUserJoined => _onUserJoined.stream;
  Stream<String> get onUserLeft => _onUserLeft.stream;
  Stream<SdpData> get onOffer => _onOffer.stream;
  Stream<SdpData> get onAnswer => _onAnswer.stream;
  Stream<IceData> get onIceCandidate => _onIceCandidate.stream;
  Stream<int> get onCallEnded => _onCallEnded.stream;
  Stream<VideoCallInviteData> get onVideoCallInvite =>
      _onVideoCallInvite.stream;
  Stream<VideoCallAcceptData> get onVideoCallAccept =>
      _onVideoCallAccept.stream;
  Stream<VideoCallRejectData> get onVideoCallReject =>
      _onVideoCallReject.stream;

  @override
  void onInit() {
    super.onInit();
    // 收到消息
    onChatMessage.listen(_handleIncomingMessage);
    onOfflineMessage.listen(_handleIncomingMessage);
    // 收到视频通话邀请：直接跳转到视频通话页，由页面展示来电弹窗让用户手动接听/拒绝
    // 注意：不再自动调用 sendVideoCallAccept，接听/拒绝逻辑移至 VideoCallPage
    onVideoCallInvite.listen((data) {
      Get.toNamed(
        Routes.chatVideoCall,
        arguments: {
          'peerUserId': data.from,
          'peerName': data.nickname,
          'roomId': data.roomId,
          'isCaller': false, // 标记为被叫方，页面会显示来电接听界面
        },
      );
    });
  }

  // ===================== 连接 / 断开 =====================

  /// 连接 WebSocket 并认证
  Future<void> connect() async {
    final box = GetStorage();
    final token = box.read<String>(BaseUrl.tokenKey) ?? '';
    if (token.isEmpty) {
      isConnected.value = false;
      _onChatError.add('请先登录');
      return;
    }
    // 如果已有连接先断开
    if (_connected) {
      disconnect();
      // 等一小段时间确保旧连接清理
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final url = BaseUrl.msgWsHost();
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
      _send('auth', {'token': GetStorage().read<String>('access_token') ?? ''});
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
    _send('ice-candidate', {
      'roomId': roomId,
      'to': to,
      'candidate': candidate,
    });
  }

  void sendEndCall(String roomId, int to) {
    _send('end-call', {'roomId': roomId, 'to': to});
  }

  /// 视频通话邀请
  void sendVideoCallInvite(int toUserId, String roomId) {
    _send('video-call-invite', {'to': toUserId, 'roomId': roomId});
  }

  /// 主动拉取在线用户列表（前端调用）
  void sendGetOnlineUsers() {
    _send('get-online-users', {});
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
        case 'device-update':
          AppSnackBar.show('新设备：${data['device']['name']}');
          break;

        // ---- 认证 ----
        case 'auth-success':
          isAuthenticated.value = true;
          debugPrint('[WS] 认证成功');
          break;

        case 'auth-error':
          isAuthenticated.value = false;
          _onChatError.add(data['message'] as String? ?? '认证失败');
          AppSnackBar.show('认证失败');
          break;

        case 'kicked':
          _onKicked.add(data['message'] as String? ?? '账号在其他设备登录');
          disconnect();
          break;

        // ---- 在线列表 ----
        case 'online-list':
          final list =
              (data['users'] as List<dynamic>?)
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
              !onlineUsers.any((u) => u.userId == user.userId),
              user,
            );
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
          _onChatMessage.add(
            ChatMessageData(
              from: data['from'] as int,
              nickname: data['nickname'] as String? ?? '',
              avatar: data['avatar'] as String? ?? '',
              message: data['message'] as String? ?? '',
              timestamp: data['timestamp'] as int? ?? 0,
            ),
          );
          break;

        case 'chat-error':
          _onChatError.add(data['message'] as String? ?? '');
          break;

        case 'offline-message':
          _onOfflineMessage.add(
            ChatMessageData(
              from: data['from'] as int,
              nickname: data['nickname'] as String? ?? '',
              avatar: data['avatar'] as String? ?? '',
              message: data['message'] as String? ?? '',
              timestamp: data['timestamp'] as int? ?? 0,
            ),
          );
          break;

        // ---- WebRTC 房间 ----
        case 'room-users':
          final roomId = data['roomId'] as String? ?? '';
          final users =
              (data['users'] as List<dynamic>?)
                  ?.map((e) => (e as Map<String, dynamic>)['userId'] as int)
                  .toList() ??
              [];
          _onRoomUsers.add(RoomUsersData(roomId: roomId, users: users));
          break;

        case 'peer-ready':
          final prRoomId = data['roomId'] as String? ?? '';
          final peers =
              (data['peers'] as List<dynamic>?)
                  ?.map((e) => (e as Map<String, dynamic>)['userId'] as int)
                  .toList() ??
              [];
          _onPeerReady.add(PeerReadyData(roomId: prRoomId, peers: peers));
          break;

        // ---- WebRTC 信令 ----
        case 'offer':
          _onOffer.add(
            SdpData(
              from: data['from'] as int,
              sdp: data['sdp'] as String? ?? '',
            ),
          );
          break;

        case 'answer':
          _onAnswer.add(
            SdpData(
              from: data['from'] as int,
              sdp: data['sdp'] as String? ?? '',
            ),
          );
          break;

        case 'ice-candidate':
          _onIceCandidate.add(
            IceData(
              from: data['from'] as int,
              candidate: data['candidate'] as String? ?? '',
            ),
          );
          break;

        case 'call-ended':
          _onCallEnded.add(data['from'] as int? ?? 0);
          break;

        // ---- 视频通话邀请 ----
        case 'video-call-invite':
          _onVideoCallInvite.add(
            VideoCallInviteData(
              from: data['from'] as int,
              nickname: data['nickname'] as String? ?? '',
              avatar: data['avatar'] as String? ?? '',
              roomId: data['roomId'] as String? ?? '',
            ),
          );
          break;

        case 'video-call-accept':
          _onVideoCallAccept.add(
            VideoCallAcceptData(
              from: data['from'] as int,
              roomId: data['roomId'] as String? ?? '',
            ),
          );
          break;

        case 'video-call-reject':
          _onVideoCallReject.add(
            VideoCallRejectData(
              from: data['from'] as int,
              roomId: data['roomId'] as String? ?? '',
            ),
          );
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

  /// 处理收到的聊天消息：写入数据库（方案A）
  /// UI 更新由 ConsumerListController 通过 onChatMessage stream 驱动
  void _handleIncomingMessage(ChatMessageData data) {
    debugPrint(
      '[WS] 收到消息 from=${data.from} msg=${data.message}',
    );

    final db = ChatDatabase.to;
    final peerId = data.from;

    // 写入数据库（方案A：直接用 peerId，无 conversations 表）
    final msg = ChatMessage(
      type: ChatMsgType.text,
      isMe: false,
      content: data.message,
      time: _formatTime(DateTime.now()),
    );
    db.insertMessage(peerId, msg).catchError((e, stack) {
      debugPrint('[WS] 写入数据库失败: $e\n$stack');
      return -1;
    });

    // 如果当前不在聊天页，弹 SnackBar 通知
    if (Get.currentRoute != Routes.chat) {
      Get.snackbar(
        data.nickname,
        data.message,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        onTap: (snack) {
          Get.closeCurrentSnackbar();
          Get.toNamed(
            Routes.chat,
            arguments: {
              'peerUserId': data.from,
              'peerName': data.nickname,
              'peerAvatar': data.avatar,
            },
          );
        },
      );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }

  @override
  void onClose() {
    disconnect();
    _onChatMessage.close();
    _onChatError.close();
    _onKicked.close();
    _onOfflineMessage.close();
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/config/base_url.dart';

/// 直播间在线观众信息
class LiveViewerData {
  final int userId;
  final String nickname;
  final String avatar;

  LiveViewerData({
    required this.userId,
    this.nickname = '',
    this.avatar = '',
  });

  factory LiveViewerData.fromJson(Map<String, dynamic> json) {
    return LiveViewerData(
      userId: json['userId'] as int,
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

/// 直播间新评论数据
class LiveCommentData {
  final int id;
  final int userId;
  final String nickname;
  final String avatar;
  final String message;
  final String createdAt;

  LiveCommentData({
    required this.id,
    required this.userId,
    this.nickname = '',
    this.avatar = '',
    required this.message,
    required this.createdAt,
  });
}

/// 直播间新礼物数据
class LiveGiftData {
  final int id;
  final int senderId;
  final String senderNickname;
  final String senderAvatar;
  final String giftName;
  final String giftIcon;
  final String lottiePath;
  final String createdAt;

  LiveGiftData({
    required this.id,
    required this.senderId,
    this.senderNickname = '',
    this.senderAvatar = '',
    required this.giftName,
    this.giftIcon = '',
    this.lottiePath = '',
    required this.createdAt,
  });
}

/// 直播间 WebSocket 客户端
///
/// 连接到 live-ws 服务 (ws://host:8087)
/// 独立于 ConsumerWsClient（聊天/WebRTC 的 8086）
class LiveWsClient extends GetxService {
  WebSocket? _ws;
  bool _connected = false;
  // ignore: unused_field — tracked for future reconnection use
  String? _currentRoomId;

  /// 用于等待认证完成的 Completer
  Completer<void>? _authCompleter;

  Timer? _heartbeatTimer;

  // ===================== Rx 响应式状态 =====================

  final isConnected = false.obs;
  final isAuthenticated = false.obs;

  /// 当前房间的在线观众列表
  final viewers = <LiveViewerData>[].obs;

  /// 当前在线人数
  final viewerCount = 0.obs;

  // ===================== Stream 控制器 =====================

  final _onRoomJoined = StreamController<Map<String, dynamic>>.broadcast();
  final _onViewerJoined = StreamController<LiveViewerData>.broadcast();
  final _onViewerLeft = StreamController<int>.broadcast();
  final _onViewerList = StreamController<List<LiveViewerData>>.broadcast();
  final _onNewComment = StreamController<LiveCommentData>.broadcast();
  final _onNewGift = StreamController<LiveGiftData>.broadcast();
  final _onAnnouncementUpdated = StreamController<String>.broadcast();
  final _onLiveStarted = StreamController<String>.broadcast();
  final _onLiveEnded = StreamController<String>.broadcast();
  final _onError = StreamController<String>.broadcast();

  // ===================== 公开 Stream =====================

  Stream<Map<String, dynamic>> get onRoomJoined => _onRoomJoined.stream;
  Stream<LiveViewerData> get onViewerJoined => _onViewerJoined.stream;
  Stream<int> get onViewerLeft => _onViewerLeft.stream;
  Stream<List<LiveViewerData>> get onViewerList => _onViewerList.stream;
  Stream<LiveCommentData> get onNewComment => _onNewComment.stream;
  Stream<LiveGiftData> get onNewGift => _onNewGift.stream;
  Stream<String> get onAnnouncementUpdated => _onAnnouncementUpdated.stream;
  Stream<String> get onLiveStarted => _onLiveStarted.stream;
  Stream<String> get onLiveEnded => _onLiveEnded.stream;
  Stream<String> get onError => _onError.stream;

  // ===================== 连接 / 断开 =====================

  Future<void> connect() async {
    final box = GetStorage();
    final token = box.read<String>(BaseUrl.tokenKey) ?? '';
    if (token.isEmpty) {
      _onError.add('请先登录');
      return;
    }

    if (_connected) {
      disconnect();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 创建新的 auth completer
    _authCompleter = Completer<void>();

    final url = BaseUrl.liveWsHost();
    try {
      _ws = await WebSocket.connect(url);
      _connected = true;
      isConnected.value = true;

      _ws!.listen(
        (data) => _handleMessage(data as String),
        onError: (error) {
          debugPrint('[LiveWS] 错误: $error');
          _onError.add('连接错误: $error');
          _resetState();
        },
        onDone: () {
          debugPrint('[LiveWS] 连接关闭');
          _resetState();
        },
      );

      _startHeartbeat();
      _send('auth', {'token': GetStorage().read<String>('access_token') ?? ''});
    } catch (e) {
      _authCompleter?.completeError(e);
      _authCompleter = null;
      _connected = false;
      isConnected.value = false;
      _onError.add('连接失败: $e');
    }
  }

  /// 等待认证完成（超时 10 秒）
  Future<bool> waitForAuth() async {
    if (isAuthenticated.value) return true;
    if (_authCompleter == null) return false;
    try {
      await _authCompleter!.future.timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _currentRoomId = null;
    _ws?.close();
    _resetState();
  }

  void _resetState() {
    _authCompleter?.completeError('disconnected');
    _authCompleter = null;
    _connected = false;
    isConnected.value = false;
    isAuthenticated.value = false;
    viewers.clear();
    viewerCount.value = 0;
  }

  // ===================== 直播间操作 =====================

  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    _send('join-room', {'roomId': roomId});
  }

  void leaveRoom(String roomId) {
    _currentRoomId = null;
    _send('leave-room', {'roomId': roomId});
  }

  void sendComment(String roomId, String message) {
    _send('send-comment', {'roomId': roomId, 'message': message});
  }

  void sendGift(String roomId, String giftName, String giftIcon, String lottiePath) {
    _send('send-gift', {
      'roomId': roomId,
      'giftName': giftName,
      'giftIcon': giftIcon,
      'lottiePath': lottiePath,
    });
  }

  void startLive(String roomId) {
    _currentRoomId = roomId;
    _send('start-live', {'roomId': roomId});
  }

  void endLive(String roomId) {
    _send('end-live', {'roomId': roomId});
  }

  void updateAnnouncement(String roomId, String announcement) {
    _send('update-announcement', {'roomId': roomId, 'announcement': announcement});
  }

  void getOnlineUsers(String roomId) {
    _send('get-online-users', {'roomId': roomId});
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
      debugPrint('[LiveWS] 收到: $event');

      switch (event) {
        case 'auth-success':
          isAuthenticated.value = true;
          _authCompleter?.complete();
          _authCompleter = null;
          debugPrint('[LiveWS] 认证成功');
          break;

        case 'auth-error':
          isAuthenticated.value = false;
          _onError.add(data['message'] as String? ?? '认证失败');
          break;

        case 'kicked':
          _onError.add(data['message'] as String? ?? '账号在其他设备登录');
          disconnect();
          break;

        case 'room-joined':
          viewers.clear();
          final vList = (data['viewers'] as List<dynamic>?)
                  ?.map((e) => LiveViewerData.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          viewers.addAll(vList);
          viewerCount.value = data['viewerCount'] as int? ?? vList.length;
          _onRoomJoined.add(data);
          break;

        case 'viewer-joined':
          final viewer = LiveViewerData.fromJson(data);
          viewers.addIf(
            !viewers.any((v) => v.userId == viewer.userId),
            viewer,
          );
          viewerCount.value = viewers.length;
          _onViewerJoined.add(viewer);
          break;

        case 'viewer-left':
          final leftUserId = data['userId'] as int?;
          if (leftUserId != null) {
            viewers.removeWhere((v) => v.userId == leftUserId);
            viewerCount.value = viewers.length;
            _onViewerLeft.add(leftUserId);
          }
          break;

        case 'viewer-list':
          viewers.clear();
          final vList = (data['viewers'] as List<dynamic>?)
                  ?.map((e) => LiveViewerData.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          viewers.addAll(vList);
          viewerCount.value = data['viewerCount'] as int? ?? vList.length;
          _onViewerList.add(viewers.toList());
          break;

        case 'new-comment':
          _onNewComment.add(LiveCommentData(
            id: data['id'] as int,
            userId: data['userId'] as int,
            nickname: data['nickname'] as String? ?? '',
            avatar: data['avatar'] as String? ?? '',
            message: data['message'] as String? ?? '',
            createdAt: data['createdAt'] as String? ?? '',
          ));
          break;

        case 'new-gift':
          _onNewGift.add(LiveGiftData(
            id: data['id'] as int,
            senderId: data['senderId'] as int,
            senderNickname: data['senderNickname'] as String? ?? '',
            senderAvatar: data['senderAvatar'] as String? ?? '',
            giftName: data['giftName'] as String? ?? '',
            giftIcon: data['giftIcon'] as String? ?? '',
            lottiePath: data['lottiePath'] as String? ?? '',
            createdAt: data['createdAt'] as String? ?? '',
          ));
          break;

        case 'announcement-updated':
          _onAnnouncementUpdated.add(data['announcement'] as String? ?? '');
          break;

        case 'live-started':
          _onLiveStarted.add(data['roomId'] as String? ?? '');
          break;

        case 'live-ended':
          _onLiveEnded.add(data['roomId'] as String? ?? '');
          break;

        case 'pong':
          break;

        default:
          debugPrint('[LiveWS] 未处理事件: $event');
      }
    } catch (e) {
      debugPrint('[LiveWS] 消息解析错误: $e');
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
    _onRoomJoined.close();
    _onViewerJoined.close();
    _onViewerLeft.close();
    _onViewerList.close();
    _onNewComment.close();
    _onNewGift.close();
    _onAnnouncementUpdated.close();
    _onLiveStarted.close();
    _onLiveEnded.close();
    _onError.close();
    super.onClose();
  }
}

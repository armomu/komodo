import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

/// WebSocket 信令客户端——连接 NestJS WebRTC 信令服务器。
///
/// 地址：ws://{host}:3002
/// 协议：{ event: String, data: Object }
class SignalingClient extends GetxService {
  WebSocket? _ws;
  bool _connected = false;

  final _onConnected = StringController();
  final _onUserJoined = StringController();
  final _onUserLeft = StringController();
  final _onRoomUsers = RoomUsersController();
  final _onOffer = SdpController();
  final _onAnswer = SdpController();
  final _onIceCandidate = IceCandidateController();
  final _onCallEnded = StringController();
  final _onError = StringController();

  // ============ 公开流 ============

  /// 连接成功，包含分配的 uid
  Stream<String> get onConnected => _onConnected.stream;

  /// 新用户加入房间
  Stream<String> get onUserJoined => _onUserJoined.stream;

  /// 用户离开房间
  Stream<String> get onUserLeft => _onUserLeft.stream;

  /// 房间用户列表
  Stream<({String roomId, List<String> users})> get onRoomUsers =>
      _onRoomUsers.stream;

  /// 收到 SDP Offer（from, sdp）
  Stream<({String from, String sdp})> get onOffer => _onOffer.stream;

  /// 收到 SDP Answer（from, sdp）
  Stream<({String from, String sdp})> get onAnswer => _onAnswer.stream;

  /// 收到 ICE Candidate（from, candidate）
  Stream<({String from, String candidate})> get onIceCandidate =>
      _onIceCandidate.stream;

  /// 对端挂断
  Stream<String> get onCallEnded => _onCallEnded.stream;

  /// 错误消息
  Stream<String> get onError => _onError.stream;

  bool get isConnected => _connected;

  // ============ 连接 ============

  Future<void> connect(String url) async {
    try {
      _ws = await WebSocket.connect(url);
      _connected = true;

      _ws!.listen(
        (data) => _handleMessage(data as String),
        onError: (error) {
          _connected = false;
          _onError.add('WebSocket 错误: $error');
        },
        onDone: () {
          _connected = false;
        },
      );

      // 心跳保活
      _startHeartbeat();
    } catch (e) {
      _connected = false;
      _onError.add('连接失败: $e');
      rethrow;
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _ws?.close();
    _ws = null;
    _connected = false;
  }

  // ============ 发送消息 ============

  void joinRoom(String roomId, String uid) {
    _send('join-room', {'roomId': roomId, 'uid': uid});
  }

  void leaveRoom(String roomId) {
    _send('leave-room', {'roomId': roomId});
  }

  void sendOffer(String to, String sdp) {
    // roomId 由业务层携带
    _send('offer', {'to': to, 'sdp': sdp});
  }

  void sendAnswer(String to, String sdp) {
    _send('answer', {'to': to, 'sdp': sdp});
  }

  void sendIceCandidate(String to, String candidate) {
    _send('ice-candidate', {'to': to, 'candidate': candidate});
  }

  void sendEndCall(String to) {
    _send('end-call', {'to': to});
  }

  // ============ 内部 ============

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

      switch (event) {
        case 'connected':
          final uid = data['uid'] as String? ?? '';
          _onConnected.add(uid);
          break;
        case 'user-joined':
          _onUserJoined.add(data['uid'] as String? ?? '');
          break;
        case 'user-left':
          _onUserLeft.add(data['uid'] as String? ?? '');
          break;
        case 'room-users':
          final roomId = data['roomId'] as String? ?? '';
          final users = (data['users'] as List<dynamic>?)
                  ?.map((e) => (e as Map<String, dynamic>)['uid'] as String)
                  .toList() ??
              [];
          _onRoomUsers.add((roomId: roomId, users: users));
          break;
        case 'offer':
          _onOffer.add((
            from: data['from'] as String? ?? '',
            sdp: data['sdp'] as String? ?? '',
          ));
          break;
        case 'answer':
          _onAnswer.add((
            from: data['from'] as String? ?? '',
            sdp: data['sdp'] as String? ?? '',
          ));
          break;
        case 'ice-candidate':
          _onIceCandidate.add((
            from: data['from'] as String? ?? '',
            candidate: data['candidate'] as String? ?? '',
          ));
          break;
        case 'call-ended':
          _onCallEnded.add(data['from'] as String? ?? '');
          break;
        default:
          break;
      }
    } catch (e) {
      // 忽略解析错误
    }
  }

  // ============ 心跳 ============

  Timer? _heartbeatTimer;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send('ping', {});
    });
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}

// ==================== StreamController 便捷封装 ====================

class StringController {
  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;
  void add(String value) => _controller.add(value);
}

class RoomUsersController {
  final _controller =
      StreamController<({String roomId, List<String> users})>.broadcast();
  Stream<({String roomId, List<String> users})> get stream => _controller.stream;
  void add(({String roomId, List<String> users}) value) => _controller.add(value);
}

class SdpController {
  final _controller =
      StreamController<({String from, String sdp})>.broadcast();
  Stream<({String from, String sdp})> get stream => _controller.stream;
  void add(({String from, String sdp}) value) => _controller.add(value);
}

class IceCandidateController {
  final _controller =
      StreamController<({String from, String candidate})>.broadcast();
  Stream<({String from, String candidate})> get stream => _controller.stream;
  void add(({String from, String candidate}) value) => _controller.add(value);
}

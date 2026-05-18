# Komodo WebRTC 模块详细实现文档

## 📁 项目结构概览

```
lib/
├── main.dart                                    # 全局初始化入口
├── pages/
│   ├── webrtc/                                  # 🔹 独立WebRTC模块（旧版）
│   │   ├── models/
│   │   │   ├── call_state.dart                 # 通话状态枚举
│   │   │   └── signaling_message.dart          # 信令消息模型
│   │   ├── pages/
│   │   │   ├── call_entry_page.dart            # 通话入口页面
│   │   │   └── video_call_page.dart            # 视频通话页面
│   │   └── services/
│   │       ├── signaling_client.dart           # 独立信令客户端
│   │       └── webrtc_controller.dart          # WebRTC控制器
│   └── message/                                 # 🔹 集成WebRTC模块（新版）
│       ├── controllers/
│       │   └── video_call_controller.dart       # 集成版控制器
│       └── pages/
│           └── video_call_page.dart             # 集成版页面
├── services/
│   └── consumer_ws_client.dart                  # 🔹 统一WebSocket客户端
└── routes/
    └── app_routes.dart                          # 路由配置
```

---

## 🎯 核心概念：WebRTC 信令流程

在了解代码实现之前，需要理解WebRTC的核心挑战：

> **WebRTC本身无法直接建立P2P连接**，因为双方都不知道对方的公网IP和端口。
> 这就需要**信令服务器**来帮助双方交换"简历"（SDP）和"联系方式"（ICE Candidate）。

```
┌─────────┐  WebSocket   ┌────────────┐  WebSocket   ┌─────────┐
│ 用户 A  │◄────────────►│ 信令服务器 │◄────────────►│ 用户 B  │
└────┬────┘              └────────────┘              └────┬────┘
     │                                                   │
     │  1. join-room                                     │
     │───────────────────────────────────────────────────►
     │  2. user-joined                                   │
     │◄───────────────────────────────────────────────────
     │                                                   │
     │  3. offer (SDP)                                   │
     │───────────────────────────────────────────────────►
     │                                                   │
     │  4. answer (SDP)                                  │
     │◄───────────────────────────────────────────────────
     │                                                   │
     │  5. ice-candidate (NAT穿透信息)                    │
     │◄───────────────────────────────────────────────────
     │───────────────────────────────────────────────────►
     │                                                   │
     │  ════════════════════════════════════════════════  │
     │              P2P 直连建立成功                      │
     │  ════════════════════════════════════════════════  │
     │                                                   │
     │  6. 音视频流直接传输（P2P，无需服务器中转）           │
     └───────────────────────────────────────────────────┘
```

---

## 📦 第一步：依赖配置 (pubspec.yaml)

```yaml
dependencies:
  flutter_webrtc: ^1.4.1    # WebRTC核心库
  get: ^4.6.6               # 状态管理
  web_socket_channel: ^2.4.0  # WebSocket支持
```

---

## 📊 第二步：数据模型定义

### 2.1 通话状态枚举 (`call_state.dart`)

```dart
enum CallState {
  idle,        // 空闲
  calling,     // 呼叫中
  incoming,    // 收到来电
  connecting,   // 正在连接
  connected,    // 已连接
  ended,        // 已挂断
  error,        // 错误
  waiting,      // 等待对方接受
}
```

**设计意图**：通过枚举清晰表达通话的每个阶段，UI层可以根据状态显示不同的界面。

### 2.2 信令消息模型 (`signaling_message.dart`)

```dart
class SignalingMessage {
  final String event;           // 事件类型
  final Map<String, dynamic> data;  // 消息数据

  // JSON编解码
  factory SignalingMessage.fromJson(String raw) {...}
  String toJson() => jsonEncode({'event': event, 'data': data});
}
```

**WebSocket协议格式**：`{ "event": String, "data": Object }`

**消息类型一览**：

| 消息类型 | 方向 | 描述 | 数据字段 |
|---------|------|------|---------|
| `connected` | 服务端→客户端 | 连接成功 | `{uid: String}` |
| `join-room` | 客户端→服务端 | 加入房间 | `{roomId, uid}` |
| `leave-room` | 客户端→服务端 | 离开房间 | `{roomId}` |
| `user-joined` | 服务端→客户端 | 用户加入 | `{uid}` |
| `user-left` | 服务端→客户端 | 用户离开 | `{uid}` |
| `room-users` | 服务端→客户端 | 房间用户列表 | `{roomId, users[]}` |
| `peer-ready` | 服务端→客户端 | 双方就绪 | `{roomId, peers[]}` |
| `offer` | 双向 | SDP Offer | `{from, sdp}` |
| `answer` | 双向 | SDP Answer | `{from, sdp}` |
| `ice-candidate` | 双向 | ICE候选 | `{from, candidate}` |
| `call-ended` | 双向 | 通话结束 | `{from}` |

---

## 🔌 第三步：WebSocket信令客户端实现

### 3.1 独立信令客户端 (`signaling_client.dart`)

这是一个 **GetxService**（全局单例），管理WebSocket连接：

```dart
class SignalingClient extends GetxService {
  WebSocket? _ws;
  String _currentRoomId = '';

  // ============ 事件流 ============
  // 使用广播StreamController，每个事件一个流
  final _onConnected = StringController();
  final _onUserJoined = StringController();
  final _onOffer = SdpController();        // ({from, sdp})
  final _onAnswer = SdpController();
  final _onIceCandidate = IceCandidateController();
  // ...
}
```

**核心方法**：

```dart
// 连接信令服务器
Future<void> connect(String url) async {
  _ws = await WebSocket.connect(url);
  _ws!.listen(
    (data) => _handleMessage(data as String),
    onError: (error) => _onError.add('WebSocket 错误: $error'),
    onDone: () => _connected = false,
  );
  _startHeartbeat();  // 30秒心跳保活
}

// 加入房间
void joinRoom(String roomId, String uid) {
  _currentRoomId = roomId;
  _send('join-room', {'roomId': roomId, 'uid': uid});
}

// 发送Offer/Answer/ICE
void sendOffer(String to, String sdp) {
  _send('offer', {'roomId': _currentRoomId, 'to': to, 'sdp': sdp});
}
```

**消息分发**：

```dart
void _handleMessage(String raw) {
  final map = jsonDecode(raw);
  final event = map['event'];
  final data = map['data'];

  switch (event) {
    case 'offer':
      _onOffer.add((from: data['from'], sdp: data['sdp']));
      break;
    case 'peer-ready':
      _onPeerReady.add((roomId: data['roomId'], peers: [...]));
      break;
    // ...
  }
}
```

### 3.2 统一WebSocket客户端 (`consumer_ws_client.dart`)

与独立版不同的是，这个客户端集成了多种功能：

```dart
class ConsumerWsClient extends GetxService {
  // ============ 聊天功能 ============
  final isConnected = false.obs;
  final onlineUsers = <OnlineUser>[].obs;

  // ============ WebRTC功能 ============
  void sendVideoCallInvite(int toUserId, String roomId);
  void sendVideoCallAccept(int toUserId, String roomId);
  void sendVideoCallReject(int toUserId, String roomId);

  // 还支持：auth、online-list、chat-message、join-room、offer/answer/ice...
}
```

---

## 📞 第四步：WebRTC控制器实现

### 4.1 控制器初始化 (`webrtc_controller.dart`)

```dart
class WebrtcController extends GetxController {
  late final SignalingClient _signaling;

  // WebRTC核心对象
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 视频渲染器
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  // 可观察状态
  final callState = CallState.idle.obs;
  final isCameraOn = true.obs;
  final isMicOn = true.obs;
}
```

### 4.2 发起呼叫流程 (`startCall`)

```dart
Future<void> startCall({
  required String serverUrl,
  required String roomId,
  required String myUid,
}) async {
  // 1️⃣ 连接信令服务器
  await _signaling.connect(serverUrl);

  // 2️⃣ 加入房间
  _signaling.joinRoom(roomId, myUid);

  // 3️⃣ 获取本地媒体（摄像头+麦克风）
  await _getLocalMedia();

  // 4️⃣ 创建PeerConnection
  await _createPeerConnection();

  // 5️⃣ 等待peer-ready事件自动触发协商
  callState.value = CallState.connecting;
}
```

### 4.3 获取本地媒体

```dart
Future<void> _getLocalMedia() async {
  final constraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',  // 前置摄像头
      'width': {'ideal': 640},
      'height': {'ideal': 480},
    },
  };

  _localStream = await navigator.mediaDevices.getUserMedia(constraints);
  localRenderer.srcObject = _localStream;  // 绑定到本地预览
}
```

### 4.4 创建PeerConnection

```dart
Future<void> _createPeerConnection() async {
  // STUN服务器配置（用于NAT穿透）
  final config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  _pc = await createPeerConnection(config);

  // 添加本地流到连接
  for (final track in _localStream!.getTracks()) {
    await _pc!.addTrack(track, _localStream!);
  }

  // 设置回调
  _pc!.onIceCandidate = (candidate) {
    // 当收集到ICE候选时，发送给对端
    _signaling.sendIceCandidate(_peerUid, jsonEncode(candidate.toMap()));
  };

  _pc!.onTrack = (event) {
    // 收到远端视频流
    _remoteStream = event.streams[0];
    remoteRenderer.srcObject = _remoteStream;
    callState.value = CallState.connected;
  };
}
```

### 4.5 SDP协商流程

**谁发Offer？谁发Answer？**

```dart
void _handlePeerReady(List<String> peers) {
  // 按UID字典序排序，较小的发Offer
  final sorted = List<String>.from(peers)..sort();
  final iAmInitiator = sorted.first == _myUid;

  if (iAmInitiator) {
    _createAndSendOffer();
  }
  // 非发起方等待对端发来的Offer
}
```

**创建并发送Offer**：

```dart
Future<void> _createAndSendOffer() async {
  final session = await _pc!.createOffer();
  await _pc!.setLocalDescription(session);

  _signaling.sendOffer(_peerUid, session.sdp!);
}
```

**处理收到的Offer并回复Answer**：

```dart
Future<void> _handleOfferReceived(String fromUid, String sdp) async {
  _peerUid = fromUid;

  // 设置远端SDP
  await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

  // 创建并发送Answer
  final answer = await _pc!.createAnswer();
  await _pc!.setLocalDescription(answer);
  _signaling.sendAnswer(_peerUid, answer.sdp!);
}
```

### 4.6 ICE候选处理

```dart
Future<void> _handleIceCandidateReceived(String candidate) async {
  final map = jsonDecode(candidate);
  final iceCandidate = RTCIceCandidate(
    map['candidate'],
    map['sdpMid'],
    map['sdpMLineIndex'] as int?,
  );
  await _pc?.addCandidate(iceCandidate);
}
```

---

## 🎨 第五步：UI页面实现

### 5.1 通话入口页面 (`call_entry_page.dart`)

```dart
class CallEntryPage extends StatefulWidget {
  // 输入：服务器地址、房间号、昵称
  final _serverController = TextEditingController(text: 'ws://192.168.1.38:3002');
  final _roomController = TextEditingController(text: 'room-001');
  final _nameController = TextEditingController(text: 'User_${时间戳}');
}

Future<void> _joinRoom() async {
  // 1. 初始化控制器（permanent: 持久化）
  final controller = Get.put(WebrtcController(), permanent: true);
  await controller.initRenderers();

  // 2. 跳转到通话页面
  await Get.to(
    () => VideoCallPage(
      serverUrl: server,
      roomId: room,
      myUid: name,
    ),
  );

  // 3. 回来时清理
  Get.delete<WebrtcController>(force: true);
}
```

### 5.2 视频通话页面 (`video_call_page.dart`)

```dart
class VideoCallPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _controller = Get.find<WebrtcController>();

    // 启动呼叫
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startCall(
        serverUrl: widget.serverUrl,
        roomId: widget.roomId,
        myUid: widget.myUid,
      );
    });
  }
}
```

**UI布局**：

```dart
Stack(
  children: [
    // 远端视频（主画面）
    Positioned.fill(child: _buildRemoteVideo()),

    // 本地视频（画中画）
    Positioned(
      top: 12, right: 12,
      width: 100, height: 150,
      child: _buildLocalVideo(),
    ),

    // 顶部信息栏
    Positioned(top: 12, left: 12, child: _buildTopBar()),

    // 状态覆盖层（等待/呼入）
    if (state == CallState.calling || state == CallState.incoming)
      Positioned.fill(child: _buildCallingOverlay(state)),

    // 底部控制栏
    Positioned(left: 0, right: 0, bottom: 40, child: _buildControls()),
  ],
)
```

**本地预览镜像**：

```dart
RTCVideoView(
  _controller.localRenderer,
  mirror: true,  // 前置摄像头需要镜像
)
```

---

## 📱 第六步：路由配置

```dart
class AppPages {
  static final List<GetPage> routes = [
    // 独立WebRTC入口
    GetPage(
      name: Routes.webrtcCall,
      page: () => const CallEntryPage(),  // lib/pages/webrtc/pages/call_entry_page.dart
      transition: Transition.downToUp,
    ),

    // 集成WebRTC入口
    GetPage(
      name: Routes.chatVideoCall,
      page: () => const VideoCallPage(),  // lib/pages/message/pages/video_call_page.dart
      transition: Transition.downToUp,
    ),
  ];
}
```

---

## 🚀 第七步：全局初始化

```dart
void main() async {
  await GetStorage.init();

  // 注入全局服务
  Get.put(ApiService());
  Get.put(UserController());
  Get.put(ThemeController());
  Get.put(MusicPlayerController(), permanent: true);
  Get.put(ChatDatabase());

  // WebRTC信令客户端（全局单例）
  Get.put(SignalingClient());           // 独立版
  Get.put(ConsumerWsClient());         // 统一版

  runApp(const MyApp());
}
```

---

## 🔄 完整通话流程时序图

```
用户A（发起方）                        信令服务器                        用户B（接收方）
    │                                    │                                  │
    │  1. startCall()                   │                                  │
    │  - connect()                       │                                  │
    │  - joinRoom()                      │                                  │
    │───────────────────────────────────►│                                  │
    │                                    │                                  │
    │                      2. user-joined(room-users)                     │
    │◄───────────────────────────────────│                                  │
    │                                    │                                  │
    │                                    │    用户B也加入同一房间             │
    │                                    │◄──────────────────────────────────│
    │                                    │                                  │
    │                      3. peer-ready (双方就绪)                         │
    │◄───────────────────────────────────│                                  │
    │───────────────────────────────────►│ (转发给B)                         │
    │                                    │                                  │
    │  4. createOffer()                  │                                  │
    │  5. setLocalDescription()          │                                  │
    │  6. sendOffer(sdp)                 │                                  │
    │───────────────────────────────────►│ 转发offer                         │
    │                                    │─────────────────────────────────►│
    │                                    │                                  │
    │                                    │    7. setRemoteDescription(offer) │
    │                                    │    8. createAnswer()              │
    │                                    │    9. setLocalDescription()       │
    │◄───────────────────────────────────│◄───────────────────────────────────│
    │◄───────────────────────────────────│ sendAnswer(sdp)                   │
    │◄───────────────────────────────────│ 转发answer                        │
    │                                    │                                  │
    │  10. setRemoteDescription(answer)  │                                  │
    │                                    │                                  │
    │  11. ICE候选交换...                │                                  │
    │◄───────────────────────────────────►│◄─────────────────────────────────►│
    │                                    │                                  │
    │  ═══════════════════════════════════════════════════                 │
    │                    P2P直连建立成功                                      │
    │  ═══════════════════════════════════════════════════                 │
    │                                    │                                  │
    │  12. 音视频流直接传输（P2P）                                            │
    └────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 集成版 vs 独立版对比

| 特性 | 独立版 (SignalingClient) | 集成版 (ConsumerWsClient) |
|------|-------------------------|-------------------------|
| **适用场景** | 测试/演示 | 真实用户间通话 |
| **服务器** | ws://host:3002 (专用信令) | ws://host:8085 (统一后端) |
| **信令功能** | 纯WebRTC信令 | 信令+聊天+邀请 |
| **用户标识** | 字符串UID | 整数userId |
| **控制器** | WebrtcController | VideoCallController |
| **页面** | CallEntryPage + VideoCallPage | VideoCallPage |

---

## ⚠️ 注意事项

1. **STUN服务器**：使用Google公共STUN服务器，适合开发测试。生产环境建议使用TURN服务器处理无法P2P的情况。

2. **权限申请**：`flutter_webrtc`需要相机和麦克风权限，Android需要配置 `AndroidManifest.xml`：
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
   ```

3. **WebRTC坑点**：
   - Unified Plan vs Plan B：移动端推荐Unified Plan，使用 `addTrack` 而非 `addStream`
   - Android 10+ 需要 `android:usesCleartextTraffic="true"`（测试用）

4. **清理资源**：`onClose` 中必须释放所有资源（MediaStream、RTCPeerConnection、RTCVideoRenderer）

---

## 🎓 学习建议

1. 先理解WebRTC信令流程，这是核心
2. 从 `call_state.dart` 理解状态机
3. 看 `signaling_client.dart` 理解WebSocket通信
4. 看 `webrtc_controller.dart` 理解核心逻辑
5. 最后看UI页面理解如何与控制器交互

---

## 🔬 深入讲解：SDP 交换 + ICE NAT穿透 → P2P连接全过程

> 上面的流程图展示的是"宏观步骤"，这一节从底层机制出发，解释 **为什么要做这些、每一步发生了什么**。

---

### 一、SDP 是什么？为什么需要它？

**SDP（Session Description Protocol，会话描述协议）** 本质上是一份"能力声明书"：

```
"我支持这些编解码器，我的音频格式是这样的，我的视频格式是这样的，
我愿意用这个端口接收数据……"
```

一份真实的 SDP 长这样（节选）：

```
v=0
o=- 4611731400430051336 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0 1                     ← 音视频捆绑传输
a=msid-semantic: WMS

m=audio 9 UDP/TLS/RTP/SAVPF 111 103   ← 音频轨道
a=rtpmap:111 opus/48000/2             ← Opus编解码器，48kHz，2声道
a=rtpmap:103 ISAC/16000               ← 备选：ISAC编解码器

m=video 9 UDP/TLS/RTP/SAVPF 96 97     ← 视频轨道
a=rtpmap:96 VP8/90000                 ← VP8编解码器
a=rtpmap:97 H264/90000                ← 备选：H.264编解码器
a=fmtp:97 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f
```

**SDP 的关键信息**：
- 支持哪些音频/视频编解码器（opus / VP8 / H264）
- 采样率、声道数、帧率
- 是否支持 DTLS 加密
- BUNDLE 策略（音视频是否共用一个UDP端口）

---

### 二、Offer/Answer：SDP 如何交换？

#### 2.1 完整交换流程

```
用户A（发起方）                     信令服务器                     用户B（接收方）
     │                                  │                                │
     │  ① createOffer()                │                                │
     │  ─ 生成 SDP 描述 A 的能力        │                                │
     │                                  │                                │
     │  ② setLocalDescription(offerSDP) │                                │
     │  ─ 保存自己的SDP                  │                                │
     │  ─ 🔥 同时触发 ICE 候选收集 (重要!) │                                │
     │                                  │                                │
     │  ③ sendOffer(offerSDP) ─────────►│─────────────────────────────►│
     │                                  │                                │
     │                                  │  ④ setRemoteDescription(offerSDP)│
     │                                  │  ─ 保存 A 的能力描述              │
     │                                  │                                │
     │                                  │  ⑤ createAnswer()              │
     │                                  │  ─ 从 A 的能力里选双方都支持的     │
     │                                  │  ─ 生成 B 的 SDP（答案）          │
     │                                  │                                │
     │                                  │  ⑥ setLocalDescription(answerSDP)│
     │                                  │  ─ 🔥 同时触发 B 的 ICE 候选收集  │
     │                                  │                                │
     │◄─────────────────────────────────│◄────────────────────────────── │
     │  ⑦ setRemoteDescription(answerSDP)│                                │
     │  ─ 现在 A 知道了 B 的能力          │                                │
     │                                  │                                │
     │  ✅ 双方完成"协商"，知道用什么       │
     │     编解码器收发数据了！            │                                │
```

#### 2.2 关键代码 + 注释

```dart
// === 发起方（A）===
Future<void> _createAndSendOffer() async {
  // ① 创建 Offer：WebRTC 底层根据你添加的 Track 自动生成 SDP
  final offerSdp = await _pc!.createOffer({
    'offerToReceiveAudio': 1,
    'offerToReceiveVideo': 1,
  });

  // ② setLocalDescription 有两个副作用：
  //    a. 保存自己的 SDP（用于后续协商）
  //    b. ⚡ 立即触发 ICE 候选收集（onIceCandidate 开始回调）
  await _pc!.setLocalDescription(offerSdp);

  // ③ 通过信令服务器把 SDP 发给对方
  _signaling.sendOffer(_peerUid, offerSdp.sdp!);
}

// === 接收方（B）===
Future<void> _handleOfferReceived(String fromUid, String sdp) async {
  // ④ 设置远端（A）的 SDP，WebRTC 从中解析 A 的能力
  await _pc!.setRemoteDescription(
    RTCSessionDescription(sdp, 'offer'),
  );

  // ⑤ 创建 Answer：从 A 的能力里选双方都支持的，生成 B 的 SDP
  final answerSdp = await _pc!.createAnswer();

  // ⑥ 保存 + 触发 B 的 ICE 收集
  await _pc!.setLocalDescription(answerSdp);

  // ⑦ 发回给 A
  _signaling.sendAnswer(fromUid, answerSdp.sdp!);
}
```

#### 2.3 "协商"的本质

SDP 交换本质是双方在问：**"你支持什么？我支持什么？我们用哪个？"**

```
A 的 Offer SDP：
  视频支持：VP8, H264, VP9

B 的 Answer SDP：
  视频支持：VP8, H264
  ─→ 最终协商结果：使用 VP8（双方都支持的最优选择）
```

---

### 三、ICE 是什么？候选地址怎么收集？

**ICE（Interactive Connectivity Establishment，交互式连通性建立）** 解决的核心问题是：

> "我怎么找到能让对方连上我的地址？"

因为现实网络中，设备可能在：
- NAT 后面（家庭路由器）
- 公司防火墙后面
- 移动运营商的 CGNAT 后面（几千台设备共享一个公网 IP）

#### 3.1 三种候选地址类型

```
┌──────────────────────────────────────────────────────────────────────┐
│                          候选地址类型                                  │
├──────────────┬────────────────────────┬──────────────────────────────┤
│   类型        │       地址来源          │         适用场景               │
├──────────────┼────────────────────────┼──────────────────────────────┤
│ host         │ 设备本机的局域网 IP      │ 同一 WiFi 下直连（最快）         │
│              │ 例：192.168.1.100:56789 │                              │
├──────────────┼────────────────────────┼──────────────────────────────┤
│ srflx        │ STUN 服务器反射回来的   │ 不同网络但能 UDP 出去（大多数情况） │
│ (Server      │ 公网 IP + 端口          │                              │
│  Reflexive)  │ 例：121.42.xx.xx:12345  │                              │
├──────────────┼────────────────────────┼──────────────────────────────┤
│ relay        │ TURN 服务器的中继地址   │ UDP 被封锁时的最后手段（最慢）      │
│              │ 例：TURN服务器IP:端口    │                              │
└──────────────┴────────────────────────┴──────────────────────────────┘
```

#### 3.2 STUN 服务器工作原理（"镜子"原理）

```
用户A设备                          STUN服务器（公网）
  │                                     │
  │  你好，我是谁？（从 NAT 后发出请求）    │
  │────────────────────────────────────►│
  │                                     │  服务器看到的是 NAT 出口的公网 IP:端口
  │◄────────────────────────────────────│  "你的公网地址是 121.42.xx.xx:12345"
  │                                     │
  │  收到"反射候选地址"(srflx)：           │
  │  121.42.xx.xx:12345                 │
```

**代码中的 STUN 配置**：

```dart
final config = {
  'iceServers': [
    // 使用 Google 公共 STUN 服务器（免费，仅用于测试）
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    // ⚠️ 没有配置 TURN 服务器，对 UDP 被封锁的网络无效
  ],
};
```

#### 3.3 ICE 候选收集过程（触发时机）

```dart
// setLocalDescription 触发 ICE 收集
await _pc!.setLocalDescription(session); // ⚡ ICE 收集从这里开始

// 边收集边发送（Trickle ICE）
_pc!.onIceCandidate = (RTCIceCandidate candidate) {
  if (candidate.candidate != null) {
    // 每收集到一个候选地址，立刻通过信令服务器发给对方
    // 不等待全部收集完毕！这样可以更快建立连接
    _signaling.sendIceCandidate(_peerUid, jsonEncode({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    }));
  }
};
```

一个真实的 ICE Candidate 字符串：

```
candidate:1 1 UDP 2130706431 192.168.1.100 56789 typ host
           ─ ─ ─── ──────── ──────────── ───── ───────────
           │ │  协议  优先级   IP地址       端口  类型=本机
           │ component(1=RTP)
           foundation (标识符)

candidate:2 1 UDP 1694498815 121.42.10.20 12345 typ srflx raddr 192.168.1.100 rport 56789
                                                    ────────────────────────────────────
                                                    类型=STUN反射  真实IP:端口（NAT内部）
```

---

### 四、NAT 穿透：双方如何"打通"连接？

#### 4.1 NAT 是什么？为什么是障碍？

```
                     公网
                      │
               ┌──────┴──────┐
               │  路由器/NAT   │  ← 只有一个公网 IP
               │ 121.42.xx.xx │
               └──────┬──────┘
                      │ 局域网
            ┌─────────┴─────────┐
            │                   │
     192.168.1.100         192.168.1.101
       用户A的设备            用户B的设备
```

**NAT 的工作方式**：
- 出去的包：自动记录 `内网IP:端口 → 公网IP:端口` 映射
- 进来的包：只有"有记录的"包才放行，其他的直接丢弃

**问题**：B 想直接给 A 发包，但 A 的 NAT 没有 B 的记录 → 包被丢弃！

#### 4.2 UDP 打洞（Hole Punching）

ICE 通过以下方式"打洞"：

```
步骤1：A 向 B 的公网地址发一个探测包
  → A 的 NAT 记录了"我往 B 发过包了"
  → B 的 NAT 收到 A 的包，但此时还不认识 A → 丢弃（但没关系！）

步骤2：B 向 A 的公网地址发一个探测包
  → B 的 NAT 记录了"我往 A 发过包了"
  → A 的 NAT 收到 B 的包，检查记录："哦！我给 B 发过！放行！" ✅

步骤3：A 再向 B 发包
  → B 的 NAT 检查记录："哦！我给 A 发过！放行！" ✅

→ 双向通信建立！
```

**这就是为什么双方要互相发 ICE Candidate**：不仅是告知地址，更是为了触发 NAT 打洞。

#### 4.3 候选对连通性检查（Connectivity Check）

ICE 会尝试所有候选对（Candidate Pair），找出最优路径：

```
优先级从高到低：
1. host-host（同一局域网，最快）
2. srflx-srflx（UDP 打洞成功，正常 P2P）
3. relay-relay（TURN 中继，最慢但最稳定）

ICE 状态机：
  new → gathering → checking → connected → completed
                      │                       │
                  尝试所有候选对           找到最优路径
                  发 STUN Binding          冻结其他路径
                  Request/Response
```

**代码中接收并添加候选地址**：

```dart
Future<void> _handleIceCandidateReceived(String candidateJson) async {
  final map = jsonDecode(candidateJson);
  final iceCandidate = RTCIceCandidate(
    map['candidate'],      // 候选地址字符串
    map['sdpMid'],         // 媒体流标识（"0" 或 "1"）
    map['sdpMLineIndex'],  // 在 SDP 中的行索引
  );

  // 添加到 PeerConnection，WebRTC 内部会进行连通性检查
  await _pc?.addCandidate(iceCandidate);
}
```

---

### 五、ICE 完成后：DTLS 握手 + SRTP 加密

P2P 路径确定后，WebRTC **强制要求加密**，不加密的连接无法建立：

```
ICE 完成（找到最优路径）
     │
     ▼
DTLS 握手（基于 UDP 的 TLS）
  - 交换证书（SDP 里已经包含了指纹）
  - 协商加密参数
  - 约 1~2 次 RTT（几十毫秒）
     │
     ▼
SRTP 密钥派生（从 DTLS 主密钥衍生）
     │
     ▼
媒体流开始传输（SRTP 加密的音视频包）
```

**SDP 里的 DTLS 指纹**（提前告知对方用于验证）：

```
a=fingerprint:sha-256 8A:2E:F3:...:C9
a=setup:actpass    ← DTLS 角色（主动/被动/均可）
```

---

### 六、onTrack：连接成功的信号

```dart
_pc!.onTrack = (RTCTrackEvent event) {
  // 当远端媒体流到达时触发
  // 这意味着：
  //   1. ICE 连通性检查通过（找到了可用路径）
  //   2. DTLS 握手完成（加密建立）
  //   3. SRTP 媒体包开始流入
  if (event.streams.isNotEmpty) {
    _remoteStream = event.streams[0];
    remoteRenderer.srcObject = _remoteStream;    // 绑定到视频渲染器
    callState.value = CallState.connected;       // 更新 UI 状态
  }
};
```

---

### 七、整体时序总结（含 SDP + ICE 细节）

```
时间轴 ──────────────────────────────────────────────────────────────────►

用户A                          信令服务器                         用户B
 │                                 │                                 │
 ├─ connect WebSocket ────────────►│◄──────────────────── connect ──┤
 ├─ joinRoom ─────────────────────►│◄─────────────────── joinRoom ──┤
 │                                 │                                 │
 │           ◄──── peer-ready ─────┤──── peer-ready ───────────────►│
 │                                 │                                 │
 ├─ createOffer ───────────────────┤                                 │
 ├─ setLocalDescription ───────────┤                                 │
 │  ⚡ ICE收集开始（A）             │                                 │
 ├─ sendOffer ────────────────────►│──── forward offer ─────────────►│
 │                                 │                                 ├─ setRemoteDescription
 │                                 │                                 ├─ createAnswer
 │                                 │                                 ├─ setLocalDescription
 │                                 │                                 │  ⚡ ICE收集开始（B）
 │◄────────────────────────────────│◄──────── sendAnswer ──────────┤
 ├─ setRemoteDescription           │                                 │
 │                                 │                                 │
 │  [并行] ICE候选陆续收集          │  [并行] ICE候选陆续收集          │
 ├─ sendIceCandidate(host) ───────►│──────────────────────────────►│
 ├─ sendIceCandidate(srflx) ──────►│──────────────────────────────►│
 │◄────────────────────────────────│◄── sendIceCandidate(host) ────┤
 │◄────────────────────────────────│◄── sendIceCandidate(srflx) ───┤
 │  addCandidate × N               │                                 │  addCandidate × N
 │                                 │                                 │
 │  [ICE 连通性检查，双方互探]      │                                 │
 │◄════════════════════════════════════════════════════════════════►│
 │              UDP 打洞（Hole Punching）                            │
 │                                 │                                 │
 │  [找到最优路径]                  │                                 │
 │◄────────────────────────────────────────────────────────────────►│
 │              DTLS 握手（加密协商）                                 │
 │                                 │                                 │
 │  onTrack 触发 → connected ✅    │                     onTrack ✅  │
 │                                 │                                 │
 │  [P2P 媒体流，不再经过信令服务器] │                                 │
 │◄═══════════════════════════════════════════════════════════════►│
 │                    SRTP 加密音视频流                              │
```

---

### 八、关键知识点速查

| 问题 | 答案 |
|------|------|
| SDP 是什么格式？ | 纯文本，`key=value` 行，由 RFC 4566 定义 |
| Offer/Answer 谁先发？ | 项目中按 UID 字典序，最小的发 Offer |
| setLocalDescription 有什么副作用？ | 立即触发 ICE 候选收集（Trickle ICE） |
| ICE 候选有几种类型？ | host（局域网）/ srflx（STUN反射）/ relay（TURN中继） |
| STUN 用什么协议？ | UDP（也支持TCP，但优先UDP） |
| NAT 打洞的关键是什么？ | 双方同时向对方发包，让各自的 NAT 建立映射记录 |
| ICE 完成后还要做什么？ | DTLS 握手 → SRTP 密钥派生 → 开始传输 |
| onTrack 何时触发？ | ICE + DTLS 全部完成，媒体包开始到达时 |
| 没有 TURN 服务器会怎样？ | UDP 被严格封锁的网络无法建立 P2P 连接 |
| SDP 里的 fingerprint 字段是什么？ | DTLS 证书哈希，用于验证对端身份，防中间人攻击 |

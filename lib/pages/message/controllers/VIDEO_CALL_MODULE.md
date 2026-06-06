# 视频通话模块说明文档

> 路径：`lib/pages/message/controllers/`
>
> 最后更新：2026-05-22

---

## 一、模块概览

本模块实现基于 **WebRTC + WebSocket 信令** 的 1v1 实时视频通话功能，
涵盖通话发起、媒体采集、SDP 协商、ICE 打洞、挂断清理全流程。

| 文件 | 职责 |
|------|------|
| `consumer_ws_client.dart` | WebSocket 信令通道（GetxService 全局单例），负责连接后端、收发所有业务事件 |
| `video_call_controller.dart` | 视频通话控制器（GetxController，每次通话创建/销毁），负责 WebRTC 全流程 |

---

## 二、架构分层

```
┌────────────────────────────────────────────────────────────┐
│                         UI 层                              │
│  VideoCallPage                                             │
│    ├─ localRenderer  (本地摄像头，画中画)                   │
│    └─ remoteRenderer (对方视频，主画面)                     │
└────────────────────────┬───────────────────────────────────┘
                         │ Obx 响应 callState / isCameraOn / isMicOn
┌────────────────────────▼───────────────────────────────────┐
│              VideoCallController (GetxController)          │
│  职责：媒体采集 / RTCPeerConnection / 状态机                │
│  ├─ _getLocalMedia()          本地摄像头+麦克风             │
│  ├─ _createPeerConnection()   ICE / Offer / Answer / Track │
│  ├─ _setupListeners()         监听 WS 事件流               │
│  └─ callState.obs             驱动 UI 界面切换              │
└────────────────────────┬───────────────────────────────────┘
                         │ Stream 订阅
┌────────────────────────▼───────────────────────────────────┐
│              ConsumerWsClient (GetxService)                │
│  职责：WebSocket 连接 / JSON 解析 / Stream 分发             │
│  ├─ onPeerReady / onOffer / onAnswer / onIceCandidate      │
│  ├─ onVideoCallAccept / onVideoCallReject / onCallEnded    │
│  └─ joinRoom / sendOffer / sendAnswer / sendIceCandidate   │
└────────────────────────┬───────────────────────────────────┘
                         │ WebSocket JSON
┌────────────────────────▼───────────────────────────────────┐
│              cubeverse 后端 (NestJS, ws://host:8085)       │
│  负责：JWT 认证 / 房间管理 / 信令转发 / 在线列表推送        │
└────────────────────────────────────────────────────────────┘
```

---

## 三、通话状态机

```
                   ┌──────────┐
                   │   idle   │  ← 初始状态
                   └────┬─────┘
          主叫           │            被叫
    startAsCaller()      │      startAsCallee()
          ↓              │             ↓
    ┌──────────┐         │       ┌───────────┐
    │ waiting  │         │       │ connecting│
    │(等待接听)│         │       │(建连中)   │
    └────┬─────┘         │       └─────┬─────┘
         │ video-call-   │             │
         │ accept        │             │ peer-ready
         ↓               │             ↓
    ┌───────────┐         │    ┌─────────────────┐
    │connecting │         │    │  Offer/Answer   │
    │(加入房间) │─────────┘    │  ICE 交换       │
    └─────┬─────┘              └────────┬────────┘
          │                             │
          └──────────┬──────────────────┘
                     ↓
              ┌────────────┐
              │ connected  │  ← 视频通话中
              └──────┬─────┘
                     │ endCall() / 对方挂断 / 断网
                     ↓
              ┌────────────┐
              │   ended    │  ← UI 显示结束提示，自动返回
              └────────────┘

              任意状态 → error（媒体采集失败等异常）
```

---

## 四、完整信令流程

### 4.1 主叫方发起通话

```
主叫 App                    后端服务                   被叫 App
  │                            │                          │
  │── video-call-invite ──────▶│── video-call-invite ────▶│
  │   {to, roomId}             │   {from, roomId,         │
  │                            │    nickname, avatar}     │
  │                            │                          │
  │                            │◀──── video-call-accept ──│
  │◀──── video-call-accept ────│      {from, roomId}      │
  │  callState: connecting     │                          │
  │── join-room ──────────────▶│◀──────── join-room ──────│
  │                            │      (被叫方此前已发)    │
  │                            │                          │
  │◀── peer-ready(双方都就绪) ─┤─── peer-ready ──────────▶│
  │   [userId_A, userId_B]     │                          │
  │                            │                          │
  │  (若我userId最小)           │                          │
  │── offer ──────────────────▶│─────── offer ───────────▶│
  │   {roomId, to, sdp}        │                          │
  │                            │                          │
  │                            │◀────── answer ───────────│
  │◀──────── answer ───────────│                          │
  │   setRemoteDescription     │                          │
  │                            │                          │
  │◀═══ ice-candidate(双向) ═══│═══ ice-candidate(双向) ═▶│
  │   addCandidate             │                          │
  │                            │                          │
  │◀═══════ 媒体流建立 ════════════════════════════════════│
  │   callState: connected     │                          │
```

### 4.2 被叫方接听流程

```
被叫收到 video-call-invite
  └─ ConsumerWsClient.onInit() 自动触发
  └─ sendVideoCallAccept(from, roomId)   // 自动接受（当前版本）
  └─ Get.toNamed(Routes.chatVideoCall, isCaller: false)
       └─ VideoCallPage.initState()
           └─ controller.startAsCallee()
               └─ _getLocalMedia()
               └─ _createPeerConnection()
               └─ ws.joinRoom(roomId)    // 通知后端我就绪了
               └─ callState: connecting
```

> **注意**：当前版本被叫方在 `ConsumerWsClient.onInit()` 中**自动接受**所有来电邀请，
> 若需要弹出来电弹窗让用户手动选择接听/拒绝，需在此处改为先展示弹窗再调用 `startAsCallee()`。

---

## 五、关键设计决策

### 5.1 谁先发 Offer？

**规则**：将房间内所有用户的 userId 升序排序，**userId 最小**的一方发 Offer。

**原因**：避免双方同时发 Offer 产生 Glare 冲突（WebRTC 标准中的已知问题）。

```dart
// _handlePeerReady() 中的决策逻辑
final sorted = List<int>.from(peers)..sort();
if (sorted.first == myUserId) {
  _createAndSendOffer();   // 我是 userId 最小 → 我发 Offer
}
// 另一方等待 Offer 到来，走 _handleOfferReceived()
```

### 5.2 _handshakeStarted 标志位

**问题**：服务端可能多次推送 `peer-ready` 事件，导致重复发 Offer。

**解法**：首次处理 `peer-ready` 后置 `_handshakeStarted = true`，后续忽略。

### 5.3 MediaStream 轨道管理

| 操作 | 方法 | 说明 |
|------|------|------|
| 静音/取消静音 | `track.enabled = false/true` | 不重协商，带宽不变，对方静音 |
| 关闭/开启摄像头 | `track.enabled = false/true` | 对方画面变黑，不重协商 |
| 翻转摄像头 | `Helper.switchCamera(videoTrack)` | 直接替换采集源，不重协商 |

### 5.4 STUN 服务器

当前使用 Google 公共 STUN：

```dart
{'urls': 'stun:stun.l.google.com:19302'},
{'urls': 'stun:stun1.l.google.com:19302'},
```

**限制**：国内访问 Google STUN 可能不稳定，**生产环境建议换用国内 STUN 或自建 TURN 服务器**。

---

## 六、资源清理顺序

`_cleanup()` 按以下顺序执行，顺序不可颠倒：

```
1. 取消 WS Stream 订阅      → 防止 disposed 后再触发回调
2. leaveRoom                → 通知后端清理房间
3. 停止本地媒体轨道          → 关闭摄像头指示灯
4. dispose 本地 MediaStream
5. dispose 远端 MediaStream
6. 解绑渲染器 srcObject      → 必须在 dispose 前解绑
7. dispose 渲染器            → 释放 OpenGL 纹理
8. close RTCPeerConnection   → 关闭底层连接
9. 重置 _peerUserId 等字段
```

---

## 七、常见问题排查

| 现象 | 可能原因 | 排查方向 |
|------|---------|---------|
| 通话发起后一直停在 `waiting` | 对方没有收到 invite / WS 未认证 | 检查 `ConsumerWsClient.isAuthenticated` |
| `peer-ready` 触发但没有画面 | ICE 打洞失败（对称 NAT） | 换用 TURN 服务器中继 |
| 挂断后摄像头指示灯不消失 | `track.stop()` 未被调用 | 确认 `_cleanup()` 被正确执行 |
| 双方都看不到对方 | SDP 协商失败（编解码器不兼容） | 检查 `createOffer/Answer` 错误日志 |
| 对方视频延迟高 | STUN 不通，走了 relay | 换国内 STUN 或自建 TURN |
| `RTCPeerConnectionStateFailed` | ICE 候选全部失败 | 检查网络环境，添加 TURN 配置 |

---

## 八、扩展建议

1. **来电弹窗**：在 `ConsumerWsClient.onVideoCallInvite` 中展示来电弹窗，让用户手动接听/拒绝，而非自动接受。
2. **TURN 服务器**：在 `_createPeerConnection()` 的 `iceServers` 中添加 TURN 配置，提升穿透率。
3. **通话时长计时**：在 `callState → connected` 时启动 Timer，在 UI 顶部显示计时。
4. **网络质量监控**：通过 `_pc.getStats()` 定期采集丢包率、RTT，显示信号格。
5. **横竖屏适配**：监听 `remoteRenderer` 的宽高比，动态调整 UI 布局。

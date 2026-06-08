# Komodo

音视频、直播流 IM 类的示例应用，包含 NestJS 完整后台


<p align="center">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/1.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/2.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/3.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/4.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/5.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/6.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/7.jpg">
  <img width="24.6%" src="https://github.com/armomu/komodo/raw/main/assets/img/8.jpg">
</p>

## 功能概览

### 注册/登录 (带完整后台服务)

- **用户注册** — 邮箱、密码

### 即时通讯 IM (带后台服务，只支持文本发送，后台只转发数据不存储，只在前端 SQLite 存储)

- **WebSocket 实时通讯** — 基于 JWT 认证的 WS 长连接，支持心跳保活、断线重连、多设备踢出
- **多类型消息** — 文本、语音、图片（选择+查看+缓存）、礼物动画
- **消息持久化** — SQLite 本地存储，支持离线消息拉取、未读计数、按会话查询
- **在线状态** — 实时显示好友在线/离线状态

### 1v1 视频通话 (带完整后台服务)

- **WebRTC** — 完整的信令流程（Offer/Answer/ICE），通过 WebSocket 通道传输
- **通话状态机** — idle → waiting/incoming → connecting → connected → ended
- **媒体控制** — 前后摄像头切换、麦克风/摄像头开关
- **网络质量监控** — 实时 RTT + 丢包率检测，显示 good/fair/poor 状态
- **通话计时** — 连接后实时计时

### 音乐播放（不连接后台API数据纯模拟交互）

- **全局音乐播放器** — 跨页面保持状态，支持后台播放
- **系统媒体集成** — 通知栏、锁屏、控制中心媒体控制（audio_service）
- **LRC 歌词同步** — 实时高亮当前歌词行，支持全屏歌词/迷你歌词两种视图
- **网络歌曲缓存** — 后台下载，优先播放本地缓存


### 短视频（不连接后台API数据纯模拟交互）

- **上下滑动信息流** — PageView 纵向滑动，自动播放/暂停
- **互动操作** — 点赞、评论、收藏、分享
- **横屏全屏** — 自动检测宽高比，支持横屏视频全屏播放

## 技术栈

### 客户端 (Flutter)

| 技术 | 用途 |
|------|------|
| [GetX](https://pub.dev/packages/get) | 状态管理 + 路由 + 依赖注入 |
| [Dio](https://pub.dev/packages/dio) | HTTP 客户端 |
| [flutter_webrtc](https://pub.dev/packages/flutter_webrtc) | 1v1 视频通话 |
| [rtmp_streaming](https://pub.dev/packages/rtmp_streaming) | RTMP 直播推流 |
| [video_player](https://pub.dev/packages/video_player) | 视频/直播流播放 |
| [just_audio](https://pub.dev/packages/just_audio) | 音乐播放 |
| [audio_service](https://pub.dev/packages/audio_service) | 系统媒体通知栏集成 |
| [audioplayers](https://pub.dev/packages/audioplayers) | 聊天语音独立播放 |
| [sqflite](https://pub.dev/packages/sqflite) | 本地消息持久化 |
| [record](https://pub.dev/packages/record) | 语音录制 |
| [lottie](https://pub.dev/packages/lottie) | 礼物动画 |
| [image_picker](https://pub.dev/packages/image_picker) | 图片选择 |

### 服务端 (NestJS)

- HTTP API（认证、用户管理、消息等）
- WebSocket 网关（聊天消息、WebRTC 信令、在线状态）
- JWT 认证与鉴权
- RTMP 媒体服务器（直播推拉流）

## 项目结构

```
komodo/
├── lib/
│   ├── main.dart                  # 应用入口，全局控制器注册
│   ├── config/
│   │   └── base_url.dart         # API / WS / RTMP 地址配置
│   ├── components/               # 公共 UI 组件
│   ├── controllers/
│   │   └── user_controller.dart  # 全局用户状态
│   ├── database/
│   │   └── chat_database.dart    # SQLite 消息持久化
│   ├── models/                   # 数据模型
│   ├── pages/
│   │   ├── home/                 # 首页（底部 5 Tab 导航）
│   │   ├── music/                # 音乐播放模块
│   │   ├── video/                # 短视频模块
│   │   ├── message/              # IM 消息模块
│   │   │   ├── controllers/      # WS 客户端、会话列表、视频通话、语音
│   │   │   ├── widgets/          # 消息气泡、弹幕、通话 UI 等
│   │   ├── live/                 # 直播（观看 + 推流）
│   │   ├── login/                # 登录 / 注册 / 资料编辑
│   │   ├── profile/              # 个人中心 + 设计系统
│   │   └── settings/             # 设置
│   ├── routes/                   # 路由定义 + 中间件
│   ├── theme/                    # 主题系统（黑白灰 + 橙色强调）
│   └── utils/
│       └── request.dart          # Dio 封装
├── android/                      # Android 原生配置
├── ios/                          # iOS 原生配置
├── assets/                       # 静态资源（Lottie 动画等）
├── sounds/                       # 音频资源
└── pubspec.yaml
```

### 环境要求

```
[√] Flutter (Channel stable, 3.41.6, on Microsoft Windows [版本 10.0.22631.6199], locale zh-CN)
[√] Windows Version (11 专业版 64 位, 23H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
[√] Chrome - develop for the web (Chrome version 999.0.9999.99)
[√] Visual Studio - develop Windows apps (Visual Studio Community 2022, with Desktop development with C++)
[√] Proxy Configuration (NO_PROXY is set correctly)
[√] Connected device (3 available)
[√] Network resources

```

## License

MIT

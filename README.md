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

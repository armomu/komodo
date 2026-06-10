# Komodo 项目记忆

## 数据库架构（方案A）
- 仅一张 `messages` 表，用 `peer_id` 直接关联用户 ID（无 conversations 中间层）
- DB version: 2
- 未读数由 Controller 内存维护，不持久化

## 命名约定
- 消费者相关用 `consumer_xxx` 命名（不是 friend_xxx）
- 文件结构：controllers / models / repositories / widgets 分层

## 状态管理
- 全局 Controller 用 `Get.put()` 在 `main.dart` 注册
- `ConsumerListController` 是全局单例，驱动消息 Tab 列表
- `ConsumerWsClient.currentChatPeerId` 追踪当前打开的聊天 peerId

## request.dart 错误处理约定
- `appDio<T>()` 不再 throw，所有错误路径统一返回 `ApiResponse<T>`，调用方通过 `isSuccess` 判断
- `ApiResponse.error(code, message)` 工厂构造方法用于快速创建失败响应

## WebSocket 协议
- `get-online-users` → 主动拉取在线列表，后端回 `online-list`
- 后端位于 `C:\Users\qq894\dev\cubeverse\apps\ws\src\modules\websocket`

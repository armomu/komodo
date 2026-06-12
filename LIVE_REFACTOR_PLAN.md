# 直播模块重构实施计划

> 基于 Komodo (Flutter) + CubeVerse (NestJS) 现有架构
> ✅ **已确认**：WS 新端口 8087 | "+"号直跳主播页 | 消息Tab右上角图标 | 观看计数不包括主播，重复进入也计数

---

## 一、总览

| 维度 | 当前状态 | 目标 |
|------|----------|------|
| 主播入口 | 中间"+"号直接进入观众端 `LivePage` | "+"号 → 主播端新页面（设置公告→开始推流） |
| 直播间列表 | 不存在 | 消息页右上角直播图标 → 卡片列表页 |
| 观众端直播页 | 有基础布局但无 WS | 全量 WS 驱动（在线观众/弹幕/礼物同步） |
| 直播历史 | 不存在 | 新增页面：观看次数/评论/礼物 |
| WS 模块 | WS 服务在 8086 端口（聊天+WebRTC） | **新增** live-ws 服务在 **8087** 端口 |
| 后端 API | 无直播模块 | 新增 live 模块（房间CRUD/评论/礼物/历史） |
| 数据表 | 无 | 新增 5 张表 |

---

## 二、数据库设计（5 张新表）

### 2.1 `live_room` — 直播间

```sql
CREATE TABLE `live_room` (
  `id`          VARCHAR(36) NOT NULL,           -- UUID
  `hostId`      INT NOT NULL,                    -- 主播 user_id (FK→consumer.id)
  `title`       VARCHAR(100) DEFAULT '',         -- 直播标题
  `coverUrl`    VARCHAR(255) DEFAULT '',         -- 封面图
  `announcement` TEXT,                           -- 主播公告
  `status`      ENUM('waiting','live','ended') NOT NULL DEFAULT 'waiting',
  `rtmpKey`     VARCHAR(64) NOT NULL,            -- RTMP 推流标识 (如 stream_hostId)
  `viewerCount` INT NOT NULL DEFAULT 0,          -- 实时在线人数
  `totalViews`  INT NOT NULL DEFAULT 0,          -- 累计观看次数
  `startedAt`   DATETIME(6) NULL,
  `endedAt`     DATETIME(6) NULL,
  `createdAt`   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updatedAt`   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `idx_hostId` (`hostId`),
  INDEX `idx_status` (`status`),
  INDEX `idx_createdAt` (`createdAt` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.2 `live_viewer` — 观众进出记录

```sql
CREATE TABLE `live_viewer` (
  `id`        INT NOT NULL AUTO_INCREMENT,
  `roomId`    VARCHAR(36) NOT NULL,              -- FK→live_room.id
  `userId`    INT NOT NULL,                      -- FK→consumer.id
  `nickname`  VARCHAR(50) DEFAULT '',
  `avatar`    VARCHAR(255) DEFAULT '',
  `joinedAt`  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `leftAt`    DATETIME(6) NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_roomId` (`roomId`),
  INDEX `idx_userId` (`userId`),
  UNIQUE KEY `uk_room_user` (`roomId`, `userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.3 `live_comment` — 直播评论/弹幕

```sql
CREATE TABLE `live_comment` (
  `id`        INT NOT NULL AUTO_INCREMENT,
  `roomId`    VARCHAR(36) NOT NULL,              -- FK→live_room.id
  `userId`    INT NOT NULL,                      -- FK→consumer.id
  `nickname`  VARCHAR(50) DEFAULT '',
  `avatar`    VARCHAR(255) DEFAULT '',
  `message`   TEXT NOT NULL,
  `createdAt` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `idx_roomId` (`roomId`, `createdAt` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.4 `live_gift` — 礼物记录

```sql
CREATE TABLE `live_gift` (
  `id`            INT NOT NULL AUTO_INCREMENT,
  `roomId`        VARCHAR(36) NOT NULL,
  `senderId`      INT NOT NULL,
  `senderNickname` VARCHAR(50) DEFAULT '',
  `senderAvatar`  VARCHAR(255) DEFAULT '',
  `giftName`      VARCHAR(50) NOT NULL,          -- 礼物名称
  `giftIcon`      VARCHAR(10) DEFAULT '',        -- 图标 emoji
  `lottiePath`    VARCHAR(255) DEFAULT '',       -- Lottie 动画路径
  `createdAt`     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `idx_roomId` (`roomId`, `createdAt` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 2.5 `live_room_history` — 直播间历史统计

> 每场直播结束后生成一条记录，用于「我的直播历史」页面

```sql
CREATE TABLE `live_room_history` (
  `id`          INT NOT NULL AUTO_INCREMENT,
  `roomId`      VARCHAR(36) NOT NULL,
  `hostId`      INT NOT NULL,
  `title`       VARCHAR(100) DEFAULT '',
  `coverUrl`    VARCHAR(255) DEFAULT '',
  `announcement` TEXT,
  `totalViews`  INT NOT NULL DEFAULT 0,          -- 累计观看次数
  `peakViewers` INT NOT NULL DEFAULT 0,          -- 峰值在线人数
  `commentCount` INT NOT NULL DEFAULT 0,         -- 评论数
  `giftCount`   INT NOT NULL DEFAULT 0,          -- 礼物数
  `startedAt`   DATETIME(6) NOT NULL,
  `endedAt`     DATETIME(6) NOT NULL,
  `duration`    INT NOT NULL DEFAULT 0,          -- 直播时长（秒）
  `createdAt`   DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  INDEX `idx_hostId` (`hostId`, `endedAt` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 三、WS 协议设计（新端口：8087）

### 3.1 架构说明

- **新建** `apps/live-ws/` 服务，监听 **8087** 端口
- 与现有的 WS 服务（8086，聊天/WebRTC）完全独立
- 同样使用 `@nestjs/platform-ws` + 原生 `ws` 库
- **认证**：沿用 JWT token 认证机制（复用 `SharedModule`）

### 3.2 客户端 → 服务端命令

| 事件 | 方向 | 数据 | 说明 |
|------|------|------|------|
| `auth` | C→S | `{ token }` | JWT 认证 |
| `join-room` | C→S | `{ roomId }` | 进入直播间 |
| `leave-room` | C→S | `{ roomId }` | 离开直播间 |
| `send-comment` | C→S | `{ roomId, message }` | 发送弹幕/评论 |
| `send-gift` | C→S | `{ roomId, giftName, giftIcon, lottiePath }` | 送礼物 |
| `start-live` | C→S | `{ roomId }` | 主播开始直播 |
| `end-live` | C→S | `{ roomId }` | 主播结束直播 |
| `update-announcement` | C→S | `{ roomId, announcement }` | 主播更新公告 |
| `get-online-users` | C→S | `{ roomId }` | 拉取在线观众列表 |

### 3.3 服务端 → 客户端推送

| 事件 | 数据 | 说明 |
|------|------|------|
| `connected` | `{ connectionId }` | 连接成功 |
| `auth-success/error` | — | 认证结果 |
| `room-joined` | `{ roomId, host, viewers[], comments[], announcement }` | 进入房间后全量初始化 |
| `viewer-joined` | `{ userId, nickname, avatar }` | 有观众进入（推送给房间所有人） |
| `viewer-left` | `{ userId }` | 有观众离开 |
| `viewer-list` | `{ viewers: [...] }` | 在线观众列表更新 |
| `new-comment` | `{ id, userId, nickname, avatar, message, createdAt }` | 新评论/弹幕 |
| `new-gift` | `{ id, senderId, senderNickname, senderAvatar, giftName, giftIcon, lottiePath, createdAt }` | 收到礼物（所有人播放动画） |
| `announcement-updated` | `{ announcement }` | 公告更新 |
| `live-ended` | `{ roomId }` | 直播结束 |
| `room-stats` | `{ viewerCount, totalViews }` | 实时统计更新 |

### 3.4 心跳

- 每 **30 秒** 客户端发送 `ping`，服务端回复 `pong`
- 超过 **60 秒** 未收到心跳视为断开

---

## 四、后端 API 设计（apps/api 新增 live 模块）

### 4.1 直播间管理

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/live/room/create` | 创建直播间（主播） |
| GET | `/live/room/list` | 获取直播列表（正在直播的房间） |
| GET | `/live/room/:id` | 获取直播间详情 |
| PUT | `/live/room/:id` | 更新直播间（标题/公告） |

### 4.2 直播历史

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/live/history/:hostId` | 获取指定主播的历史直播列表 |
| GET | `/live/history/detail/:roomId` | 获取单场直播详情（含评论+礼物） |
| POST | `/live/room/:id/view` | 记录一次观看（每点击进入一次 +1 totalViews） |

### 4.3 数据管理后台

> 在 CubeVerse 现有后台管理页面中新增「直播管理」菜单

| 功能 | 说明 |
|------|------|
| 房间列表 | 查看/编辑/关闭直播间 |
| 历史记录 | 查看所有直播历史数据 |
| 评论管理 | 查看评论，支持删除违规评论 |
| 礼物统计 | 礼物排行榜/收益统计 |

---

## 五、Flutter 前端实施步骤（按优先级）

### 5.1 新建直播 WS 客户端（Phase 1）

**文件**: `lib/pages/live/controllers/live_ws_client.dart`

- 新建 GetxService，连接到 `ws://host:8087`
- 独立于现有的 `ConsumerWsClient`
- 提供方法：`connect()` / `disconnect()` / `joinRoom()` / `leaveRoom()` / `sendComment()` / `sendGift()` / `sendStartLive()` / `sendEndLive()` / `updateAnnouncement()` / `getOnlineUsers()`
- 通过 Rx/Stream 对外暴露事件

### 5.2 改造首页"+"号 → 主播端页面（Phase 1）

**文件**:
- `lib/pages/home/home_page.dart` — 将 `Get.toNamed(Routes.live)` 改为弹出**选择弹窗**（"进入直播间" / "开始直播"）
- `lib/pages/live/anchor_setup_page.dart` — **新建**主播端页面
  - 输入直播标题
  - 设置公告文本
  - "开始直播"按钮 → 跳转到 `LivePushPage`（现有的推流页改造）
- `lib/pages/live/live_push.dart` — 改造现有推流页
  - 推流前自动创建 `live_room`（调用API）
  - 推流同时通过 WS 发送 `start-live`
  - 停推时发送 `end-live`
  - 推流期间可以修改公告（WS 实时同步）

### 5.3 直播间列表页（Phase 2）

**文件**:
- `lib/pages/live/live_room_list_page.dart` — **新建**
  - 卡片布局：封面图 + 主播头像 + 标题 + 在线人数
  - 下拉刷新，获取正在直播的房间列表
  - 点击卡片进入直播间
- `lib/pages/message/message_tab.dart` — 改造
  - SliverAppBar 的 `actions` 中增加直播图标按钮
  - 点击跳转到 `LiveRoomListPage`

### 5.4 直播间（观众端）全面改造（Phase 2）

**文件**: `lib/pages/live/live_page.dart` 及 widgets/

核心修改：

#### a) WS 连接（进入时 join-room，离开时 leave-room）
- 路由参数传入 `roomId`
- `initState` → WS 连接 → `joinRoom`
- `dispose` → `leaveRoom` → WS 断连
- 收到 `viewer-list` → 更新右上角在线观众列表

#### b) 顶部布局调整
- **左上角**：`AnchorInfoBar` **保持静态不做逻辑**（粉丝数/关注按钮不交互）
- **右上角**：`ViewerInfoBar` 改造
  - 在线观众头像动态显示（从 WS 推送的 `viewer-list` 渲染）
  - 在线人数从 WS 实时更新
  - X 按钮 → 调用 `leaveRoom` WS + `Navigator.pop`

#### c) 公告栏（新建）
- 从 WS 收到的 `room-joined` / `announcement-updated` 数据渲染
- 主播端修改公告时，观众端实时更新

#### d) 评论/弹幕
- 用户在底部输入框发送评论 → `sendComment` WS
- 收到 `new-comment` → 添加弹幕到列表
  - 左下角聊天列表**自动滚动到底部**
  - 同时触发**飞行弹幕**
- **输入框右边的微笑按钮保持静态图标，不做交互**

#### e) 礼物
- 点击礼物按钮 → `GiftBottomSheet` 选择礼物
- 选择后 → `sendGift` WS
- 收到 `new-gift` → `LottieOverlayManager.playGiftAnimation()`
- **所有在房间的人都会播放动画**
- 礼物记录持久化到 `live_gift` 表

#### f) 购物篮 / 分享
- **保持静态**，不交互

### 5.5 直播历史页（Phase 3）

**文件**:
- `lib/pages/live/live_history_page.dart` — **新建**
  - 列表展示该主播的历史直播记录
  - 每项显示：封面、标题、时间、观看次数
  - 点击进入详情：展示该场直播的所有评论、礼物记录
- 入口：我的（ProfileTab）中增加"我的直播"入口

### 5.6 数据管理后台（Phase 3）

> 在 CubeVerse 后端 `apps/api` 中新增 live 管理模块

- 新增 `apps/api/src/modules/live/` 模块
- TypeORM 实体 + Controller + Service
- 后台管理界面（后续考虑用前端的现有 admin 管理）

---

## 六、文件变更清单

### Backend (CubeVerse)

| 操作 | 文件路径 |
|------|----------|
| **新建** | `apps/live-ws/package.json` |
| **新建** | `apps/live-ws/tsconfig.json` |
| **新建** | `apps/live-ws/src/main.ts` |
| **新建** | `apps/live-ws/src/app.module.ts` |
| **新建** | `apps/live-ws/src/modules/live-ws/live-ws.module.ts` |
| **新建** | `apps/live-ws/src/modules/live-ws/live-ws.gateway.ts` |
| **新建** | `apps/live-ws/src/modules/live-ws/live-ws.service.ts` |
| **新建** | `apps/live-ws/src/modules/live-ws/LIVE_WS_PROTOCOL.md` |
| **新建** | `packages/shared/src/entities/live-room.entity.ts` |
| **新建** | `packages/shared/src/entities/live-viewer.entity.ts` |
| **新建** | `packages/shared/src/entities/live-comment.entity.ts` |
| **新建** | `packages/shared/src/entities/live-gift.entity.ts` |
| **新建** | `packages/shared/src/entities/live-room-history.entity.ts` |
| **修改** | `packages/shared/src/index.ts`（导出新实体） |
| **新建** | `apps/api/src/modules/live/live.module.ts` |
| **新建** | `apps/api/src/modules/live/live.controller.ts` |
| **新建** | `apps/api/src/modules/live/live.service.ts` |
| **新建** | `apps/api/src/modules/live/dto/live.dto.ts` |
| **修改** | `.env.local` / `.env.development`（增加 LIVE_WS_PORT=8087） |
| **修改** | `nest-cli.json`（注册 live-ws-service） |
| **修改** | `pm2.config.js`（增加 live-ws 进程） |

### Frontend (Komodo)

| 操作 | 文件路径 |
|------|----------|
| **新建** | `lib/pages/live/controllers/live_ws_client.dart` |
| **新建** | `lib/pages/live/controllers/live_repository.dart`（HTTP API 封装） |
| **新建** | `lib/pages/live/anchor_setup_page.dart`（主播端设置页） |
| **新建** | `lib/pages/live/live_room_list_page.dart`（卡片列表页） |
| **新建** | `lib/pages/live/live_history_page.dart`（直播历史页） |
| **新建** | `lib/pages/live/models/live_models.dart`（数据模型） |
| **新建** | `lib/pages/live/widgets/online_viewers_widget.dart`（在线观众组件） |
| **新建** | `lib/pages/live/widgets/announcement_bar.dart`（公告栏组件） |
| **新建** | `lib/pages/live/widgets/live_room_card.dart`（房间卡片组件） |
| **修改** | `lib/pages/home/home_page.dart`（"+"号改为弹窗选择） |
| **修改** | `lib/pages/live/live_page.dart`（接入 WS 全量驱动） |
| **修改** | `lib/pages/live/live_push.dart`（改造为推流+WS联动） |
| **修改** | `lib/pages/live/widgets/viewer_info_bar.dart`（改为 WS 驱动实时更新） |
| **修改** | `lib/pages/live/widgets/anchor_info_bar.dart`（保持静态） |
| **修改** | `lib/pages/live/widgets/live_action_bar.dart`（微笑图标保持静态） |
| **修改** | `lib/pages/live/widgets/chat_input_bar.dart`（发送评论改为 WS） |
| **修改** | `lib/pages/live/gift_lottie_overlay.dart`（支持 WS 触发的远程动画） |
| **修改** | `lib/pages/message/message_tab.dart`（右上角加直播图标） |
| **修改** | `lib/routes/app_routes.dart`（新增路由） |
| **修改** | `lib/config/base_url.dart`（增加 live WS 地址） |
| **修改** | `lib/main.dart`（注册 LiveWsClient） |

---

## 七、实施顺序（3 个 Phase）

### Phase 1 — 基础建设 & 主播端
1. 后端：创建 `live_room` / `live_viewer` / `live_comment` / `live_gift` / `live_room_history` 实体
2. 后端：新建 `apps/live-ws` 服务（8087 端口，JWT 认证 + live 协议）
3. 后端：新建 `apps/api` live 模块（房间 CRUD + 观看计数 API）
4. 前端：新建 `LiveWsClient`（8087 WS 连接器）
5. 前端：改造首页"+"号 → 弹出选择（主播/观众）
6. 前端：新建 `AnchorSetupPage` → `LivePushPage` 联动
7. 前端：改造 `LivePushPage`（WS 联动 start-live / end-live / 公告同步）

### Phase 2 — 观众端 & 直播间列表
8. 前端：新建 `LiveRoomListPage`（卡片布局）
9. 前端：改造 `MessageTab`（右上角直播图标）
10. 前端：全面改造 `LivePage`（WS join-room / leave-room / viewer-list / new-comment / new-gift）
11. 前端：新建 `OnlineViewersWidget`（右上角在线观众动态展示）
12. 前端：新建 `AnnouncementBar`（公告栏）
13. 前端：改造礼物逻辑（send-gift WS → 全员动画播放）

### Phase 3 — 直播历史 & 后台管理
14. 前端：新建 `LiveHistoryPage`（我的直播历史）
15. 后端：后台管理 API（评论管理/礼物统计）
16. 前端：个人中心增加"我的直播"入口

---

## 八、关键约定

1. **WS 消息格式**（与现有 8086 服务保持一致）：
   ```json
   // 发送
   {"event": "join-room", "data": {"roomId": "xxx"}}
   // 接收
   {"event": "viewer-joined", "data": {"userId": 1, "nickname": "xxx", "avatar": "xxx"}}
   ```

2. **观看计数规则**：每次点击进入直播间就调用 `POST /live/room/:id/view` +1（包括主播自己进入算一次）

3. **RTMP 推流 key 规则**：`stream_{hostId}_{timestamp}`，保证唯一

4. **礼物 Lottie 动画路径**：与现有 `assets/lotties/` 下文件一致（闭眼入.json、潮范儿.json、买它.json、清仓.json）

5. **错误处理**：WS 断连后自动重连（最多 3 次，间隔 2s），重连后重新 join-room

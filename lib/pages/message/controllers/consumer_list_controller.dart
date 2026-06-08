import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/database/chat_database.dart';
import 'package:komodo/pages/message/controllers/consumer_ws_client.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import 'package:komodo/pages/message/models/consumer_list_item.dart';
import 'package:komodo/pages/message/repositories/consumer_repository.dart';
import 'package:komodo/routes/app_routes.dart';

/// 消费者列表 Controller（全局单例）
///
/// 管理：列表数据、分页、最后消息、在线状态、未读数。
/// 注册方式：Get.put() in main.dart（全局，后台也能更新列表）。
class ConsumerListController extends GetxController {
  static ConsumerListController get to => Get.find();

  final _repo = ConsumerRepository();

  // ── 列表状态 ──────────────────────────────────────────────────

  final consumers = RxList<ConsumerListItem>([]);
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;

  /// 分页状态
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // ── Worker 引用（dispose 时需要释放）──────────────────────
  Worker? _wsOnlineUsersWorker;
  StreamSubscription<ChatMessageData>? _wsMessageSub;

  // ── 生命周期 ──────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // 延迟一帧，等 GetX 绑定完成后再加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[ConsumerList] init=========================');
      if (Get.find<UserController>().isLoggedIn) {
        loadFirstPage();
      }
    });
  }

  @override
  void onClose() {
    _wsMessageSub?.cancel();
    _wsOnlineUsersWorker?.dispose();
    super.onClose();
  }

  // ── 公开方法（给 UI 调用）───────────────────────────────────

  /// 下拉刷新
  Future<void> refreshList() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    _currentPage = 1;
    try {
      final (items, totalPages, _) = await _repo.fetchConsumerPage(1, 20);
      _totalPages = totalPages;
      _hasMore = _currentPage < _totalPages;
      consumers.assignAll(items);
      // 拉取在线列表
      _requestOnlineUsers();
      // 监听 WS 消息（仅注册一次）
      _setupWsListeners();
    } catch (e) {
      debugPrint('[ConsumerList] refresh error: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  /// 上拉加载更多
  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    final nextPage = _currentPage + 1;
    try {
      final (items, totalPages, _) = await _repo.fetchConsumerPage(
        nextPage,
        20,
      );
      _totalPages = totalPages;
      _currentPage = nextPage;
      _hasMore = _currentPage < _totalPages;
      // 补充在线状态和 DB 数据
      final db = ChatDatabase.to;
      final wsCtrl = Get.find<ConsumerWsClient>();
      final newItems = <ConsumerListItem>[];
      for (final item in items) {
        final (content, time) = await db.getLastMessageByPeerId(item.id);
        final unread = await db.getUnreadCountByPeerId(item.id);
        final isOnline = wsCtrl.onlineUsers.any((u) => u.userId == item.id);
        newItems.add(
          item.copyWith(
            lastMessage: content,
            lastTime: time,
            unread: unread,
            isOnline: isOnline,
          ),
        );
      }
      consumers.addAll(newItems);
    } catch (e) {
      debugPrint('[ConsumerList] loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 首次加载
  Future<void> loadFirstPage() async {
    if (isLoading.value) return;
    isLoading.value = true;
    _currentPage = 1;
    try {
      final (items, totalPages, _) = await _repo.fetchConsumerPage(1, 20);
      _totalPages = totalPages;
      _hasMore = _currentPage < _totalPages;
      consumers.assignAll(items);
      _requestOnlineUsers();
      _setupWsListeners();
    } catch (e) {
      debugPrint('[ConsumerList] loadFirstPage error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 打开聊天页
  void openChat(ConsumerListItem item) {
    // 设置当前聊天 peerId（WS 客户端用来判断是否在前台）
    final wsCtrl = Get.find<ConsumerWsClient>();
    wsCtrl.currentChatPeerId.value = item.id;
    // 清未读（方案A：由 Controller 内存维护，进入即清）
    final idx = consumers.indexWhere((c) => c.id == item.id);
    if (idx != -1) {
      consumers[idx] = consumers[idx].copyWith(unread: 0);
    }
    // 导航
    Get.toNamed(
      Routes.chat,
      arguments: {
        'peerUserId': item.id,
        'peerName': item.nickname,
        'peerAvatar': item.avatar,
      },
    )?.then((_) {
      // 离开聊天页时清除 currentChatPeerId
      wsCtrl.currentChatPeerId.value = null;
    });
  }

  // ── 内部方法 ──────────────────────────────────────────────────

  void _requestOnlineUsers() {
    try {
      Get.find<ConsumerWsClient>().sendGetOnlineUsers();
    } catch (_) {
      // WS 可能未连接，忽略
    }
  }

  void _setupWsListeners() {
    if (_wsMessageSub != null) return; // 已注册

    final wsCtrl = Get.find<ConsumerWsClient>();

    // 监听聊天消息 → 更新对应 consumer 的 subtitle + unread
    _wsMessageSub = wsCtrl.onChatMessage.listen((ChatMessageData data) {
      _handleIncomingMessage(data);
    });

    // 监听在线列表 → 更新 isOnline
    _wsOnlineUsersWorker = ever(wsCtrl.onlineUsers, (list) {
      _updateOnlineStatus(list);
    });
  }

  void _handleIncomingMessage(ChatMessageData data) {
    final wsCtrl = Get.find<ConsumerWsClient>();
    final myId = Get.find<UserController>().userId;

    // 只处理发给我的消息
    if (data.from == myId) return;

    // 如果当前正在和该用户聊天，不更新列表
    if (wsCtrl.currentChatPeerId.value == data.from) return;

    // 找到对应 consumer，更新 subtitle 和 unread
    final idx = consumers.indexWhere((c) => c.id == data.from);
    if (idx == -1) return;

    final item = consumers[idx];
    consumers[idx] = item.copyWith(
      lastMessage: data.message,
      lastTime: _formatTime(DateTime.now()),
      unread: item.unread + 1,
    );
  }

  void _updateOnlineStatus(List<OnlineUser> list) {
    final onlineIds = list.map((u) => u.userId).toSet();
    for (int i = 0; i < consumers.length; i++) {
      final item = consumers[i];
      final online = onlineIds.contains(item.id);
      if (item.isOnline != online) {
        consumers[i] = item.copyWith(isOnline: online);
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}

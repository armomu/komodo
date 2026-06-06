import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/pages/message/controllers/consumer_ws_client.dart';
import 'package:komodo/pages/message/models/chat_models.dart';
import 'package:komodo/routes/app_routes.dart';
import 'package:komodo/utils/request.dart';
import '../music/widgets/message_list_item.dart';

/// 消息Tab — 分页加载 consumer 列表
/// 通过 GET /consumer/auth/list?page=1&pageSize=20 拉取用户列表
/// 下拉刷新重置到第 1 页，上拉加载更多
class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  MessageTabState createState() => MessageTabState();
}

class MessageTabState extends State<MessageTab> {
  final ScrollController _scrollController = ScrollController();
  final wsCtrl = Get.find<ConsumerWsClient>();
  final userCtrl = Get.find<UserController>();
  double _scrollOffset = 0.0;

  /// 用户列表
  final List<ConsumerItem> _users = [];

  /// 分页状态
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  /// 加载状态
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;

  /// 是否首次加载完成
  bool _initialized = false;

  Worker? _onlineUsersWorker;
  Worker? _userLoginStateWorker;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 延迟一帧，等 GetX 绑定完成后再加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && userCtrl.isLoggedIn) _loadFirstPage();
      // 监听在线用户列表
      _onlineUsersWorker = ever(wsCtrl.onlineUsers, (list) {
        setState(() {
          for (var item in _users) {
            item.isOnline = list.any((e) => e.userId == item.id);
          }
        });
      });
      _userLoginStateWorker = ever(userCtrl.isLogin, (login) {
        if (login) {
          _currentPage = 1;
          _loadFirstPage();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _onlineUsersWorker?.dispose();
    _userLoginStateWorker?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;

    setState(() {
      _scrollOffset = offset;
    });

    // 上拉加载更多：距底部 200px 时触发
    if (_hasMore && !_loading && !_loadingMore && maxExtent - offset < 200) {
      _loadMore();
    }
  }

  void _openChat(ConsumerItem user) {
    Get.toNamed(
      Routes.chat,
      arguments: {
        'peerUserId': user.id,
        'peerName': user.nickname,
        'peerAvatar': user.avatar,
      },
    );
  }

  /// 首次加载
  Future<void> _loadFirstPage() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _initialized = false;
    });

    final result = await _fetchPage(1);

    if (mounted) {
      setState(() {
        _users.clear();
        _users.addAll(result.list);
        _currentPage = result.page;
        _totalPages = result.totalPages;
        _hasMore = result.page < result.totalPages;
        _loading = false;
        _initialized = true;
      });
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    if (userCtrl.isLoggedIn) {
      wsCtrl.connect();
    }
    final result = await _fetchPage(1);
    if (mounted) {
      setState(() {
        _users.clear();
        _users.addAll(result.list);
        _currentPage = result.page;
        _totalPages = result.totalPages;
        _hasMore = result.page < result.totalPages;
        _refreshing = false;
      });
    } else {
      setState(() => _refreshing = false);
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final nextPage = _currentPage + 1;
    final result = await _fetchPage(nextPage);

    if (mounted) {
      setState(() {
        _users.addAll(result.list);
        _currentPage = result.page;
        _totalPages = result.totalPages;
        _hasMore = result.page < result.totalPages;
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  /// 请求分页数据
  Future<PageData> _fetchPage(int page) async {
    try {
      final resp = await appDio<PageData>(
        '/consumer/auth/list',
        method: 'get',
        params: {'page': '$page', 'pageSize': '20'},
        fromJsonT: (data) => PageData.fromJson(data as Map<String, dynamic>),
      );

      if (resp.isSuccess && resp.data != null) {
        return resp.data!;
      }

      // 请求失败返回空页
      debugPrint('[MessageTab] 加载失败: ${resp.message}');
    } catch (e) {
      debugPrint('[MessageTab] 加载异常: $e');
    }

    return const PageData(
      list: [],
      total: 0,
      page: 1,
      pageSize: 20,
      totalPages: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxExtent = 102.0;
    const minExtent = kToolbarHeight;
    final shrinkOffset = _scrollOffset.clamp(0.0, maxExtent - minExtent);
    final collapseProgress = shrinkOffset / (maxExtent - minExtent);

    const startLeft = 16.0;
    const endLeft = 52.0;
    final leftPadding = startLeft + (endLeft - startLeft) * collapseProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            leading: Opacity(
              opacity: collapseProgress,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            expandedHeight: maxExtent,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Messages',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              titlePadding: EdgeInsets.only(left: leftPadding, bottom: 14),
              centerTitle: false,
            ),
          ),
        ];
      },
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    // 首次加载中
    if (!_initialized && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 未登录
    final userCtrl = UserController.to;
    if (!userCtrl.isLoggedIn) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    '请先登录',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 空列表
    if (_users.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    '暂无用户',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 用户列表 + 加载更多指示器
    final itemCount = _users.length + (_hasMore ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index >= _users.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _loadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        final user = _users[index];
        return MessageListItem(
          unread: user.unread,
          title: user.nickname,
          avatarUrl: user.avatar,
          subtitle: 'user_id: ${user.id}',
          isDark: isDark,
          isOnline: user.isOnline,
          onTap: () => _openChat(user),
        );
      },
    );
  }
}

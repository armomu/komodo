import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/routes/app_routes.dart';
import 'controllers/live_repository.dart';
import 'models/live_models.dart';

/// 直播间列表页
/// 使用"首页-我的"可点击卡片规范，封面用 picsum.photos 占位
class LiveRoomListPage extends StatefulWidget {
  const LiveRoomListPage({super.key});

  @override
  State<LiveRoomListPage> createState() => _LiveRoomListPageState();
}

class _LiveRoomListPageState extends State<LiveRoomListPage> {
  final List<LiveRoom> _rooms = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    final result = await LiveRepository.getRoomList(page: _page);
    if (result.isSuccess && result.data != null) {
      setState(() {
        if (refresh) _rooms.clear();
        _rooms.addAll(result.data!);
        _hasMore = result.data!.length >= 20;
        _page++;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enterRoom(LiveRoom room) async {
    await Get.toNamed(Routes.live, arguments: {'roomId': room.id, 'isAnchor': false});
    // 从直播间返回后刷新列表
    _loadRooms(refresh: true);
  }

  static const _coverColors = [
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFF3E5F5),
    Color(0xFFE0F7FA),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播中'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '直播历史',
            onPressed: () => Get.toNamed(Routes.liveHistory),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.anchorSetup),
        child: const Icon(Icons.add),
      ),
      body: _rooms.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无正在直播的房间',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadRooms(refresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _rooms.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _rooms.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildRoomCard(_rooms[index], index);
                },
              ),
            ),
    );
  }

  Widget _buildRoomCard(LiveRoom room, int index) {
    final coverColor = _coverColors[index % _coverColors.length];
    final coverSeed = room.id.hashCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _enterRoom(room),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图（可点击卡片规范）
              Container(
                height: 140,
                width: double.infinity,
                color: coverColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://picsum.photos/seed/$coverSeed/400/225',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: coverColor),
                    ),
                    // 直播中标签
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '直播',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // 在线人数
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${room.viewerCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 底部信息
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title.isNotEmpty ? room.title : '未命名直播',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.hostNickname ?? '主播',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

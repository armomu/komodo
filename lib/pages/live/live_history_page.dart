import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'controllers/live_repository.dart';
import 'models/live_models.dart';

/// 我的直播历史页
class LiveHistoryPage extends StatefulWidget {
  const LiveHistoryPage({super.key});

  @override
  State<LiveHistoryPage> createState() => _LiveHistoryPageState();
}

class _LiveHistoryPageState extends State<LiveHistoryPage> {
  final List<LiveRoomHistory> _histories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);

    final hostId = Get.find<UserController>().userId;
    if (hostId <= 0) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await LiveRepository.getHistoryByHost(hostId, page: _page);
    if (result.isSuccess && result.data != null) {
      setState(() {
        if (refresh) _histories.clear();
        _histories.addAll(result.data!);
        _hasMore = result.data!.length >= 20;
        _page++;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showDetail(LiveRoomHistory history) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: FutureBuilder<LiveHistoryDetail?>(
          future: LiveRepository.getHistoryDetail(history.roomId).then((r) => r.data),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('加载失败'));
            }
            final detail = snapshot.data!;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('直播详情',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _infoRow('直播标题', history.title),
                    _infoRow('观看次数', '${history.totalViews}'),
                    _infoRow('峰值在线', '${history.peakViewers}'),
                    _infoRow('评论数', '${history.commentCount}'),
                    _infoRow('礼物数', '${history.giftCount}'),
                    _infoRow('时长', history.durationText),
                    const SizedBox(height: 16),
                    if (detail.comments.isNotEmpty) ...[
                      const Text('评论',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...detail.comments.map((c) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  c.avatar.isNotEmpty ? NetworkImage(c.avatar) : null,
                              child: c.avatar.isEmpty ? const Icon(Icons.person, size: 14) : null,
                            ),
                            title: Text(c.nickname,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            subtitle: Text(c.message, style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                    if (detail.gifts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('礼物',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...detail.gifts.map((g) => ListTile(
                            dense: true,
                            leading: Text(g.giftIcon, style: const TextStyle(fontSize: 24)),
                            title: Text(g.senderNickname,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text('赠送了 ${g.giftName}',
                                style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播历史'),
        centerTitle: true,
      ),
      body: _histories.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('暂无直播历史',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadHistories(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _histories.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _histories.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildHistoryCard(_histories[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(LiveRoomHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(history),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: history.coverUrl.isNotEmpty
                      ? Image.network(history.coverUrl, fit: BoxFit.cover)
                      : const Icon(Icons.live_tv, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.title.isNotEmpty ? history.title : '未命名直播',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${history.totalViews} 次观看',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.comment, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${history.commentCount} 评论',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.card_giftcard, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${history.giftCount} 礼物',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(history.durationText,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

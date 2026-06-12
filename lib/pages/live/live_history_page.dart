import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'controllers/live_repository.dart';
import 'models/live_models.dart';

/// 我的直播历史页
/// 遵循"首页-我的"列表规范：无背景色、标准 ListTile 样式
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
    AppBottomSheet.show(
      child: FutureBuilder<LiveHistoryDetail?>(
        future: LiveRepository.getHistoryDetail(history.roomId).then((r) => r.data),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: Text('加载失败')),
            );
          }
          final detail = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 统计信息
                _infoRow('直播标题', history.title.isNotEmpty ? history.title : '未命名'),
                _infoRow('观看次数', '${history.totalViews}'),
                _infoRow('峰值在线', '${history.peakViewers}'),
                _infoRow('评论数', '${history.commentCount}'),
                _infoRow('礼物数', '${history.giftCount}'),
                _infoRow('时长', history.durationText),
                const SizedBox(height: 16),
                // 评论列表
                if (detail.comments.isNotEmpty) ...[
                  _buildSectionTitle('评论'),
                  const SizedBox(height: 4),
                  ...detail.comments.map((c) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              c.avatar.isNotEmpty ? NetworkImage(c.avatar) : null,
                          child:
                              c.avatar.isEmpty ? const Icon(Icons.person, size: 14) : null,
                        ),
                        title: Text(c.nickname,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(c.message, style: const TextStyle(fontSize: 13)),
                      )),
                ],
                // 礼物列表
                if (detail.gifts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSectionTitle('礼物'),
                  const SizedBox(height: 4),
                  ...detail.gifts.map((g) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(g.giftIcon, style: const TextStyle(fontSize: 24)),
                        title: Text(g.senderNickname, style: const TextStyle(fontSize: 13)),
                        subtitle:
                            Text('赠送了 ${g.giftName}', style: const TextStyle(fontSize: 13)),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
    return ListTile(
      onTap: () => _showDetail(history),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 44,
          height: 44,
          color: Colors.grey[200],
          child: history.coverUrl.isNotEmpty
              ? Image.network(history.coverUrl, fit: BoxFit.cover)
              : const Icon(Icons.live_tv, color: Colors.grey, size: 22),
        ),
      ),
      title: Text(
        history.title.isNotEmpty ? history.title : '未命名直播',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text('${history.totalViews} 次观看 · ',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(history.durationText,
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

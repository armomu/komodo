import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/pages/live/controllers/live_repository.dart';
import 'package:komodo/pages/live/controllers/live_ws_client.dart';
import 'package:komodo/routes/app_routes.dart';

/// 主播设置页面
/// 设置直播标题和公告后，开始直播（跳转到推流页）
class AnchorSetupPage extends StatefulWidget {
  const AnchorSetupPage({super.key});

  @override
  State<AnchorSetupPage> createState() => _AnchorSetupPageState();
}

class _AnchorSetupPageState extends State<AnchorSetupPage> {
  final _titleController = TextEditingController();
  final _announcementController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('提示', '请输入直播标题',
          backgroundColor: Colors.black87, colorText: Colors.white);
      return;
    }

    setState(() => _isCreating = true);

    final result = await LiveRepository.createRoom(
      title: title,
      announcement: _announcementController.text.trim(),
    );

    setState(() => _isCreating = false);

    if (!result.isSuccess) {
      Get.snackbar('创建失败', result.message,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final room = result.data;
    if (room == null) {
      Get.snackbar('创建失败', '返回数据异常',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // 连接 Live WS
    final liveWs = Get.find<LiveWsClient>();
    if (!liveWs.isConnected.value) {
      await liveWs.connect();
      // 等认证完成
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 跳转到推流页，传入 roomId
    Get.toNamed(Routes.livePush, arguments: {
      'roomId': room.id,
      'rtmpKey': room.rtmpKey,
      'title': room.title,
      'announcement': room.announcement,
    });
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('开始直播'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主播信息
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: userCtrl.avatar.isNotEmpty
                        ? NetworkImage(userCtrl.avatar)
                        : null,
                    child: userCtrl.avatar.isEmpty
                        ? Icon(Icons.person, size: 32, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userCtrl.nickname,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 直播标题
            const Text('直播标题', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: '输入直播标题',
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            // 公告
            const Text('直播公告', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _announcementController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: '输入直播公告（可选）',
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 40),

            // 开始直播按钮
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _startLive,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.live_tv, size: 22),
                label: Text(_isCreating ? '创建中...' : '开始直播'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  textStyle: const TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

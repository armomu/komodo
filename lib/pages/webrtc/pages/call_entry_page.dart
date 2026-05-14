import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/webrtc_controller.dart';
import 'video_call_page.dart';

/// 通话入口页面——输入房间号和昵称，发起或等待呼叫。
class CallEntryPage extends StatefulWidget {
  const CallEntryPage({super.key});

  @override
  State<CallEntryPage> createState() => _CallEntryPageState();
}

class _CallEntryPageState extends State<CallEntryPage> {
  final _serverController = TextEditingController(
    text: 'ws://192.168.1.38:3002',
  );
  final _roomController = TextEditingController(text: 'room-001');
  final _nameController = TextEditingController(
    text: 'User_${DateTime.now().millisecondsSinceEpoch % 10000}',
  );

  bool _connecting = false;

  @override
  void dispose() {
    _serverController.dispose();
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final server = _serverController.text.trim();
    final room = _roomController.text.trim();
    final name = _nameController.text.trim();

    if (room.isEmpty || name.isEmpty) {
      Get.snackbar('提示', '请填写房间号和昵称');
      return;
    }
    if (server.isEmpty) {
      Get.snackbar('提示', '请填写信令服务器地址');
      return;
    }

    setState(() => _connecting = true);

    try {
      // 初始化控制器
      final controller = Get.put(WebrtcController(), permanent: true);
      await controller.initRenderers();

      // 导航到通话页面
      await Get.to(
        () => VideoCallPage(serverUrl: server, roomId: room, myUid: name),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 300),
      );

      // 回来时清理
      Get.delete<WebrtcController>(force: true);
    } catch (e) {
      Get.snackbar('错误', '连接失败: $e');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('视频通话'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // 图标
            Icon(
              Icons.videocam_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              '一对一视频通话',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '输入房间号即可发起或加入通话',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 40),

            // 信令服务器地址
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: '信令服务器地址',
                hintText: 'ws://host:3002',
                prefixIcon: Icon(Icons.dns_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 房间号
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: '房间号',
                hintText: '输入房间号，如 room-001',
                prefixIcon: Icon(Icons.meeting_room_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 昵称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                hintText: '你的显示名称',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // 加入按钮
            FilledButton.icon(
              onPressed: _connecting ? null : _joinRoom,
              icon: _connecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.call),
              label: Text(_connecting ? '连接中...' : '加入房间'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 使用说明
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHint('1. 和对方使用相同的房间号'),
                    _buildHint('2. 双方都加入后即可开始通话'),
                    _buildHint('3. 点击接听按钮接通来电'),
                    _buildHint('4. 支持切换摄像头和静音'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

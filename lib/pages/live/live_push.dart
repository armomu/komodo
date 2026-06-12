import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/config/base_url.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/pages/live/controllers/live_repository.dart';
import 'package:komodo/pages/live/controllers/live_ws_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_streaming/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LivePushPage extends StatefulWidget {
  const LivePushPage({super.key});

  @override
  State<LivePushPage> createState() => _LivePushPageState();
}

class _LivePushPageState extends State<LivePushPage> {
  final CameraController _controller = CameraController(
    ResolutionPreset.medium,
    enableAudio: true,
    androidUseOpenGL: true,
  );

  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool isStreaming = false;
  bool _permissionDenied = false;

  Timer? _statsTimer;
  String _statsLine = '';

  // 直播间数据
  String? _roomId;
  String _rtmpUrl = BaseUrl.rtmpPush();
  String _title = '';
  String _announcement = '';

  final TextEditingController _announcementController = TextEditingController();

  late final LiveWsClient _liveWs;

  @override
  void initState() {
    super.initState();

    // 读取路由参数
    final args = Get.arguments as Map<String, dynamic>?;
    _roomId = args?['roomId'] as String?;
    final rtmpKey = args?['rtmpKey'] as String?;
    _title = args?['title'] as String? ?? '';

    // 如果有 rtmpKey，生成推流地址
    if (rtmpKey != null && rtmpKey.isNotEmpty) {
      _rtmpUrl = BaseUrl.rtmpPushWithKey(rtmpKey);
    }

    _liveWs = Get.find<LiveWsClient>();

    _initCamera();
  }

  Future<void> _initCamera() async {
    debugPrint('[推流] 正在申请权限...');

    if (Platform.isAndroid || Platform.isIOS) {
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        setState(() => _permissionDenied = true);
        debugPrint('[推流] 权限被拒绝');
        return;
      }
      debugPrint('[推流] 权限申请成功');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _permissionDenied = true);
      debugPrint('[推流] 未检测到可用相机');
      return;
    }

    _cameras = cameras;
    debugPrint('[推流] 检测到 ${cameras.length} 个相机');

    _currentCameraIndex = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_currentCameraIndex < 0) _currentCameraIndex = 0;

    debugPrint('[推流] 初始化 ${_cameraLabel(cameras[_currentCameraIndex])}...');

    try {
      await _controller.initialize(cameras[_currentCameraIndex]);

      _controller.addListener(() {
        if (mounted) setState(() {});
        if (_controller.value.event != null) {
          final event = _controller.value.event as Map<dynamic, dynamic>;
          final eventType = event['eventType'] as String;
          final detail = event['detail'] ?? '';
          debugPrint('[推流事件] $eventType  $detail');

          if ((eventType == "error" || eventType == 'rtmp_stopped') &&
              isStreaming) {
            _showSnackBar('推流异常，已停止');
            _stopStreaming();
          }
        }
      });

      if (mounted) setState(() => _isInitialized = true);
      debugPrint('[推流] 相机初始化完成');
    } catch (e) {
      debugPrint('[推流] 相机初始化失败: $e');
      _showSnackBar('相机初始化失败');
    }
  }

  void _startStatsTimer() {
    if (!Platform.isAndroid) return;
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || !isStreaming) return;
      try {
        final s = await _controller.getStreamStatistics();
        if (!mounted) return;
        setState(() {
          _statsLine =
              'fps=${s.fps}  RTT=${s.rttMicros}µs  已发送=${s.bytesSend}B';
        });
        debugPrint(
          '[推流数据] fps=${s.fps}  RTT=${s.rttMicros}µs  bytes=${s.bytesSend}',
        );
      } catch (_) {}
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _statsLine = '';
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || isStreaming) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    final nextCamera = _cameras[_currentCameraIndex];

    debugPrint('[推流] 切换相机到 ${_cameraLabel(nextCamera)}');

    try {
      await _controller.switchCamera(nextCamera.name!);
      _showSnackBar('已切换到 ${_cameraLabel(nextCamera)}');
    } on CameraException catch (e) {
      _showSnackBar('切换失败: ${e.description}');
    }
  }

  String _cameraLabel(CameraDescription c) {
    switch (c.lensDirection) {
      case CameraLensDirection.front:
        return '前置相机';
      case CameraLensDirection.back:
        return '后置相机';
      default:
        return '相机';
    }
  }

  Future<void> _startStreaming() async {
    if (!_isInitialized) return;
    if (_rtmpUrl.isEmpty) {
      _showSnackBar('推流地址无效');
      return;
    }
    debugPrint('[推流] 开始推流: $_rtmpUrl');
    try {
      await _controller.startVideoStreaming(_rtmpUrl);
      await WakelockPlus.enable();

      // 通知 WS：直播开始（等待认证完成）
      if (_roomId != null && _liveWs.isConnected.value) {
        final ready = await _liveWs.waitForAuth();
        if (ready) {
          _liveWs.startLive(_roomId!);
        } else {
          _showSnackBar('WS 未就绪，直播状态可能不同步');
        }
      }

      setState(() => isStreaming = true);
      _startStatsTimer();
      _showSnackBar('开始推流');
    } on CameraException catch (e) {
      debugPrint('[推流] 推流失败: ${e.description}');
      _showSnackBar('推流失败: ${e.description}');
    }
  }

  Future<void> _stopStreaming() async {
    if (!isStreaming) return;
    debugPrint('[推流] 停止推流');
    try {
      await _controller.stopVideoStreaming();
      await WakelockPlus.disable();
      _stopStatsTimer();

      // 通知 WS：直播结束
      if (_roomId != null) {
        final ready = await _liveWs.waitForAuth();
        if (ready) {
          _liveWs.endLive(_roomId!);
        } else {
          debugPrint('[推流] WS 未认证，无法发送 end-live');
        }
      }
    } on CameraException catch (e) {
      debugPrint('[推流] 停止推流失败: ${e.description}');
      _showSnackBar('停止推流失败: ${e.description}');
    } finally {
      if (mounted) setState(() => isStreaming = false);
      // 延迟返回上一页
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Get.back();
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showUpdateAnnouncementDialog() {
    _announcementController.text = _announcement;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改公告'),
        content: TextField(
          controller: _announcementController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '输入新公告内容',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = _announcementController.text.trim();
              if (text.isNotEmpty && _roomId != null) {
                _announcement = text;
                _liveWs.updateAnnouncement(_roomId!, text);
                // 同步更新后端
                LiveRepository.updateRoom(_roomId!, announcement: text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 如果离开时仍在推流，尝试结束直播
    if (isStreaming) {
      try {
        _controller.stopVideoStreaming();
        WakelockPlus.disable();
      } catch (_) {}
      _stopStatsTimer();
      // 发送 end-live 到 WS
      if (_roomId != null) {
        _liveWs.endLive(_roomId!);
      }
    }
    _stopStatsTimer();
    _controller.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_title.isNotEmpty ? _title : '主播端',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_roomId != null)
            IconButton(
              icon: const Icon(Icons.campaign, color: Colors.white),
              tooltip: '修改公告',
              onPressed: _showUpdateAnnouncementDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // 主播信息条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: userCtrl.avatar.isNotEmpty
                      ? NetworkImage(userCtrl.avatar)
                      : null,
                  child: userCtrl.avatar.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  userCtrl.nickname,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isStreaming ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isStreaming ? '直播中' : '等待中',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 相机预览
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isStreaming ? Colors.redAccent : Colors.grey,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildPreview()),
                    if (_cameras.length >= 2 && !isStreaming)
                      Positioned(
                          right: 12, top: 12, child: _switchCameraBtn()),
                    if (isStreaming && _statsLine.isNotEmpty)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statsLine,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 推流按钮
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: !_isInitialized
                    ? null
                    : (isStreaming ? _stopStreaming : _startStreaming),
                icon: Icon(
                  isStreaming ? Icons.stop : Icons.live_tv,
                  size: 22,
                ),
                label: Text(
                  isStreaming ? '停止推流' : '开始推流',
                  style: const TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStreaming ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCameraBtn() {
    return GestureDetector(
      onTap: _switchCamera,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white30),
        ),
        child:
            const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildPreview() {
    if (_permissionDenied) {
      return const Center(
        child: Text(
          '请授予相机和麦克风权限',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white54),
            SizedBox(height: 16),
            Text('相机初始化中...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: CameraPreview(_controller),
    );
  }
}

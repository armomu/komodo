import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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

  final String _rtmpUrl = "rtmp://192.168.1.38:1935/live/stream";

  @override
  void initState() {
    super.initState();
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
    debugPrint('[推流] 开始推流: $_rtmpUrl');
    try {
      await _controller.startVideoStreaming(_rtmpUrl);
      await WakelockPlus.enable();
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
    } on CameraException catch (e) {
      debugPrint('[推流] 停止推流失败: ${e.description}');
      _showSnackBar('停止推流失败: ${e.description}');
    } finally {
      if (mounted) setState(() => isStreaming = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _stopStatsTimer();
    _controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('主播端', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
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
                      Positioned(right: 12, top: 12, child: _switchCameraBtn()),
                    // 实时数据叠加层
                    if (isStreaming && _statsLine.isNotEmpty)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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

          // 推流状态 + 按钮
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isStreaming ? Colors.red : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isStreaming ? '推流中' : '等待推流',
                      style: TextStyle(
                        color: isStreaming ? Colors.red : Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _rtmpUrl,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
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
              ],
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
        child: const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
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

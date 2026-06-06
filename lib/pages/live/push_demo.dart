// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:komodo/config/base_url.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_streaming/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CameraExampleHome extends StatefulWidget {
  const CameraExampleHome({super.key});
  @override
  CameraExampleHomeState createState() {
    return CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection? direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
    default:
      return Icons.camera;
  }
}

String _cameraLensLabel(CameraLensDirection? direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return '后置';
    case CameraLensDirection.front:
      return '前置';
    case CameraLensDirection.external:
      return '外置';
    default:
      return '未知';
  }
}

void logError(String code, String message) =>
    debugPrint('Error: $code\nError Message: $message');

class CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  final CameraController controller = CameraController(
    ResolutionPreset.medium,
    enableAudio: true,
    androidUseOpenGL: true,
  );
  String? imagePath;
  String? videoPath;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  bool isFlashLight = false;
  CameraDescription? _cameraDesc;
  final TextEditingController _textFieldController = TextEditingController(
    text: BaseUrl.rtmpPush(),
  );

  /// RootEncoder 2.7.0+: BT.709 与 RTMP ping/RTT
  bool _forceBt709 = false;
  bool _rtmpShouldSendPings = false;
  Timer? _streamStatsTimer;
  String _androidStreamStatsLine = '';

  /// HaishinKit 2.2.5+: 分屏/多任务时保持相机（iOS 17+）
  bool _iosMultitaskingCamera = false;

  bool get isStreaming => controller.value.isStreamingVideoRtmp ?? false;
  bool get isControllerInitialized => controller.value.isInitialized ?? false;
  bool get isRecordingVideo => controller.value.isRecordingVideo ?? false;
  bool get isRecordingPaused => controller.value.isRecordingPaused;
  bool get isStreamingPaused => controller.value.isStreamingPaused;
  bool get isTakingPicture => controller.value.isTakingPicture ?? false;

  @override
  void initState() {
    super.initState();
    _initCameras();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initCameras() async {
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      logError(e.code, e.description ?? "No description found");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showInSnackBar("相机错误: ${e.code}");
      });
      return;
    }
    if (cameras.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showInSnackBar("未检测到可用相机");
      });
      return;
    }
    var cameraItem = cameras[0];
    setState(() {
      _cameraDesc = cameraItem;
    });
    onNewCameraSelected(cameraItem);
  }

  @override
  void dispose() {
    onDispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void onDispose() async {
    _streamStatsTimer?.cancel();
    await WakelockPlus.disable();
    await controller.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey;

    if (isRecordingVideo) {
      borderColor = Colors.redAccent;
    } else if (isStreaming) {
      borderColor = Colors.blueAccent;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('相机推流', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (Platform.isAndroid) ...[
            // 滤镜按钮组
            _appBarFilterBtn('原始', () => controller.setFilter(0)),
            _appBarFilterBtn('美白', () => controller.setFilter(43)),
            _appBarFilterBtn('关闭', () => controller.removeFilter(0)),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: isControllerInitialized
                ? () async {
                    await controller.dispose();
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // 相机预览区
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 3.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _cameraPreviewWidget(),
              ),
            ),
          ),
          // 控制面板
          Expanded(flex: 2, child: _controlPanel()),
        ],
      ),
    );
  }

  Widget _appBarFilterBtn(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: isControllerInitialized ? onPressed : null,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  /// 相机预览（或提示文字）
  Widget _cameraPreviewWidget() {
    if (!isControllerInitialized) {
      return const Center(
        child: Text(
          '相机初始化中...',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// 控制面板主体
  Widget _controlPanel() {
    if (!isControllerInitialized) return Container();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ===== 第一行：主操作按钮 =====
            Row(
              children: [
                // 拍照（仅 Android）
                if (Platform.isAndroid)
                  Expanded(
                    child: _actionBtn(
                      '拍照',
                      Icons.camera_alt,
                      Colors.blue,
                      onTakePictureButtonPressed,
                      enabled: !(isRecordingVideo || isStreaming),
                    ),
                  ),
                if (Platform.isAndroid) const SizedBox(width: 8),
                // 本地录制
                Expanded(
                  child: _actionBtn(
                    isRecordingVideo ? '停止录制' : '开始录制',
                    isRecordingVideo ? Icons.stop : Icons.videocam,
                    isRecordingVideo ? Colors.red : Colors.blue,
                    onVideoRecordButtonPressed,
                  ),
                ),
                const SizedBox(width: 8),
                // 推流
                Expanded(
                  child: _actionBtn(
                    isStreaming ? '停止推流' : '开始推流',
                    isStreaming ? Icons.stop : Icons.live_tv,
                    isStreaming ? Colors.red : Colors.orange,
                    () {
                      if (isStreaming) {
                        stopVideoStreaming();
                      } else {
                        startVideoStreaming();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ===== 第二行：同时录制+推流、暂停录制 =====
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    (isRecordingVideo && isStreaming) ? '停止录推' : '同时录推',
                    (isRecordingVideo && isStreaming)
                        ? Icons.stop
                        : Icons.fiber_new,
                    (isRecordingVideo && isStreaming)
                        ? Colors.red
                        : Colors.deepPurple,
                    onRecordingAndVideoStreamingButtonPressed,
                  ),
                ),
                const SizedBox(width: 8),
                // 暂停录制（仅 Android）
                if (Platform.isAndroid)
                  Expanded(
                    child: _actionBtn(
                      isRecordingPaused ? '继续录制' : '暂停录制',
                      isRecordingPaused ? Icons.play_arrow : Icons.pause,
                      isRecordingPaused ? Colors.green : Colors.grey,
                      () async {
                        if (isRecordingPaused) {
                          await resumeVideoRecording();
                        } else {
                          await pauseVideoRecording();
                        }
                      },
                      enabled: isRecordingVideo,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),

            // ===== 第三行：相机切换 =====
            _sectionTitle('切换相机'),
            const SizedBox(height: 6),
            _cameraSwitcher(),
            const SizedBox(height: 14),

            // ===== 第四行：音频 + 闪光灯 =====
            Row(
              children: [
                Expanded(
                  child: _toggleRow('麦克风', Icons.mic, enableAudio, (v) async {
                    if (isControllerInitialized) {
                      await controller.switchAudio(v);
                      setState(() => enableAudio = v);
                    } else {
                      showInSnackBar('请先选择相机');
                    }
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _toggleRow('闪光灯', Icons.flash_on, isFlashLight, (
                    v,
                  ) async {
                    if (isControllerInitialized &&
                        _cameraDesc?.lensDirection ==
                            CameraLensDirection.back) {
                      setState(() => isFlashLight = v);
                      await controller.switchFlashLight(v);
                    } else {
                      showInSnackBar('请先切换到后置相机');
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ===== 平台专属设置 =====
            if (Platform.isAndroid) ...[
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),
              _sectionTitle('高级设置（Android）'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _toggleRow(
                      'BT.709 色彩',
                      Icons.color_lens,
                      _forceBt709,
                      (v) => setState(() => _forceBt709 = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _toggleRow(
                      'RTMP Ping',
                      Icons.network_ping,
                      _rtmpShouldSendPings,
                      (v) => setState(() => _rtmpShouldSendPings = v),
                    ),
                  ),
                ],
              ),
              if (_androidStreamStatsLine.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _androidStreamStatsLine,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],

            if (Platform.isIOS) ...[
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),
              _sectionTitle('高级设置（iOS）'),
              const SizedBox(height: 6),
              _toggleRow(
                '多任务相机 (iOS 17+)',
                Icons.tablet_mac,
                _iosMultitaskingCamera,
                (v) async {
                  setState(() => _iosMultitaskingCamera = v);
                  if (isControllerInitialized) {
                    try {
                      await controller.setMultitaskingCameraAccessEnabled(v);
                    } on CameraException catch (e) {
                      _showCameraException(e);
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('HaishinKit 视频编码示例'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: isControllerInitialized
                      ? () async {
                          try {
                            await controller.setVideoSettings(
                              expectedFrameRate: 30,
                              bitRateMode: 'average',
                            );
                            showInSnackBar('已设置帧率=30、码率模式=average');
                          } on CameraException catch (e) {
                            _showCameraException(e);
                          }
                        }
                      : null,
                ),
              ),
            ],

            const SizedBox(height: 12),
            // 缩略图预览
            _thumbnailWidget(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// 主操作按钮
  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }

  /// 开关行
  Widget _toggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? Colors.greenAccent : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.greenAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// 相机切换
  Widget _cameraSwitcher() {
    if (cameras.isEmpty) {
      return const Text('未检测到相机', style: TextStyle(color: Colors.white54));
    }
    return Wrap(
      spacing: 8,
      children: cameras.map((c) {
        final isSelected = _cameraDesc == c;
        return ChoiceChip(
          avatar: Icon(
            getCameraLensIcon(c.lensDirection),
            size: 18,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          label: Text(_cameraLensLabel(c.lensDirection)),
          selected: isSelected,
          selectedColor: Colors.blue,
          backgroundColor: const Color(0xFF2A2A2A),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
          ),
          onSelected: (selected) {
            if (selected && isControllerInitialized) {
              onSwitchCameras(c);
            }
          },
        );
      }).toList(),
    );
  }

  /// 缩略图
  Widget _thumbnailWidget() {
    if (imagePath == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近拍照',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(imagePath!),
            height: 80,
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // ========== 相机操作方法 ==========

  void onSwitchCameras(CameraDescription? cld) async {
    if (cld == null) return;
    try {
      setState(() => _cameraDesc = cld);
      await controller.switchCamera(cld.name!);
      await WakelockPlus.enable();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (cameraDescription == null) return;
    if (Platform.isMacOS == false) {
      await Permission.camera.request();
      await Permission.microphone.request();
    }
    try {
      await controller.initialize(cameraDescription);
      if (Platform.isIOS && _iosMultitaskingCamera) {
        try {
          await controller.setMultitaskingCameraAccessEnabled(true);
        } on CameraException catch (e) {
          _showCameraException(e);
        }
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.event != null) {
        final Map<dynamic, dynamic> event =
            controller.value.event as Map<dynamic, dynamic>;
        final String eventType = event['eventType'] as String;
        if ((eventType == "error" || eventType == 'rtmp_stopped') &&
            isStreaming) {
          showInSnackBar('相机异常: ${controller.value.errorDescription}');
          stopVideoStreaming();
        }
      }
    });
    if (mounted) setState(() {});
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void onTakePictureButtonPressed() async {
    if (!isControllerInitialized) {
      showInSnackBar('错误: 相机未初始化');
      return;
    }
    final Directory? extDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getTemporaryDirectory();
    if (extDir == null) return;
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    if (isTakingPicture) {
      showInSnackBar('正在拍照中，请稍候');
      return;
    }
    try {
      await controller.takePicture(filePath);
      if (mounted) {
        setState(() => imagePath = filePath);
        showInSnackBar('图片已保存');
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void onVideoRecordButtonPressed() async {
    if (!isControllerInitialized) {
      showInSnackBar('错误: 相机未初始化');
      return;
    }
    final Directory? extDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getTemporaryDirectory();
    if (extDir == null) return;
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';
    if (isRecordingVideo) {
      showInSnackBar('正在录制中');
      return;
    }
    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
      showInSnackBar('开始录制');
      await WakelockPlus.enable();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> startVideoStreaming() async {
    if (!isControllerInitialized) {
      showInSnackBar('请先选择相机');
      return;
    }
    if (isStreaming) {
      showInSnackBar('正在推流中');
      return;
    }
    String? myUrl = await _getUrl();
    if (myUrl!.isEmpty) {
      showInSnackBar('推流地址不能为空');
      return;
    }
    try {
      if (Platform.isAndroid) {
        await controller.setForceBt709Color(_forceBt709);
        await controller.setRtmpShouldSendPings(_rtmpShouldSendPings);
      }
      await controller.startVideoStreaming(myUrl);
      showInSnackBar('开始推流: $myUrl');
      await WakelockPlus.enable();
      _startAndroidStreamStatsTimer();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void onRecordingAndVideoStreamingButtonPressed() async {
    if (!isControllerInitialized) {
      showInSnackBar('错误: 相机未初始化');
      return;
    }
    if (isStreaming) {
      showInSnackBar('正在推流中');
      return;
    }
    String? myUrl = await _getUrl();
    if (myUrl!.isEmpty) {
      showInSnackBar('推流地址不能为空');
      return;
    }
    final Directory? extDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getTemporaryDirectory();
    if (extDir == null) return;
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';
    try {
      if (Platform.isAndroid) {
        await controller.setForceBt709Color(_forceBt709);
        await controller.setRtmpShouldSendPings(_rtmpShouldSendPings);
      }
      videoPath = filePath;
      await controller.startVideoRecordingAndStreaming(videoPath!, myUrl);
      showInSnackBar('开始录推');
      await WakelockPlus.enable();
      _startAndroidStreamStatsTimer();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void _startAndroidStreamStatsTimer() {
    if (!Platform.isAndroid) return;
    _streamStatsTimer?.cancel();
    _streamStatsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || !isStreaming) return;
      try {
        final s = await controller.getStreamStatistics();
        if (!mounted) return;
        setState(() {
          _androidStreamStatsLine =
              'fps=${s.fps}  RTT=${s.rttMicros}µs  已发送=${s.bytesSend}';
        });
      } catch (_) {}
    });
  }

  void _stopAndroidStreamStatsTimer() {
    _streamStatsTimer?.cancel();
    _streamStatsTimer = null;
    if (mounted) setState(() => _androidStreamStatsLine = '');
  }

  void stopRecordingOrStreaming() async {
    if (!isStreaming && !isRecordingVideo) {
      showInSnackBar('当前无录推操作');
      return;
    }
    try {
      await controller.stopRecordingOrStreaming();
      _stopAndroidStreamStatsTimer();
      await WakelockPlus.disable();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void stopVideoRecording() async {
    if (!isRecordingVideo) {
      showInSnackBar('未在录制');
      return;
    }
    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> pauseVideoRecording() async {
    try {
      if (!isRecordingVideo) {
        showInSnackBar('未在录制');
        return;
      }
      await controller.pauseVideoRecording();
      showInSnackBar('已暂停录制');
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    } catch (e) {
      showInSnackBar(e.toString());
    }
  }

  Future<void> resumeVideoRecording() async {
    try {
      if (!isRecordingVideo) {
        showInSnackBar('未在录制');
        return;
      }
      await controller.resumeVideoRecording();
      showInSnackBar('已继续录制');
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    } catch (e) {
      showInSnackBar(e.toString());
    }
  }

  Future<String?> _getUrl() async {
    String result = _textFieldController.text;
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('推流地址'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(
              hintText: 'rtmp://192.168.1.38:1935/live/stream',
              border: OutlineInputBorder(),
            ),
            onChanged: (String str) => result = str,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(''),
            ),
            ElevatedButton(
              child: const Text('确认'),
              onPressed: () => Navigator.pop(context, result),
            ),
          ],
        );
      },
    );
  }

  void stopVideoStreaming() async {
    if (!isControllerInitialized) {
      showInSnackBar('错误: 相机未初始化');
      return;
    }
    if (!isStreaming) {
      showInSnackBar('未在推流');
      return;
    }
    try {
      await controller.stopVideoStreaming();
      _stopAndroidStreamStatsTimer();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description ?? "No description found");
    showInSnackBar('错误: ${e.code} ${e.description ?? ""}');
  }
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CameraExampleHome());
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description ?? "No description found");
  }
  runApp(const CameraApp());
}

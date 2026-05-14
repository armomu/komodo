import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../webrtc/models/call_state.dart';
import '../controllers/video_call_controller.dart';

/// 简化版 1v1 视频通话页面
/// 参数通过 Get.arguments 传入 Map: {serverUrl, roomId, myUid, peerName}
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final VideoCallController _controller;
  late final String _serverUrl;
  late final String _roomId;
  late final String _myUid;
  late final String _peerName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    _serverUrl = args['serverUrl'] as String;
    _roomId = args['roomId'] as String;
    _myUid = args['myUid'] as String;
    _peerName = args['peerName'] as String;

    _controller = Get.put(VideoCallController(), permanent: true);
    _controller.initRenderers().then((_) {
      _controller.startCall(
        serverUrl: _serverUrl,
        roomId: _roomId,
        myUid: _myUid,
      );
    });
  }

  @override
  void dispose() {
    Get.delete<VideoCallController>(force: true);
    super.dispose();
  }

  Future<void> _handleBack() async {
    await _controller.endCall();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Obx(() {
            final state = _controller.callState.value;
            return Stack(
              children: [
                // 远端视频
                Positioned.fill(child: _buildRemoteVideo()),

                // 本地面中画
                Positioned(
                  top: 12,
                  right: 12,
                  width: 100,
                  height: 150,
                  child: _buildLocalVideo(),
                ),

                // 顶部栏
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildTopBar(),
                ),

                // 等待中
                if (state == CallState.calling ||
                    state == CallState.connecting)
                  Positioned.fill(child: _buildConnectingOverlay()),

                // 底部控制栏
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: _buildControls(state),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    return Obx(() {
      if (_controller.callState.value == CallState.connected) {
        return Stack(
          children: [
            RTCVideoView(
              _controller.remoteRenderer,
              mirror: false,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            // 对端名字标签
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _peerName,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      }
      return const ColoredBox(color: Colors.black);
    });
  }

  Widget _buildLocalVideo() {
    return Obx(() {
      if (!_controller.isCameraOn.value) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child:
                Icon(Icons.videocam_off, color: Colors.white54, size: 28),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            RTCVideoView(
              _controller.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _myUid,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            splashRadius: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _peerName,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            '正在连接...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待 $_peerName 加入...',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(CallState state) {
    if (state == CallState.ended || state == CallState.error) {
      return _buildEndedControls();
    }
    if (state == CallState.calling || state == CallState.incoming) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ctrlBtn(
            icon: Obx(() => Icon(
                  _controller.isMicOn.value ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                  size: 24,
                )),
            label: Obx(() => Text(
                  _controller.isMicOn.value ? '麦克风' : '静音',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )),
            onTap: _controller.toggleMic,
          ),
          _ctrlBtn(
            icon: Obx(() => Icon(
                  _controller.isCameraOn.value
                      ? Icons.videocam
                      : Icons.videocam_off,
                  color: Colors.white,
                  size: 24,
                )),
            label: Obx(() => Text(
                  _controller.isCameraOn.value ? '摄像头' : '关闭',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )),
            onTap: _controller.toggleCamera,
          ),
          _ctrlBtn(
            icon: const Icon(Icons.flip_camera_android,
                color: Colors.white, size: 24),
            label: const Text('翻转',
                style: TextStyle(color: Colors.white, fontSize: 10)),
            onTap: _controller.switchCamera,
          ),
          _ctrlBtn(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            label: const Text('挂断',
                style: TextStyle(color: Colors.red, fontSize: 10)),
            onTap: _handleBack,
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required Widget icon,
    required Widget label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          label,
        ],
      ),
    );
  }

  Widget _buildEndedControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '通话已结束',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('返回'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../models/call_state.dart';
import '../services/webrtc_controller.dart';

/// 视频通话页面——显示本地/远端画面和控制按钮。
class VideoCallPage extends StatefulWidget {
  final String serverUrl;
  final String roomId;
  final String myUid;

  const VideoCallPage({
    super.key,
    required this.serverUrl,
    required this.roomId,
    required this.myUid,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final WebrtcController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WebrtcController>();

    // 启动呼叫
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startCall(
        serverUrl: widget.serverUrl,
        roomId: widget.roomId,
        myUid: widget.myUid,
      );
    });
  }

  @override
  void dispose() {
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
                // 远端视频（主画面）
                Positioned.fill(
                  child: _buildRemoteVideo(),
                ),

                // 本地视频（画中画）
                Positioned(
                  top: 12,
                  right: 12,
                  width: 100,
                  height: 150,
                  child: _buildLocalVideo(),
                ),

                // 顶部信息
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildTopBar(),
                ),

                // 中间状态（等待/呼入）
                if (state == CallState.calling ||
                    state == CallState.incoming ||
                    state == CallState.connecting)
                  Positioned.fill(
                    child: _buildCallingOverlay(state),
                  ),

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

  // ==================== 构建组件 ====================

  Widget _buildRemoteVideo() {
    return Obx(() {
      if (_controller.callState.value == CallState.connected) {
        return RTCVideoView(
          _controller.remoteRenderer,
          mirror: false,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
      // 未连接时显示纯黑背景
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
            child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: RTCVideoView(
          _controller.localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // 返回按钮
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
        // 房间号
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '房间: ${widget.roomId}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCallingOverlay(CallState state) {
    String statusText;
    IconData statusIcon;

    switch (state) {
      case CallState.calling:
        statusText = '正在呼叫...';
        statusIcon = Icons.call_made;
        break;
      case CallState.incoming:
        statusText = '来电...';
        statusIcon = Icons.call_received;
        break;
      case CallState.connecting:
        statusText = '正在连接...';
        statusIcon = Icons.sync;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '对端用户加入后将自动接通',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          if (state == CallState.incoming) ...[
            const SizedBox(height: 32),
            // 接听按钮
            FilledButton.icon(
              onPressed: _controller.answerCall,
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text('接听'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(140, 48),
              ),
            ),
            const SizedBox(height: 12),
            // 挂断按钮
            OutlinedButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.call_end, color: Colors.red),
              label: const Text('拒绝', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(140, 48),
              ),
            ),
          ],
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
          _buildControlButton(
            icon: Obx(() => Icon(
                  _controller.isMicOn.value
                      ? Icons.mic
                      : Icons.mic_off,
                  color: Colors.white,
                  size: 24,
                )),
            label: Obx(() => Text(
                  _controller.isMicOn.value ? '麦克风' : '静音',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )),
            onTap: _controller.toggleMic,
          ),
          _buildControlButton(
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
          _buildControlButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 24),
            label: const Text('翻转', style: TextStyle(color: Colors.white, fontSize: 10)),
            onTap: _controller.switchCamera,
          ),
          _buildControlButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            label: const Text('挂断', style: TextStyle(color: Colors.red, fontSize: 10)),
            onTap: _handleBack,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
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

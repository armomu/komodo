import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../models/call_state.dart';
import '../services/webrtc_controller.dart';

/// 视频通话页面——Mesh 多人通话。
/// 远端画面根据人数自动切换布局：1人全屏、2人上下分屏、3-4人2x2网格。
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
                // 远端视频网格
                Positioned.fill(child: _buildRemoteVideosGrid()),

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

                // 等待/连接中遮罩
                if (state == CallState.calling ||
                    state == CallState.connecting)
                  Positioned.fill(
                    child: _buildConnectingOverlay(state),
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

  // ==================== 远端视频网格 ====================

  Widget _buildRemoteVideosGrid() {
    final peers = _controller.remotePeerUids;
    if (peers.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }

    final count = peers.length;

    // 1人全屏
    if (count == 1) {
      return _buildPeerVideo(peers[0]);
    }

    // 2人上下分屏（各占一半）
    if (count == 2) {
      return Column(
        children: [
          Expanded(child: _buildPeerVideo(peers[0])),
          SizedBox(height: 2, child: Container(color: Colors.black)),
          Expanded(child: _buildPeerVideo(peers[1])),
        ],
      );
    }

    // 3-4人 2x2 网格
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final rowCount = (count / crossAxisCount).ceil();
        final aspectRatio =
            (constraints.maxWidth / crossAxisCount) /
            (constraints.maxHeight / rowCount);
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: count,
          itemBuilder: (context, index) =>
              _buildPeerVideo(peers[index]),
        );
      },
    );
  }

  Widget _buildPeerVideo(String uid) {
    final renderer = _controller.rendererForPeer(uid);
    if (renderer == null) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Text(uid, style: const TextStyle(color: Colors.white54)),
        ),
      );
    }
    return Stack(
      children: [
        RTCVideoView(
          renderer,
          mirror: false,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
        // 左下角名字标签
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uid,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 本地视频 ====================

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
        child: Stack(
          children: [
            RTCVideoView(
              _controller.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            // 左下角名字标签
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.myUid,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==================== 顶部栏 ====================

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
          child: Obx(() {
            final count = _controller.remotePeerUids.length;
            return Text(
              '房间: ${widget.roomId}  ·  $count 人在线',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            );
          }),
        ),
      ],
    );
  }

  // ==================== 连接中遮罩 ====================

  Widget _buildConnectingOverlay(CallState state) {
    final statusText =
        state == CallState.calling ? '正在呼叫...' : '等待其他人加入...';
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sync, color: Colors.white, size: 48),
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
            '输入相同房间号的用户将自动连接',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==================== 控制栏 ====================

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
            icon: const Icon(Icons.flip_camera_android,
                color: Colors.white, size: 24),
            label: const Text('翻转',
                style: TextStyle(color: Colors.white, fontSize: 10)),
            onTap: _controller.switchCamera,
          ),
          _buildControlButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
            label: const Text('挂断',
                style: TextStyle(color: Colors.red, fontSize: 10)),
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

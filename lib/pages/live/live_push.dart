import 'package:flutter/material.dart';
import 'package:rtmp_streaming/camera.dart';

class LivePushPage extends StatefulWidget {
  const LivePushPage({super.key});

  @override
  State<LivePushPage> createState() => _LivePushPageState();
}

class _LivePushPageState extends State<LivePushPage> {
  // late RtmpStreamingController _controller;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();

    // _controller = RtmpStreamingController(
    //   url: "rtmp://192.168.1.100:1935/live/stream", // ⚠️换成你的电脑IP
    // );
  }

  void start() async {
    // await _controller.startStreaming();
    setState(() => isStreaming = true);
  }

  void stop() async {
    // await _controller.stopStreaming();
    setState(() => isStreaming = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎥 主播端")),
      body: Column(
        children: [
          // Expanded(
          //   child: RtmpStreamingView(controller: _controller),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: isStreaming ? null : start,
                child: const Text("开始直播"),
              ),
              ElevatedButton(
                onPressed: isStreaming ? stop : null,
                child: const Text("停止直播"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

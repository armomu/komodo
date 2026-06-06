import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'video_data.dart';
import 'video_action_bar.dart';
import 'video_bottom_info.dart';
import 'video_progress_bar.dart';
import 'fullscreen_video_page.dart';
import 'comment_bottom_sheet.dart';
import 'share_bottom_sheet.dart';

class VideoPage extends StatefulWidget {
  final VideoData data;
  final bool isActive;
  final bool lazyLoad;

  const VideoPage({
    required this.data,
    required this.isActive,
    this.lazyLoad = false,
    super.key,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = true;
  bool _showPlayIcon = false;
  String? _errorMessage;
  bool _isLandscapeVideo = false;

  @override
  void initState() {
    super.initState();
    if (!widget.lazyLoad) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_initialized) {
      final becameActiveNoLazy =
          widget.isActive && !oldWidget.isActive && !widget.lazyLoad;
      final lazyLiftedAndActive =
          widget.isActive && oldWidget.lazyLoad && !widget.lazyLoad;
      if (becameActiveNoLazy || lazyLiftedAndActive) {
        _initVideo();
      }
      return;
    }

    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      setState(() => _isPlaying = true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initVideo() async {
    if (_controller != null) return;
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.data.url),
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      final aspectRatio = _controller!.value.aspectRatio;
      _isLandscapeVideo = aspectRatio >= 1.4;
      if (widget.isActive) {
        _controller!.play();
      }
      if (mounted) {
        setState(() {
          _initialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '视频加载失败，请检查网络或视频地址';
        });
      }
    }
  }

  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenVideoPage(controller: _controller!),
      ),
    );
    _exitFullScreen();
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized || _controller == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _showPlayIcon = true;
      if (_isPlaying) {
        _controller!.play();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _isPlaying) setState(() => _showPlayIcon = false);
        });
      } else {
        _controller!.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          // 播放器主体
          if (_initialized && _controller != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  if (_isLandscapeVideo)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: _enterFullScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.screen_rotation,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '横屏观看',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          // 错误状态
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _initialized = false;
                      });
                      _initVideo();
                    },
                    child: const Text(
                      '重试',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          // 加载中
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 播放/暂停图标提示
          if (_showPlayIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),

          // 右侧操作栏
          if (_initialized && _controller != null)
            Positioned(
              right: 10,
              bottom: 120,
              child: VideoActionBar(
                likes: widget.data.likes,
                comments: widget.data.comments,
                favorites: widget.data.favorites,
                shares: widget.data.shares,
                onComment: () => showCommentBottomSheet(
                  context: context,
                  commentCount: widget.data.comments,
                ),
                onShare: showShareBottomSheet,
              ),
            ),

          // 进度条
          if (_initialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressBar(controller: _controller!),
            ),

          // 底部信息
          if (_initialized && _controller != null)
            Positioned(
              left: 16,
              right: 80,
              bottom: 30,
              child: VideoBottomInfo(
                username: widget.data.username,
                desc: widget.data.desc,
              ),
            ),
        ],
      ),
    );
  }
}

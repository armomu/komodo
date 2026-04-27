import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

// ══════════════════════════════════════════════════════════════════════════
// 可见性检测 Widget
// ══════════════════════════════════════════════════════════════════════════

class WidgetVisibilityInfo {
  final double visibleFraction;
  const WidgetVisibilityInfo(this.visibleFraction);
}

typedef VisibilityChangedCallback = void Function(WidgetVisibilityInfo);

class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VisibilityChangedCallback onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(const WidgetVisibilityInfo(1.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 数据模型
// ══════════════════════════════════════════════════════════════════════════

class VideoData {
  final String url;
  final String username;
  final String desc;
  final int likes;
  final int comments;
  final int favorites;
  final int shares;

  const VideoData({
    required this.url,
    required this.username,
    required this.desc,
    required this.likes,
    required this.comments,
    required this.favorites,
    required this.shares,
  });
}

// 视频数据列表
final List<VideoData> videoList = [
  const VideoData(
    url: 'http://192.168.1.38:8085/uploads/18126938-uhd_1440_2560_60fps.mp4',
    username: '@小猫咪',
    desc: '小猫咪，请给我来点cats~ 🐱',
    likes: 35640,
    comments: 13280,
    favorites: 8520,
    shares: 6720,
  ),
  const VideoData(
    url: 'https://www.w3schools.com/html/movie.mp4',
    username: '@海边的风',
    desc: '海浪声是最好的白噪音 🌊',
    likes: 19200,
    comments: 7600,
    favorites: 4500,
    shares: 3200,
  ),
  const VideoData(
    url: 'http://192.168.1.38:8085/uploads/13924703-hd_1920_1080_25fps.mp4',
    username: '@自然探索',
    desc: '慢下来，感受生活的美好 ✨',
    likes: 28900,
    comments: 9100,
    favorites: 6200,
    shares: 4300,
  ),
  const VideoData(
    url: 'https://www.w3schools.com/html/mov_bbb.mp4',
    username: '@蝴蝶记录者',
    desc: '诗和远方，一起去旅行吧~ 🌊',
    likes: 12800,
    comments: 5200,
    favorites: 3300,
    shares: 2100,
  ),
];

// ══════════════════════════════════════════════════════════════════════════
// 视频流控制器 — 关注/精选共享
// ══════════════════════════════════════════════════════════════════════════

class VideoFeedController extends GetxController {
  int currentPage = 0;

  /// Rx 响应式变量：feed 是否处于活跃（当前显示中的 tab）
  final RxBool isFeedActive = false.obs;

  void onPageChanged(int index) => currentPage = index;

  /// 通知 Feed 是否处于活跃状态（当前显示的 tab）
  void setFeedActive(bool active) {
    isFeedActive.value = active;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 视频流视图 — 关注和精选共用
// ══════════════════════════════════════════════════════════════════════════

class VideoFeedView extends StatefulWidget {
  final VideoFeedController controller;
  final int tabIndex;

  const VideoFeedView({
    required this.controller,
    required this.tabIndex,
    super.key,
  });

  @override
  State<VideoFeedView> createState() => _VideoFeedViewState();
}

class _VideoFeedViewState extends State<VideoFeedView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  bool _isViewVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.controller.currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(WidgetVisibilityInfo info) {
    final visible = info.visibleFraction > 0.1;
    if (visible != _isViewVisible) {
      setState(() {
        _isViewVisible = visible;
      });
    }
  }

  @override
  void didUpdateWidget(covariant VideoFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videoList.length,
        onPageChanged: (index) {
          widget.controller.onPageChanged(index);
          setState(() {});
        },
        itemBuilder: (context, index) {
          // 用 Obx 监听 isFeedActive 变化，确保 isFeedActive 变化时触发 VideoPage rebuild
          return Obx(() {
            final active =
                widget.controller.isFeedActive.value &&
                (index == widget.controller.currentPage);
            return VideoPage(
              key: ValueKey('video_$index'),
              data: videoList[index],
              isActive: active,
              lazyLoad: !_isViewVisible,
            );
          });
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 单个视频页
// ══════════════════════════════════════════════════════════════════════════

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
      // 尚未初始化时，满足以下任一条件就触发初始化：
      // 1. isActive 从 false → true，且不需要懒加载
      // 2. lazyLoad 从 true → false（视图变可见），且当前是活跃页
      final becameActiveNoLazy =
          widget.isActive && !oldWidget.isActive && !widget.lazyLoad;
      final lazyLiftedAndActive =
          widget.isActive && oldWidget.lazyLoad && !widget.lazyLoad;
      if (becameActiveNoLazy || lazyLiftedAndActive) {
        _initVideo();
      }
      return;
    }

    // 已初始化：根据 isActive 变化播放/暂停
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
    if (mounted) {
      setState(() {});
    }
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
                        onTap: () {
                          _enterFullScreen();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
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
          if (_initialized && _controller != null)
            Positioned(right: 10, bottom: 120, child: _buildRightActions()),
          if (_initialized && _controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(),
            ),
          if (_initialized && _controller != null)
            Positioned(
              left: 16,
              right: 80,
              bottom: 30,
              child: _buildBottomInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[700],
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: -8,
              left: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildActionButton(
          icon: Icons.favorite,
          color: Colors.red,
          count: widget.data.likes,
        ),
        const SizedBox(height: 20),
        // 评论按钮
        GestureDetector(
          onTap: _showCommentBottomSheet,
          child: Column(
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(widget.data.comments),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.star_rounded,
          color: Colors.amber,
          count: widget.data.favorites,
        ),
        const SizedBox(height: 20),
        // 分享按钮
        GestureDetector(
          onTap: _showShareBottomSheet,
          child: Column(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                child: const Icon(Icons.reply, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(widget.data.shares),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    bool flipHorizontal = false,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: flipHorizontal
                ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0))
                : Matrix4.identity(),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.data.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.data.desc,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (_controller == null || !_initialized) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: _controller!,
      builder: (context, VideoPlayerValue value, child) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 2,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0).toDouble(),
            onChanged: (value) {
              final newPosition = duration * value;
              _controller!.seekTo(newPosition);
            },
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 评论 BottomSheet
  // ═════════════════════════════════════════════════════════════════════════

  void _showCommentBottomSheet() {
    final comments = [
      const _CommentItem(
        username: '@观众小明',
        avatar: Icons.person,
        content: '这个视频拍得真好！',
        time: '3分钟前',
        likes: 128,
      ),
      const _CommentItem(
        username: '@旅行者',
        avatar: Icons.person,
        content: '收藏了，下次去这里打卡 📍',
        time: '15分钟前',
        likes: 56,
      ),
      const _CommentItem(
        username: '@摄影师小王',
        avatar: Icons.person,
        content: '运镜很稳，用的什么稳定器？',
        time: '1小时前',
        likes: 42,
      ),
      const _CommentItem(
        username: '@美食家',
        avatar: Icons.person,
        content: '旁边那家餐厅也超好吃！推荐大家去试试',
        time: '2小时前',
        likes: 89,
      ),
      const _CommentItem(
        username: '@户外达人',
        avatar: Icons.person,
        content: '这个地方我去过，风景确实绝了',
        time: '3小时前',
        likes: 37,
      ),
    ];

    Get.bottomSheet(
      SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 顶部把手
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.data.comments} 条评论',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // 评论列表
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.white10,
                    height: 1,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment);
                  },
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // 评论输入框
              _buildCommentInput(),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildCommentItem(_CommentItem comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            child: Icon(comment.avatar, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      comment.time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '回复',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(
                Icons.favorite_border,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(height: 2),
              Text(
                '${comment.likes}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final controller = TextEditingController();
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.image, color: Colors.white70),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.alternate_email, color: Colors.white70),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // 微笑图标按钮
            IconButton(
              icon: const Icon(Icons.mood, color: Colors.white70),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 分享 BottomSheet
  // ═════════════════════════════════════════════════════════════════════════

  void _showShareBottomSheet() {
    final shareItems = [
      const _ShareItem(icon: Icons.link, label: '复制链接', color: Colors.blue),
      const _ShareItem(icon: Icons.chat, label: '微信', color: Colors.green),
      const _ShareItem(icon: Icons.wechat, label: '朋友圈', color: Colors.green),
      const _ShareItem(icon: Icons.qr_code, label: '二维码', color: Colors.purple),
      const _ShareItem(
        icon: Icons.shape_line,
        label: '系统分享',
        color: Colors.grey,
      ),
      const _ShareItem(
        icon: Icons.bookmark_border,
        label: '收藏',
        color: Colors.amber,
      ),
      const _ShareItem(icon: Icons.report, label: '举报', color: Colors.red),
    ];

    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部把手
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              // 分享图标网格
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: shareItems.length,
                  itemBuilder: (context, index) {
                    final item = shareItems[index];
                    return _buildShareItem(item);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 取消按钮
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: const Center(
                    child: Text(
                      '取消',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildShareItem(_ShareItem item) {
    return GestureDetector(
      onTap: () {
        Get.back();
        Get.snackbar(
          '分享',
          '已选择${item.label}',
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 评论数据模型（文件私有）
// ══════════════════════════════════════════════════════════════════════════

class _CommentItem {
  final String username;
  final IconData avatar;
  final String content;
  final String time;
  final int likes;

  const _CommentItem({
    required this.username,
    required this.avatar,
    required this.content,
    required this.time,
    required this.likes,
  });
}

class _ShareItem {
  final IconData icon;
  final String label;
  final Color color;

  const _ShareItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// 全屏视频页面（横屏观看体验）
// ══════════════════════════════════════════════════════════════════════════

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPage({required this.controller, super.key});

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.height *
                      controller.value.aspectRatio,
                  height: MediaQuery.of(context).size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            if (_showControls) ...[
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return GestureDetector(
                      onTap: () {
                        if (value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _buildFullScreenProgressBar(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenProgressBar() {
    if (!widget.controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, VideoPlayerValue value, child) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0).toDouble(),
                onChanged: (value) {
                  final newPosition = duration * value;
                  widget.controller.seekTo(newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fmt(position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    fmt(duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

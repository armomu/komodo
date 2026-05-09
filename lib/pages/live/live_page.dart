import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'gift_lottie_overlay.dart';

// ═════════════════════════════════════════════════════════════════════════
// 直播间页面（含飞行弹幕）
// ═════════════════════════════════════════════════════════════════════════

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller = VideoPlayerController.networkUrl(
    Uri.parse('https://www.youtube.com/watch?v=_lvYy_YXZxQ'),
  );

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 飞行弹幕 Widget 列表 —— 每条弹幕是独立 StatefulWidget，飞出后自动销毁
  final List<Widget> _flyingWidgets = [];
  int _danmakuIdCounter = 0;

  // 弹幕轨道系统 —— 防止弹幕堆叠遮挡
  static const int _trackCount = 5; // 5 条轨道
  static const List<double> _trackPercents = [0.12, 0.20, 0.28, 0.36, 0.44]; // 各轨道位置

  /// 弹幕飞行轨迹记录：id + 飞行时间窗口 + 所在轨道
  final List<_DanmakuTrack> _danmakuTracks = [];

  // 左下角聊天弹幕数据
  final List<_DanmakuItem> _danmakuList = [
    const _DanmakuItem(
      '公告',
      '直播间严禁黄赌毒，共建绿色健康网络环境',
      Colors.white,
    ),
    const _DanmakuItem('西二旗华仔', '画质清晰，点赞！', Color(0xFF9C27B0)),
    const _DanmakuItem('小米女神', '第一次来，支持一下', Color(0xFF2196F3)),
    const _DanmakuItem('北漂小王', '求关注求关注', Color(0xFF00BCD4)),
  ];

  bool _showInput = false;
  String? _playUrl;

  void _initVlcPlayer(String url) {
    _controller.dispose();
    _playUrl = url;
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    // 进入直播间后，依次播放默认聊天信息的飞行弹幕
    _playInitialDanmaku();
  }

  /// 进入直播间时，依次触发默认聊天信息的飞行弹幕
  void _playInitialDanmaku() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _danmakuList.length; i++) {
        final item = _danmakuList[i];
        Future.delayed(Duration(milliseconds: 300 + i * 250), () {
          if (mounted) {
            _addFlyingDanmaku('${item.username}：${item.content}', item.color);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.dispose();
    }
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoArea(),
          _buildTopGradient(),
          _buildTopBar(),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          if (!_showInput) _buildDanmakuArea(),
          // 飞行弹幕层
          ..._flyingWidgets,
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_playUrl == null || !_controller.value.isInitialized) {
      return _buildVideoPlaceholder();
    }
    return GestureDetector(
      onTap: () {},
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tap_and_play, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('还没有输入源', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildAnchorInfo()),
            const SizedBox(width: 20),
            _buildViewerInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorInfo() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showUrlInputDialog,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF3A3A3A),
              child: Icon(Icons.person, color: Colors.white70, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '小毛驴的毛…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '粉丝 938',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            '关注',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildViewerInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 54, height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 12.0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [Colors.purple[200], Colors.teal[200], Colors.orange[200]][i],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(Icons.person, size: 14, color: Colors.grey[700]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('8888',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            Navigator.of(context).pop();
          },
          child: Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildDanmakuArea() {
    final maxWidth = MediaQuery.of(context).size.width * 0.80;
    return Positioned(
      left: 8, bottom: 82,
      child: SizedBox(
        width: maxWidth, height: 200,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _danmakuList.length,
          itemBuilder: (context, index) {
            final item = _danmakuList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${item.username}：',
                              style: TextStyle(color: item.color, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: item.content,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_showInput) return _buildInputMode();
    return _buildActionBar();
  }

  Widget _buildActionBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safePadding = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, safePadding + 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showInput = true),
                      child: const Text('说点什么…',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showToast('表情面板（待实现）'),
                    child: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70, size: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildBottomBtn(icon: Icons.shopping_cart_outlined, onTap: () => _showToast('购物车')),
          const SizedBox(width: 8),
          _buildBottomBtn(
            icon: Icons.card_giftcard,
            color: Colors.orange[300]!,
            onTap: _showGiftSheet,
          ),
          const SizedBox(width: 8),
          _buildBottomBtn(icon: Icons.share_outlined, onTap: _showShareSheet),
        ],
      ),
    );
  }

  Widget _buildInputMode() {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safePadding = MediaQuery.of(context).padding.bottom;
    final totalPadding = bottomPadding + (safePadding > 0 ? safePadding : 8.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(8, 8, 8, totalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '说点什么…',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF3A3A3A),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _showInput = false),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Color(0xFF3A3A3A), shape: BoxShape.circle),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBtn({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: color, size: 22)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 交互方法
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _danmakuList.add(_DanmakuItem('我', text, Colors.red));
      _chatController.clear();
      _showInput = false;
      _addFlyingDanmaku(text, Colors.red);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 添加一条飞行弹幕 —— 创建独立 Widget 加入列表，飞出后自动移除
  void _addFlyingDanmaku(String text, Color color) {
    final id = _danmakuIdCounter++;
    final now = DateTime.now();
    final endTime = now.add(const Duration(milliseconds: 4000));

    // 找到第一个在此时刻空闲的轨道
    int trackIndex = _findFreeTrack(now);

    // 记录轨迹信息，用于碰撞检测
    final track = _DanmakuTrack(
      id: id,
      startTime: now,
      endTime: endTime,
      topPercent: _trackPercents[trackIndex],
    );
    _danmakuTracks.add(track);

    final key = ValueKey(id);
    setState(() {
      _flyingWidgets.add(
        _FlyingDanmakuItem(
          key: key,
          text: text,
          color: color,
          topPercent: _trackPercents[trackIndex],
          onComplete: () {
            // 清理轨迹记录和 Widget
            _danmakuTracks.removeWhere((t) => t.id == id);
            setState(() {
              _flyingWidgets.removeWhere((w) {
                if (w is _FlyingDanmakuItem) {
                  return (w.key as ValueKey?)?.value == id;
                }
                return false;
              });
            });
          },
        ),
      );
      // 最多保留 8 条，防止叠加太多
      if (_flyingWidgets.length > 8) {
        final oldest = _flyingWidgets.removeAt(0);
        if (oldest is _FlyingDanmakuItem) {
          final oldestId = (oldest.key as ValueKey?)?.value;
          if (oldestId != null) {
            _danmakuTracks.removeWhere((t) => t.id == oldestId);
          }
        }
      }
    });
  }

  /// 找到第一个在指定时刻空闲的轨道索引
  int _findFreeTrack(DateTime time) {
    for (int i = 0; i < _trackCount; i++) {
      final trackPercent = _trackPercents[i];
      bool isOccupied = _danmakuTracks.any((t) =>
        (t.topPercent - trackPercent).abs() < 0.01 &&
        time.isAfter(t.startTime) &&
        time.isBefore(t.endTime)
      );
      if (!isOccupied) return i;
    }
    // 所有轨道都被占用，返回时间最早的轨道
    return 0;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController(
      text: _playUrl ?? 'http://192.168.1.38:8085/live/stream.m3u8',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        actionsPadding: const EdgeInsets.all(16),
        title: const Text('输入播放地址', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '请输入RTMP/HTTPS直播地址',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop();
                _initVlcPlayer(url);
              }
            },
            child: const Text('确认', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet() {
    GiftBottomSheet.show(context, (gift) {
      Future.delayed(const Duration(milliseconds: 100), () {
        LottieOverlayManager.playGiftAnimation(context, gift);
      });
    });
  }

  void _showShareSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制链接'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════════════════════

class _DanmakuItem {
  final String username;
  final String content;
  final Color color;
  const _DanmakuItem(this.username, this.content, this.color);
}

/// 弹幕飞行轨迹记录，用于轨道碰撞检测
class _DanmakuTrack {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double topPercent;

  const _DanmakuTrack({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.topPercent,
  });
}

// ═══════════════════════════════════════════════════════════════
// 飞行弹幕 Widget —— 每条独立管理动画，飞出屏幕即销毁
// ═══════════════════════════════════════════════════════════════

class _FlyingDanmakuItem extends StatefulWidget {
  final String text;
  final Color color;
  final double topPercent;
  final VoidCallback onComplete;

  const _FlyingDanmakuItem({
    required this.text,
    required this.color,
    required this.topPercent,
    required this.onComplete,
    super.key,
  });

  @override
  State<_FlyingDanmakuItem> createState() => _FlyingDanmakuItemState();
}

class _FlyingDanmakuItemState extends State<_FlyingDanmakuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        // 用 SlideTransition 思路：通过 left 定位
        final textWidth = _estimateTextWidth();
        final totalDistance = screenWidth + textWidth;
        final currentX = screenWidth - _ctrl.value * totalDistance;

        return Positioned(
          left: currentX,
          top: widget.topPercent * MediaQuery.of(context).size.height,
          child: _buildContent(),
        );
      },
    );
  }

  double _estimateTextWidth() {
    const charWidth = 14.0;
    return (widget.text.length * charWidth + 24).clamp(60, 300);
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
  }
}

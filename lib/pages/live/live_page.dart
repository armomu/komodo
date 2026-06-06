import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'gift_lottie_overlay.dart';
import 'models/danmaku_item.dart';
import 'models/danmaku_track.dart';
import 'widgets/flying_danmaku_item.dart';
import 'widgets/video_player_area.dart';
import 'widgets/top_gradient.dart';
import 'widgets/anchor_info_bar.dart';
import 'widgets/viewer_info_bar.dart';
import 'widgets/danmaku_chat_list.dart';
import 'widgets/live_action_bar.dart';
import 'widgets/chat_input_bar.dart';

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
  static const int _trackCount = 5;
  static const List<double> _trackPercents = [0.12, 0.20, 0.28, 0.36, 0.44];

  /// 弹幕飞行轨迹记录：id + 飞行时间窗口 + 所在轨道
  final List<DanmakuTrack> _danmakuTracks = [];

  // 左下角聊天弹幕数据
  final List<DanmakuItem> _danmakuList = [
    const DanmakuItem('公告', '直播间严禁黄赌毒，共建绿色健康网络环境', Colors.white),
    const DanmakuItem('西二旗华仔', '画质清晰，点赞！', Color(0xFF9C27B0)),
    const DanmakuItem('小米女神', '第一次来，支持一下', Color(0xFF2196F3)),
    const DanmakuItem('北漂小王', '求关注求关注', Color(0xFF00BCD4)),
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

    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 状态栏背景色
      statusBarIconBrightness: Brightness.light, // 图标亮度：light=白色，dark=黑色
      statusBarBrightness: Brightness.light, // iOS 专用
    );

    // 应用到当前界面
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
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
    _controller.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
          const TopGradient(),
          // 全屏背景图 — 模拟直播画面
          Image.network(
            'https://picsum.photos/seed/mv3/800/800',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          VideoPlayerArea(
            controller: _controller,
            playUrl: _playUrl,
            onTap: () {},
          ),
          _buildTopBar(),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          if (!_showInput)
            DanmakuChatList(
              danmakuList: _danmakuList,
              scrollController: _scrollController,
            ),
          // 飞行弹幕层
          ..._flyingWidgets,
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: AnchorInfoBar(onAvatarTap: _showUrlInputDialog)),
            const SizedBox(width: 20),
            ViewerInfoBar(onClose: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_showInput) {
      return ChatInputBar(
        controller: _chatController,
        onSend: _sendMessage,
        onClose: () => setState(() => _showInput = false),
      );
    }
    return LiveActionBar(
      onChatTap: () => setState(() => _showInput = true),
      onEmojiTap: () => _showToast('表情面板（待实现）'),
      onCartTap: () => _showToast('购物车'),
      onGiftTap: _showGiftSheet,
      onShareTap: _showShareSheet,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 交互方法
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _danmakuList.add(DanmakuItem('我', text, Colors.red));
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
    final track = DanmakuTrack(
      id: id,
      startTime: now,
      endTime: endTime,
      topPercent: _trackPercents[trackIndex],
    );
    _danmakuTracks.add(track);

    final key = ValueKey(id);
    setState(() {
      _flyingWidgets.add(
        FlyingDanmakuItem(
          key: key,
          text: text,
          color: color,
          topPercent: _trackPercents[trackIndex],
          onComplete: () {
            // 清理轨迹记录和 Widget
            _danmakuTracks.removeWhere((t) => t.id == id);
            setState(() {
              _flyingWidgets.removeWhere((w) {
                if (w is FlyingDanmakuItem) {
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
        if (oldest is FlyingDanmakuItem) {
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
      bool isOccupied = _danmakuTracks.any(
        (t) =>
            (t.topPercent - trackPercent).abs() < 0.01 &&
            time.isAfter(t.startTime) &&
            time.isBefore(t.endTime),
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
    if (!mounted) return;
    final urlController = TextEditingController(
      text: _playUrl ?? 'http://192.168.1.38:8085/live/stream.m3u8',
    );
    // ignore: use_build_context_synchronously
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
        if (!mounted) return;
        LottieOverlayManager.playGiftAnimation(context, gift);
      });
    });
  }

  void _showShareSheet() {
    AppBottomSheet.show(
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
    );
  }
}

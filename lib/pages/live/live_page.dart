import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'package:komodo/config/base_url.dart';
import 'package:video_player/video_player.dart';
import 'controllers/live_repository.dart';
import 'controllers/live_ws_client.dart';
import 'gift_lottie_overlay.dart';
import 'models/danmaku_item.dart';
import 'models/danmaku_track.dart';
import 'models/live_models.dart';
import 'widgets/flying_danmaku_item.dart';
import 'widgets/video_player_area.dart';
import 'widgets/top_gradient.dart';
import 'widgets/anchor_info_bar.dart';
import 'widgets/viewer_info_bar.dart';
import 'widgets/danmaku_chat_list.dart';
import 'widgets/live_action_bar.dart';
import 'widgets/chat_input_bar.dart';

/// 直播间页面 — 全量 WS 驱动
class LivePage extends StatefulWidget {
  final String? roomId;

  const LivePage({super.key, this.roomId});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with SingleTickerProviderStateMixin {
  late final LiveWsClient _liveWs;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── 直播间数据 ──
  String? _roomId;
  LiveRoom? _roomDetail;
  bool _isLoading = true;
  String? _loadError;

  // ── 主播信息（静态展示） ──
  String _anchorNickname = '主播';
  String _anchorAvatar = '';

  // ── 在线观众（WS 驱动） ──
  final List<String> _viewerAvatars = [];
  int _viewerCount = 0;

  // ── 公告 ──
  String _announcement = '';

  // ── 飞行弹幕 ──
  final List<Widget> _flyingWidgets = [];
  int _danmakuIdCounter = 0;
  static const int _trackCount = 5;
  static const List<double> _trackPercents = [0.12, 0.20, 0.28, 0.36, 0.44];
  final List<DanmakuTrack> _danmakuTracks = [];

  // ── 左下角聊天列表 ──
  final List<DanmakuItem> _danmakuList = [];

  // ── 视频播放 ──
  VideoPlayerController? _videoController;
  String? _hlsUrl;

  bool _showInput = false;

  // ── Stream 订阅 ──
  StreamSubscription? _onViewerListSub;
  StreamSubscription? _onViewerJoinedSub;
  StreamSubscription? _onViewerLeftSub;
  StreamSubscription? _onNewCommentSub;
  StreamSubscription? _onNewGiftSub;
  StreamSubscription? _onAnnouncementSub;
  StreamSubscription? _onLiveEndedSub;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    _liveWs = Get.find<LiveWsClient>();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ));

    _initRoom();
  }

  Future<void> _initRoom() async {
    if (_roomId == null) {
      setState(() => _loadError = '未指定直播间');
      return;
    }

    // 1. 加载房间详情
    final detailRes = await LiveRepository.getRoomDetail(_roomId!);
    if (!detailRes.isSuccess || detailRes.data == null) {
      setState(() {
        _loadError = '加载直播间失败: ${detailRes.message}';
        _isLoading = false;
      });
      return;
    }

    final room = detailRes.data!;
    _roomDetail = room;
    _anchorNickname = room.hostNickname ?? '主播';
    _anchorAvatar = room.hostAvatar ?? '';
    _announcement = room.announcement;

    // 2. 记录观看
    LiveRepository.recordView(_roomId!);

    // 3. 初始化视频播放（HLS）
    _initHlsPlayer(room.rtmpKey);

    // 4. 连接 WS 并加入房间
    await _connectWs();

    setState(() => _isLoading = false);
  }

  void _initHlsPlayer(String rtmpKey) {
    final hlsUrl = '${BaseUrl.host()}/live/$rtmpKey.m3u8';
    _hlsUrl = hlsUrl;
    debugPrint('[LivePage] HLS URL: $hlsUrl');

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(hlsUrl))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _videoController?.play();
        }).catchError((e) {
          debugPrint('[LivePage] 视频播放初始化失败: $e');
          // 推流尚未开始时不报错，留空画面
        });
    } catch (e) {
      debugPrint('[LivePage] 创建视频控制器失败: $e');
    }
  }

  Future<void> _connectWs() async {
    if (!_liveWs.isConnected.value) {
      await _liveWs.connect();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!_liveWs.isAuthenticated.value) {
      // 等待认证
      await Future.delayed(const Duration(seconds: 1));
    }

    // 订阅 WS 事件
    _onViewerListSub = _liveWs.onViewerList.listen((viewers) {
      if (!mounted) return;
      setState(() {
        _viewerAvatars
          ..clear()
          ..addAll(viewers.map((v) => v.avatar).take(8));
        _viewerCount = _liveWs.viewerCount.value;
      });
    });

    _onViewerJoinedSub = _liveWs.onViewerJoined.listen((viewer) {
      if (!mounted) return;
      setState(() {
        _viewerAvatars.add(viewer.avatar);
        if (_viewerAvatars.length > 8) _viewerAvatars.removeAt(0);
        _viewerCount = _liveWs.viewerCount.value;
      });
    });

    _onViewerLeftSub = _liveWs.onViewerLeft.listen((_) {
      if (!mounted) return;
      setState(() {
        _viewerCount = _liveWs.viewerCount.value;
      });
    });

    _onNewCommentSub = _liveWs.onNewComment.listen((data) {
      if (!mounted) return;
      _addComment(data.nickname, data.message);
    });

    _onNewGiftSub = _liveWs.onNewGift.listen((data) {
      if (!mounted) return;
      if (mounted) {
        LottieOverlayManager.playGiftAnimation(
          context,
          GiftData(
            name: data.giftName,
            lottiePath: data.lottiePath,
            iconName: data.giftIcon,
          ),
        );
      }
      _addComment(data.senderNickname, '赠送了 ${data.giftName}');
    });

    _onAnnouncementSub = _liveWs.onAnnouncementUpdated.listen((text) {
      if (!mounted) return;
      setState(() => _announcement = text);
    });

    _onLiveEndedSub = _liveWs.onLiveEnded.listen((_) {
      if (!mounted) return;
      Get.snackbar('直播已结束', '主播已关闭直播',
          backgroundColor: Colors.black87, colorText: Colors.white);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    });

    // 加入房间
    _liveWs.joinRoom(_roomId!);
  }

  /// 添加一条评论到弹幕列表 + 飞行弹幕
  void _addComment(String nickname, String message) {
    final colors = [
      Colors.white,
      const Color(0xFF9C27B0),
      const Color(0xFF2196F3),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
    ];
    final color = colors[_danmakuList.length % colors.length];

    setState(() {
      _danmakuList.add(DanmakuItem(nickname, message, color));
      _addFlyingDanmaku('$nickname：$message', color);
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

  @override
  void dispose() {
    // 离开 WS 房间
    if (_roomId != null && _liveWs.isConnected.value) {
      _liveWs.leaveRoom(_roomId!);
    }

    // 取消订阅
    _onViewerListSub?.cancel();
    _onViewerJoinedSub?.cancel();
    _onViewerLeftSub?.cancel();
    _onNewCommentSub?.cancel();
    _onNewGiftSub?.cancel();
    _onAnnouncementSub?.cancel();
    _onLiveEndedSub?.cancel();

    _videoController?.dispose();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _loadError != null
              ? _buildErrorView()
              : _buildLiveView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Text(_loadError!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const TopGradient(),
        // 全屏背景
        Image.network(
          'https://picsum.photos/seed/${_roomId ?? 'live'}/800/800',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        // 视频播放区域（如果可用）
        if (_videoController != null)
          VideoPlayerArea(
            controller: _videoController!,
            playUrl: _hlsUrl,
            onTap: () {},
          ),
        // 公告条
        if (_announcement.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('📢 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      _announcement,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // 顶部栏
        SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AnchorInfoBar(
                    nickname: _anchorNickname,
                    avatar: _anchorAvatar,
                    fansText: '粉丝 0',
                  ),
                ),
                const SizedBox(width: 20),
                ViewerInfoBar(
                  viewerCount: _viewerCount,
                  viewerAvatars: _viewerAvatars,
                  onClose: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
        // 底部操作栏
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
        // 弹幕列表
        if (!_showInput)
          DanmakuChatList(
            danmakuList: _danmakuList,
            scrollController: _scrollController,
          ),
        // 飞行弹幕层
        ..._flyingWidgets,
      ],
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
      onEmojiTap: () {}, // 静态图标，不做交互
      onCartTap: () {}, // 静态图标，不做交互
      onGiftTap: _showGiftSheet,
      onShareTap: () {}, // 静态图标，不做交互
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  交互方法
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    // 通过 WS 发送评论（服务器会广播给所有人）
    if (_liveWs.isConnected.value) {
      _liveWs.sendComment(_roomId!, text);
    }

    // 本地显示
    _addComment('我', text);
    _chatController.clear();
    setState(() => _showInput = false);
  }

  void _addFlyingDanmaku(String text, Color color) {
    final id = _danmakuIdCounter++;
    final now = DateTime.now();
    final endTime = now.add(const Duration(milliseconds: 4000));
    int trackIndex = _findFreeTrack(now);
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
    return 0;
  }

  void _showGiftSheet() {
    if (_roomId == null) return;

    GiftBottomSheet.show(context, (gift) {
      // 通过 WS 发送礼物
      if (_liveWs.isConnected.value) {
        _liveWs.sendGift(_roomId!, gift.name, gift.iconName, gift.lottiePath);
      }

      // 本地也播放动画（因为 WS 广播包括发送者自己）
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        LottieOverlayManager.playGiftAnimation(context, gift);
      });
    });
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
}

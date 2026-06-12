import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:komodo/config/base_url.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_streaming/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'controllers/live_repository.dart';
import 'controllers/live_ws_client.dart';
import 'gift_lottie_overlay.dart';
import 'models/danmaku_item.dart';
import 'models/danmaku_track.dart';
import 'models/live_models.dart';
import 'widgets/flying_danmaku_item.dart';
import 'widgets/top_gradient.dart';
import 'widgets/anchor_info_bar.dart';
import 'widgets/viewer_info_bar.dart';
import 'widgets/danmaku_chat_list.dart';
import 'widgets/live_action_bar.dart';
import 'widgets/chat_input_bar.dart';

/// 直播间页面 — 支持主播/观众双模式
///
/// 主播端：本地相机预览 + RTMP 推流 + WS 全功能（评论/礼物/观众）
/// 观众端：远程 HLS 视频 + WS 全功能（评论/礼物/观众）
class LivePage extends StatefulWidget {
  final String? roomId;
  final bool isAnchor;

  const LivePage({super.key, this.roomId, this.isAnchor = false});

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
  final String _anchorFansText = '粉丝 0';

  // ── 在线观众（WS 驱动） ──
  final List<String> _viewerAvatars = [];
  int _viewerCount = 0;

  // ── 公告 ──
  String _announcement = '';
  final TextEditingController _announcementController = TextEditingController();

  // ── 飞行弹幕 ──
  final List<Widget> _flyingWidgets = [];
  int _danmakuIdCounter = 0;
  static const int _trackCount = 5;
  static const List<double> _trackPercents = [0.12, 0.20, 0.28, 0.36, 0.44];
  final List<DanmakuTrack> _danmakuTracks = [];

  // ── 左下角聊天列表 ──
  final List<DanmakuItem> _danmakuList = [];

  // ── 观众端视频 ──
  VideoPlayerController? _videoController;
  String? _hlsUrl;

  // ── 主播端推流 ──
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  bool _isStreaming = false;
  Timer? _statsTimer;
  String _statsLine = '';
  String _rtmpUrl = '';

  bool _showInput = false;
  bool get _isAnchor => widget.isAnchor;

  // ── Stream 订阅 ──
  StreamSubscription? _onViewerListSub;
  StreamSubscription? _onViewerJoinedSub;
  StreamSubscription? _onViewerLeftSub;
  StreamSubscription? _onNewCommentSub;
  StreamSubscription? _onNewGiftSub;
  StreamSubscription? _onAnnouncementSub;
  StreamSubscription? _onLiveEndedSub;
  StreamSubscription? _onRoomUnavailableSub;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomId;
    _liveWs = Get.find<LiveWsClient>();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );

    _initRoom();
  }

  Future<void> _initRoom() async {
    if (_roomId == null) {
      setState(() => _loadError = '未指定直播间');
      return;
    }

    // 加载房间详情
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
    _rtmpUrl = 'rtmp://192.168.1.38:1935/live/${room.rtmpKey}';

    // 先结束 loading 显示直播画面，再异步初始化其余功能
    setState(() => _isLoading = false);

    // 异步初始化（不阻塞 UI）
    if (_isAnchor) {
      _initCamera(); // 不 await
    } else {
      LiveRepository.recordView(_roomId!);
      _initHlsPlayer(_roomDetail?.rtmpKey ?? '');
    }

    // 连接 WS（异步），就绪后标记直播开始再推流
    _connectWs().then((connected) {
      if (!connected || !_isAnchor) return;

      // WS 就绪后立即发 start-live，让房间出现在列表中
      _liveWs.startLive(_roomId!);
      debugPrint('[LivePage] start-live 已发送');

      // 稍后启动推流
      _startPushStreaming();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  主播端 — 相机 + 推流
  // ═══════════════════════════════════════════════════════════════

  Future<void> _initCamera() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final cameraStatus = await Permission.camera.request().timeout(
          const Duration(seconds: 5),
        );
        final micStatus = await Permission.microphone.request().timeout(
          const Duration(seconds: 5),
        );
        if (!cameraStatus.isGranted || !micStatus.isGranted) {
          setState(() => _permissionDenied = true);
          return;
        }
      }

      final cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
      );
      if (cameras.isEmpty) {
        setState(() => _permissionDenied = true);
        return;
      }
      _cameras = cameras;
      _currentCameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;

      _cameraController = CameraController(
        ResolutionPreset.medium,
        enableAudio: true,
        androidUseOpenGL: true,
      );
      await _cameraController!
          .initialize(cameras[_currentCameraIndex])
          .timeout(const Duration(seconds: 10));
      _cameraController!.addListener(() {
        // if (mounted) setState(() {});
        if (_cameraController!.value.event != null) {
          final event = _cameraController!.value.event as Map<dynamic, dynamic>;
          if ((event['eventType'] == "error" ||
                  event['eventType'] == 'rtmp_stopped') &&
              _isStreaming) {
            _showToast('推流异常，已停止');
            _stopPushStreaming();
          }
        }
      });
      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('[LivePage] 相机初始化失败: $e');
    }
  }

  Future<void> _startPushStreaming() async {
    if (_rtmpUrl.isEmpty || _isStreaming) return;

    // 等待相机就绪（最多等 15 秒）
    for (int i = 0; i < 30; i++) {
      if (_cameraReady) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!_cameraReady || _cameraController == null) {
      debugPrint('[LivePage] 相机未就绪，跳过推流');
      return;
    }

    try {
      await _cameraController!.startVideoStreaming(_rtmpUrl);
      await WakelockPlus.enable();
      setState(() => _isStreaming = true);
      _startStatsTimer();
      _showToast('开始推流');
    } catch (e) {
      debugPrint('[LivePage] 推流失败: $e');
      _showToast('推流失败');
    }
  }

  Future<void> _stopPushStreaming() async {
    if (!_isStreaming) return;
    try {
      await _cameraController!.stopVideoStreaming();
      await WakelockPlus.disable();
      _stopStatsTimer();

      final ready = await _liveWs.waitForAuth();
      if (ready) {
        _liveWs.endLive(_roomId!);
      }
    } catch (e) {
      debugPrint('[LivePage] 停止推流失败: $e');
    } finally {
      if (mounted) setState(() => _isStreaming = false);
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2 || _isStreaming) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    _cameraController?.switchCamera(_cameras[_currentCameraIndex].name!);
  }

  void _startStatsTimer() {
    if (!Platform.isAndroid) return;
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || !_isStreaming) return;
      try {
        final s = await _cameraController!.getStreamStatistics();
        if (!mounted) return;
        setState(() {
          _statsLine = 'fps=${s.fps}  RTT=${s.rttMicros}µs  ${s.bytesSend}B';
        });
      } catch (_) {}
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _statsLine = '';
    // if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════
  //  观众端 — HLS 播放
  // ═══════════════════════════════════════════════════════════════

  void _initHlsPlayer(String rtmpKey) {
    _hlsUrl = '${BaseUrl.host()}/live/$rtmpKey.m3u8';
    debugPrint('[LivePage] HLS URL: $_hlsUrl');
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(_hlsUrl ?? ''))
            ..initialize()
                .then((_) {
                  if (mounted) setState(() {});
                  _videoController?.play();
                })
                .catchError((e) {
                  debugPrint('[LivePage] HLS 初始化失败: $e');
                });
    } catch (e) {
      debugPrint('[LivePage] 创建视频控制器失败: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  WS 连接
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _connectWs() async {
    if (!_liveWs.isConnected.value) {
      await _liveWs.connect();
      final authed = await _liveWs.waitForAuth();
      if (!authed) {
        debugPrint('[LivePage] WS 认证失败');
        return false;
      }
    }

    // 确认认证状态
    if (!_liveWs.isAuthenticated.value) {
      debugPrint('[LivePage] WS 未认证，尝试重连');
      _liveWs.disconnect();
      await _liveWs.connect();
      final authed = await _liveWs.waitForAuth();
      if (!authed) {
        debugPrint('[LivePage] WS 重连认证失败');
        return false;
      }
    }

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
      setState(() => _viewerCount = _liveWs.viewerCount.value);
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

    // 只有观众端才监听直播结束
    if (!_isAnchor) {
      _onLiveEndedSub = _liveWs.onLiveEnded.listen((_) {
        if (!mounted) return;
        Get.snackbar(
          '直播已结束',
          '主播已关闭直播',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      });
    }

    // 监听房间不可用（非 LIVE 状态拒绝）
    _onRoomUnavailableSub?.cancel();
    _onRoomUnavailableSub = _liveWs.onRoomUnavailable.listen((message) {
      if (!mounted) return;
      Get.snackbar('无法进入', message,
          backgroundColor: Colors.red, colorText: Colors.white);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    });

    _liveWs.joinRoom(_roomId!);
    return true;
  }

  // ═══════════════════════════════════════════════════════════════
  //  评论 + 弹幕
  // ═══════════════════════════════════════════════════════════════

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

  void _addFlyingDanmaku(String text, Color color) {
    final id = _danmakuIdCounter++;
    final now = DateTime.now();
    final endTime = now.add(const Duration(milliseconds: 4000));
    int trackIndex = _findFreeTrack(now);
    _danmakuTracks.add(
      DanmakuTrack(
        id: id,
        startTime: now,
        endTime: endTime,
        topPercent: _trackPercents[trackIndex],
      ),
    );

    setState(() {
      _flyingWidgets.add(
        FlyingDanmakuItem(
          key: ValueKey(id),
          text: text,
          color: color,
          topPercent: _trackPercents[trackIndex],
          onComplete: () {
            _danmakuTracks.removeWhere((t) => t.id == id);
            setState(
              () => _flyingWidgets.removeWhere(
                (w) => (w.key as ValueKey?)?.value == id,
              ),
            );
          },
        ),
      );
      if (_flyingWidgets.length > 8) {
        final oldest = _flyingWidgets.removeAt(0);
        final oldestId = (oldest.key as ValueKey?)?.value;
        if (oldestId != null) {
          _danmakuTracks.removeWhere((t) => t.id == oldestId);
        }
      }
    });
  }

  int _findFreeTrack(DateTime time) {
    for (int i = 0; i < _trackCount; i++) {
      final tp = _trackPercents[i];
      if (!_danmakuTracks.any(
        (t) =>
            (t.topPercent - tp).abs() < 0.01 &&
            time.isAfter(t.startTime) &&
            time.isBefore(t.endTime),
      )) {
        return i;
      }
    }
    return 0;
  }

  // ═══════════════════════════════════════════════════════════════
  //  公告编辑（主播端）
  // ═══════════════════════════════════════════════════════════════

  void _showEditAnnouncementDialog() {
    _announcementController.text = _announcement;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改公告'),
        content: TextField(
          controller: _announcementController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '输入新公告内容',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = _announcementController.text.trim();
              if (text.isNotEmpty && _roomId != null) {
                _announcement = text;
                _liveWs.updateAnnouncement(_roomId!, text);
                LiveRepository.updateRoom(_roomId!, announcement: text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  dispose
  // ═══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    if (_isAnchor && _isStreaming) {
      _stopPushStreaming();
    }

    if (_roomId != null && _liveWs.isConnected.value) {
      _liveWs.leaveRoom(_roomId!);
    }

    _onViewerListSub?.cancel();
    _onViewerJoinedSub?.cancel();
    _onViewerLeftSub?.cancel();
    _onNewCommentSub?.cancel();
    _onNewGiftSub?.cancel();
    _onAnnouncementSub?.cancel();
    _onLiveEndedSub?.cancel();
    _onRoomUnavailableSub?.cancel();

    _stopStatsTimer();
    _cameraController?.dispose();
    _videoController?.dispose();
    _chatController.dispose();
    _announcementController.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════

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
        // 视频区域（锚端=本地相机/观众端=远程HLS）
        if (_isAnchor) _buildAnchorVideo() else _buildViewerVideo(),
        // 主播端推流状态
        if (_isAnchor) _buildPushStatus(),
        // 公告条
        if (_announcement.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 12,
            right: 12,
            child: GestureDetector(
              onTap: _isAnchor ? _showEditAnnouncementDialog : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _isAnchor ? '📝 ' : '📢 ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Expanded(
                      child: Text(
                        _announcement,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isAnchor)
                      const Icon(Icons.edit, color: Colors.white54, size: 14),
                  ],
                ),
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
                    fansText: _anchorFansText,
                  ),
                ),
                const SizedBox(width: 20),
                ViewerInfoBar(
                  viewerCount: _viewerCount,
                  viewerAvatars: _viewerAvatars,
                  onClose: () {
                    // 主播端离开先停止推流
                    if (_isAnchor && _isStreaming) {
                      _stopPushStreaming();
                    }
                    Navigator.of(context).pop();
                  },
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

  Widget _buildAnchorVideo() {
    if (_permissionDenied) {
      return const Center(
        child: Text('请授予相机和麦克风权限', style: TextStyle(color: Colors.white54)),
      );
    }
    if (!_cameraReady || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white54),
            SizedBox(height: 8),
            Text('相机初始化中…', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    // 全屏竖屏相机预览
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.aspectRatio > 1
              ? _cameraController!.value.previewSize!.height
              : _cameraController!.value.previewSize!.width,
          height: _cameraController!.value.aspectRatio > 1
              ? _cameraController!.value.previewSize!.width
              : _cameraController!.value.previewSize!.height,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildViewerVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      // 全屏竖屏 HLS 播放
      return Positioned.fill(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPushStatus() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 推流状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isStreaming
                  ? Colors.red.withValues(alpha: 0.8)
                  : Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isStreaming ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isStreaming ? '直播中' : '等待中',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 切换相机按钮
          if (_cameras.length >= 2 && !_isStreaming)
            GestureDetector(
              onTap: _switchCamera,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          // 推流数据
          if (_isStreaming && _statsLine.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statsLine,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
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
      onEmojiTap: () {},
      onCartTap: () {},
      onGiftTap: _showGiftSheet,
      onShareTap: () {},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  交互
  // ═══════════════════════════════════════════════════════════════

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty || _roomId == null) return;
    // 只发 WS，由服务器广播回来触发 _addComment，避免重复
    if (_liveWs.isConnected.value) {
      _liveWs.sendComment(_roomId!, text);
    }
    _chatController.clear();
    setState(() => _showInput = false);
  }

  void _showGiftSheet() {
    if (_roomId == null) return;
    GiftBottomSheet.show(context, (gift) {
      if (_liveWs.isConnected.value) {
        _liveWs.sendGift(_roomId!, gift.name, gift.iconName, gift.lottiePath);
      }
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'video_feed_view.dart';
import 'nearby_view.dart';

// ═════════════════════════════════════════════════════════════════════════
// 主 Tab 入口 — 三个 Tab 水平滑动
// ═════════════════════════════════════════════════════════════════════════

class ShortVideoTab extends StatefulWidget {
  const ShortVideoTab({super.key});

  @override
  State<ShortVideoTab> createState() => _ShortVideoTabState();
}

class _ShortVideoTabState extends State<ShortVideoTab>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  int _topTabIndex = 1; // 默认「精选」
  late PageController _tabPageController;

  @override
  bool get wantKeepAlive => true;

  /// 「关注」和「精选」共用同一个视频 Feed
  /// 使用 GetX 全局控制器，确保 HomePage 和 ShortVideoTab 共享同一实例
  VideoFeedController get _feedCtrl => Get.find<VideoFeedController>();

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: 1);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用进入后台或切到其他大 Tab 时，暂停视频
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _feedCtrl.setFeedActive(false);
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，检查是否当前 tab
      // 这里不自动激活，由 HomePage 的 tab 切换逻辑控制
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _buildTopBar(),
        body: PageView(
          controller: _tabPageController,
          onPageChanged: (index) {
            setState(() => _topTabIndex = index);
            // 切换到同城 tab 时暂停视频
            if (index == 1) {
              _feedCtrl.setFeedActive(true);
            } else {
              _feedCtrl.setFeedActive(false);
            }
          },
          children: [
            // 关注 — 与精选共用视频流
            const Center(child: Text('关注')),
            // 精选 — 与关注共用视频流
            VideoFeedView(controller: _feedCtrl, tabIndex: _topTabIndex),
            // 同城 — 瀑布流布局（由 NearbyView 自行处理顶部偏移）
            NearbyView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    const titles = ['关注', '精选', '同城'];
    final isCityTab = _topTabIndex == 2;

    return AppBar(
      backgroundColor: isCityTab ? Colors.black : Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: titles.asMap().entries.map((e) {
          final active = e.key == _topTabIndex;
          return GestureDetector(
            onTap: () {
              _tabPageController.animateToPage(
                e.key,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: active ? 16 : 15,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 20,
                    height: 2,
                    color: active ? Colors.white : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:komodo/pages/ble_demo/ble_demo_controller.dart';
import 'package:komodo/pages/home/tabs/video_feed_view.dart';
import 'package:komodo/routes/app_routes.dart';
import 'tabs/music_tab.dart';
import 'tabs/short_video_tab.dart';
import 'tabs/message_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:get/get.dart';

/// 首页 Tab 懒加载控制器
/// 实现：点击 Tab 时加载内容，第二次点击不重复加载
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前激活的 navIndex（0=首页, 1=短视频, 2=+号, 3=消息, 4=我的）
  int _currentIndex = 0;

  /// 各 Tab 的加载状态：true = 已加载过（缓存），false = 未加载
  /// 懒加载策略：只有点击到该 Tab 时才标记为已加载
  final Map<int, bool> _tabLoaded = {0: true}; // 默认首页初始显示，直接加载

  /// 各 Tab 页面实例（懒创建，只创建一次）
  final Map<int, Widget> _tabPages = {};

  final ctrl = Get.put(BleDemoController());

  /// 视频 Feed 控制器（全局共享）
  final videoFeedCtrl = Get.put(VideoFeedController());

  /// navIndex → 页面索引（+号占位不对应页面，跳过）
  int _navIndexToPageIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex - 1;
  }

  /// 获取或创建 Tab 页面（懒加载）
  Widget _getOrCreateTabPage(int navIndex) {
    final pageIndex = _navIndexToPageIndex(navIndex);
    if (!_tabPages.containsKey(pageIndex)) {
      switch (pageIndex) {
        case 0:
          _tabPages[pageIndex] = const MusicTab();
          break;
        case 1:
          _tabPages[pageIndex] = const ShortVideoTab();
          break;
        case 2:
          _tabPages[pageIndex] = const MessageTab();
          break;
        case 3:
          _tabPages[pageIndex] = const ProfileTab();
          break;
      }
    }
    return _tabPages[pageIndex]!;
  }

  void _onTabTapped(int navIndex) {
    if (navIndex == 2) {
      _onPlusPressed();
      return;
    }

    // 懒加载：如果是第一次点击该 Tab，触发加载
    if (!_tabLoaded.containsKey(navIndex)) {
      _tabLoaded[navIndex] = true;
      debugPrint('Tab $navIndex 首次加载');
    }

    // 更新视频 Feed 活跃状态：只有短视频 tab 时才激活
    videoFeedCtrl.setFeedActive(navIndex == 1);

    setState(() {
      _currentIndex = navIndex;
    });
  }

  void _onPlusPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('点击了 + 按钮'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 所有 Tab 页面都放在 Stack 中，通过 Offstage 控制显示
          for (int i = 0; i < 5; i++)
            if (i != 2) // 跳过 + 号
              Offstage(
                offstage: _currentIndex != i,
                child: _getOrCreateTabPage(i),
              ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    // 短视频Tab选中时，底部导航栏使用深色背景
    final isVideoTab = _currentIndex == 1;
    final bgColor = isVideoTab
        ? Colors.black
        : Theme.of(context).bottomAppBarTheme.color;
    // final shadowColor = isVideoTab
    //     ? Colors.transparent
    //     : Colors.black.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -1),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '音乐',
                navIndex: 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_circle,
                label: '短视频',
                navIndex: 1,
              ),
              // 中间 + 号按钮
              _buildPlusItem(context),
              _buildNavItem(
                context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: '消息',
                navIndex: 3,
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                navIndex: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int navIndex,
  }) {
    final bool isActive = _currentIndex == navIndex;
    final isLoaded = _tabLoaded[navIndex] ?? false;
    // 短视频Tab选中时，使用浅色文字；其他Tab使用主题色
    final bool isDarkBg = _currentIndex == 1;
    final color = isDarkBg
        ? (isActive ? Colors.white : Colors.white70)
        : (isActive
              ? Theme.of(context).colorScheme.onSurface
              : Colors.grey[600]!);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(navIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isActive ? 17 : 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                // 小红点提示未读（可选）
                if (!isLoaded)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlusItem(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Get.toNamed(Routes.livePushDemo);
        },
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.surface,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

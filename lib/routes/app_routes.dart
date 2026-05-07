import 'package:get/get.dart';
import 'package:komodo/pages/live/live_push.dart';
import 'package:komodo/pages/live/push_demo.dart';
import 'package:komodo/pages/music/music_player_page.dart';
import 'package:komodo/pages/message/chat_page.dart';
import 'package:komodo/pages/message/image_viewer_page.dart';
import 'package:komodo/pages/design_system/design_system_page.dart';
import '../pages/home/home_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/lifecycle/lifecycle_detail_page.dart';
import '../pages/lifecycle/lifecycle_demo_page.dart';
import '../pages/live/live_page.dart';
import '../pages/ble_demo/ble_demo_page.dart';
import 'route_middleware.dart';

/// 路由名称常量
abstract class Routes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String designSystem = '/design-system';
  static const String lifecycleDetail = '/lifecycle-detail';
  static const String lifecycleDemo = '/lifecycle-demo';
  static const String live = '/live';
  static const String bleDemo = '/ble-demo';
  static const String livePushDemo = '/live-push-demo';
  static const String livePush = '/live-push';
  static const String musicPlayer = '/music-player';
  static const String chat = '/chat';
  static const String imageViewer = '/image-viewer';
}

/// 路由配置
class AppPages {
  static const String initial = Routes.home;

  static final List<GetPage> routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.designSystem,
      page: () => const DesignSystemPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.lifecycleDetail,
      page: () => const LifecycleDetailPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.lifecycleDemo,
      page: () => const LifecycleDemoPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.live,
      page: () => const LivePage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.bleDemo,
      page: () => const BleDemoPage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.livePushDemo,
      page: () => const CameraExampleHome(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.livePush,
      page: () => const LivePushPage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.musicPlayer,
      page: () => const MusicPlayerPage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Routes.chat,
      page: () => const ChatPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.imageViewer,
      page: () => const ImageViewerPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];
}

/// Home 页面绑定
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 这里可以注入 Home 页面需要的 Controller
    // Get.lazyPut<HomeController>(() => HomeController());
  }
}

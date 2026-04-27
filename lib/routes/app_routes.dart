import 'package:get/get.dart';
import 'package:komodo/pages/live/push_demo.dart';
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
  static const String lifecycleDetail = '/lifecycle-detail';
  static const String lifecycleDemo = '/lifecycle-demo';
  static const String live = '/live';
  static const String bleDemo = '/ble-demo';
  static const String livePushDemo = '/live-push-demo';
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

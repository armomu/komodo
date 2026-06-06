import 'package:get/get.dart';
import 'package:komodo/pages/live/live_push.dart';
import 'package:komodo/pages/live/push_demo.dart';
import 'package:komodo/pages/music/music_player_page.dart';
import 'package:komodo/pages/message/chat_page.dart';
import 'package:komodo/pages/message/image_viewer_page.dart';
import 'package:komodo/pages/database_demo/database_demo_page.dart';
import 'package:komodo/pages/cache_browser/cache_browser_page.dart';
import 'package:komodo/pages/login/login_page.dart';
import 'package:komodo/pages/login/register_page.dart';
import 'package:komodo/pages/login/profile_edit_page.dart';
import 'package:komodo/pages/message/video_call_page.dart';
import 'package:komodo/pages/home/home_page.dart';
import 'package:komodo/pages/settings/settings_page.dart';
import 'package:komodo/pages/live/live_page.dart';
import 'route_middleware.dart';

/// 路由名称常量
abstract class Routes {
  static const String login = '/login';
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
  static const String databaseDemo = '/database-demo';
  static const String cacheBrowser = '/cache-browser';
  static const String webrtcCall = '/webrtc-call';
  static const String chatVideoCall = '/chat-video-call';
  static const String register = '/register';
  static const String profileEdit = '/profile-edit';
  static const String reactiveDemo = '/reactive-demo';
  static const String customPaintDemo = '/custom-paint-demo';
}

/// 路由配置
class AppPages {
  static const String initial = Routes.home;

  static final List<GetPage> routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
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
      name: Routes.live,
      page: () => const LivePage(),
      middlewares: [AuthMiddleware()],
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
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
    GetPage(
      name: Routes.databaseDemo,
      page: () => const DatabaseDemoPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.cacheBrowser,
      page: () => const CacheBrowserPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.chatVideoCall,
      page: () => const VideoCallPage(),
      transition: Transition.upToDown,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.profileEdit,
      page: () => const ProfileEditPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}

/// Home 页面绑定
class HomeBinding extends Bindings {
  @override
  void dependencies() {}
}

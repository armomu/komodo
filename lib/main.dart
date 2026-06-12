import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/user_controller.dart';
import 'pages/music/music_player_controller.dart';
import 'pages/message/controllers/consumer_ws_client.dart';
import 'pages/message/controllers/consumer_list_controller.dart';
import 'pages/live/controllers/live_ws_client.dart';
import 'database/chat_database.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  // 保持启动页直到初始化完成
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── 系统栏样式（轻量、无 I/O） ──────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 初始化 GetStorage（用于本地存储）
  await GetStorage.init();

  // ── 注入全局控制器（仅轻量注入，不做耗时 I/O）──────────────────────────
  // 用户状态控制器
  Get.put(UserController());
  // 主题控制器
  Get.put(ThemeController());
  // 全局音乐播放器控制器（permanent = true，首帧前不加载播放列表）
  Get.put(MusicPlayerController(), permanent: true);
  // 聊天数据库（GetxService，全局单例 — 延迟初始化，首帧后再建表/种子数据）
  Get.put(ChatDatabase());
  // Consumer WebSocket 统一客户端（全局单例，登录后自动连接）
  Get.put(ConsumerWsClient());
  // 消费者列表控制器（全局单例，驱动消息 Tab 列表）
  Get.put(ConsumerListController());
  // Live WebSocket 客户端（全局单例，直播间实时通信）
  Get.put(LiveWsClient());

  // 初始化完成，移除启动页
  FlutterNativeSplash.remove();

  runApp(const MyApp());

  // ── 首帧渲染后执行非关键初始化 ────────────────────────────────────────
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDeferred();
  });
}

/// 首帧渲染后才执行的非关键初始化
void _initDeferred() async {
  // Android 13+ 通知权限 — 延迟请求，不阻塞首帧
  MusicPlayerController.requestNotificationPermission();

  // 聊天数据库初始化（建表 + 种子数据）
  Get.find<ChatDatabase>().ensureInitialized();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'KOMODO',
        debugShowCheckedModeBanner: true,

        // ==================== 主题配置 ====================
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,

        // ==================== 路由配置 ====================
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,

        // 默认过渡动画
        defaultTransition: Transition.native,

        // 路由中间件
        routingCallback: (routing) {
          // 可以在这里添加全局路由监听
          // debugPrint('📍 路由: ${routing?.current}');
        },

        // 国际化配置（可选）
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),

        // 导航观察者
        navigatorObservers: [
          GetObserver((routing) {
            // 路由变化监听
            if (routing?.current == '/settings') {
              debugPrint('🔧 进入设置页面');
            }
          }),
        ],
        // 未知路由
        unknownRoute: GetPage(
          name: '/not-found',
          page: () => const NotFoundPage(),
        ),
      ),
    );
  }
}

/// 404 页面
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text('页面不存在或已被移除', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(Routes.home),
              icon: const Icon(Icons.home),
              label: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

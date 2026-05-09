import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'controllers/user_controller.dart';
import 'pages/music/music_player_controller.dart';
import 'services/api_service.dart';
import 'database/chat_database.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  // 保持启动页直到初始化完成
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── Android 13+ 通知权限（POST_NOTIFICATIONS）────────────────────────────
  // 必须在 JustAudioBackground.init 之前请求，否则前台服务通知无法显示。
  // Android 12 及以下无此权限，permission_handler 会自动跳过。
  await Permission.notification.request();

  // ── 初始化 just_audio_background ──────────────────────────────────────────
  // 必须在 runApp 之前调用，负责注册系统媒体通知/锁屏/控制中心
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.komodo.music.channel.audio',
    androidNotificationChannelName: 'Komodo 音乐播放',
    androidNotificationOngoing: true, // 播放时通知不可手动清除
    androidStopForegroundOnPause: true, // 暂停时允许滑掉通知
  );
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.manual,
  //   overlays: [SystemUiOverlay.top], // 只显示顶部
  // );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 顶部透明
      systemNavigationBarColor: Colors.transparent, // 底部透明
      systemNavigationBarIconBrightness: Brightness.dark, // 图标颜色
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  // 初始化 GetStorage（用于本地存储）
  await GetStorage.init();

  // ── 注入全局控制器 ────────────────────────────────────────────────────────
  // API 服务（需在控制器之前注入）
  Get.put(ApiService());
  // 用户状态控制器
  Get.put(UserController());
  // 主题控制器
  Get.put(ThemeController());
  // 全局音乐播放器控制器（permanent = true 防止页面销毁时被自动 delete）
  Get.put(MusicPlayerController(), permanent: true);
  // 聊天数据库（GetxService，全局单例）
  await Get.putAsync<ChatDatabase>(() async {
    final db = ChatDatabase();
    await db.init();
    return db;
  });

  // 初始化完成，移除启动页
  FlutterNativeSplash.remove();

  runApp(const MyApp());
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

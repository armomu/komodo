import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'pages/music/music_player_controller.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 初始化 just_audio_background ──────────────────────────────────────────
  // 必须在 runApp 之前调用，负责注册系统媒体通知/锁屏/控制中心
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.komodo.music.channel.audio',
    androidNotificationChannelName: 'Komodo 音乐播放',
    androidNotificationOngoing: true,   // 播放时通知不可手动清除
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
    ),
  );
  // 初始化 GetStorage（用于本地存储）
  await GetStorage.init();

  // ── 注入全局控制器 ────────────────────────────────────────────────────────
  // 主题控制器
  Get.put(ThemeController());
  // 全局音乐播放器控制器（permanent = true 防止页面销毁时被自动 delete）
  Get.put(MusicPlayerController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          title: 'HybridArt - GetX 示例',
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
        ));
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
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
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
            const Text(
              '页面不存在或已被移除',
              style: TextStyle(color: Colors.grey),
            ),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/theme_controller.dart';
import '../../routes/app_routes.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        children: [
          // 主题设置
          _buildSectionHeader('外观设置'),
          Obx(
            () => Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.brightness_auto),
                      SizedBox(width: 12),
                      Text('跟随系统'),
                    ],
                  ),
                  value: AppThemeMode.system,
                  groupValue: themeController.appThemeMode,
                  onChanged: (_) => themeController.setSystemMode(),
                ),
                RadioListTile<AppThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.light_mode),
                      SizedBox(width: 12),
                      Text('浅色模式'),
                    ],
                  ),
                  value: AppThemeMode.light,
                  groupValue: themeController.appThemeMode,
                  onChanged: (_) => themeController.setLightMode(),
                ),
                RadioListTile<AppThemeMode>(
                  title: const Row(
                    children: [
                      Icon(Icons.dark_mode),
                      SizedBox(width: 12),
                      Text('深色模式'),
                    ],
                  ),
                  value: AppThemeMode.dark,
                  groupValue: themeController.appThemeMode,
                  onChanged: (_) => themeController.setDarkMode(),
                ),
              ],
            ),
          ),

          const Divider(),

          // 关于
          _buildSectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('应用信息'),
            subtitle: const Text('版本 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('关于'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flutter_dash, size: 64, color: Colors.blue),
                      SizedBox(height: 16),
                      Text('KOMODO APP'),
                      Text('使用 GetX 构建的 Flutter 应用'),
                      SizedBox(height: 8),
                      Text('版本 1.0.0+1', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),

          // 路由演示
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('路由演示'),
            subtitle: const Text('跳转到生命周期详情页'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(Routes.lifecycleDemo),
          ),

          // Snackbar 演示
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('蓝牙通信'),
            subtitle: const Text('跳转到蓝牙通信详情页'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(Routes.bleDemo),
          ),

          // Dialog 演示
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Dialog 演示'),
            subtitle: const Text('显示 GetX Dialog'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.defaultDialog(
                title: '确认操作',
                middleText: '你确定要执行此操作吗?',
                textConfirm: '确认',
                textCancel: '取消',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  Get.back();
                  Get.snackbar('成功', '操作已确认');
                },
              );
            },
          ),

          // BottomSheet 演示
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom),
            title: const Text('BottomSheet 演示'),
            subtitle: const Text('显示 GetX BottomSheet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.bottomSheet(
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '选择操作',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('分享'),
                        onTap: () => Get.back(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.copy),
                        title: const Text('复制链接'),
                        onTap: () => Get.back(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text(
                          '删除',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => Get.back(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}

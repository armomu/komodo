// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/theme/theme_controller.dart';
import 'package:komodo/routes/app_routes.dart';

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
          // 通知
          _buildSectionHeader('通知'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('通知'),
            subtitle: const Text('接收通知'),
            trailing: Switch(value: true, onChanged: (value) {}),
          ),

          // 主题设置
          _buildSectionHeader('外观设置'),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('主题'),
              subtitle: const Text('设置系统主题颜色'),
              trailing: DropdownButton<String>(
                value: themeController.curThemeMode,
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('跟随系统')),
                  DropdownMenuItem(value: 'light', child: Text('浅色模式')),
                  DropdownMenuItem(value: 'dark', child: Text('深色模式')),
                ],
                onChanged: (v) {
                  switch (v) {
                    case 'system':
                      themeController.setSystemMode();
                      break;
                    case 'light':
                      themeController.setLightMode();
                      break;
                    case 'dark':
                      themeController.setDarkMode();
                      break;
                  }
                },
              ),
            ),
          ),
          const Divider(),
          // 开发工具
          _buildSectionHeader('开发工具'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('本地数据库'),
            subtitle: const Text('浏览和操作 SQLite 聊天数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(Routes.databaseDemo),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('缓存管理'),
            subtitle: const Text('查看和清理聊天录音缓存文件'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(Routes.cacheBrowser),
          ),
          // 注销登录
          Obx(() {
            final userController = Get.find<UserController>();
            if (!userController.isLoggedIn) return const SizedBox.shrink();

            return Column(
              children: [
                const Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade400),
                  title: Text(
                    '注销登录',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.red.shade400,
                  ),
                  onTap: () => _showLogoutConfirm(context),
                ),
                const SizedBox(height: 32),
              ],
            );
          }),
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

  /// 显示注销登录确认对话框
  void _showLogoutConfirm(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认注销'),
        content: const Text('确定要注销登录吗？注销后需要重新登录。'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Get.back(); // 关闭对话框
              final userController = Get.find<UserController>();
              await userController.logout();
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
  }
}

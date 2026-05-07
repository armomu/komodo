import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/theme/theme_controller.dart';

class SwitchThemeWidget extends StatelessWidget {
  const SwitchThemeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return IconButton(
      icon: Obx(
        () => Icon(
          themeController.appThemeMode == AppThemeMode.light
              ? Icons.dark_mode
              : Icons.light_mode,
        ),
      ),
      onPressed: () {
        themeController.toggleTheme();
      },
      tooltip: '切换主题',
    );
  }
}

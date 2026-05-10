import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ble_demo_controller.dart';
import 'tabs/send_data_tab.dart';
import 'tabs/ota_upgrade_tab.dart';

/// 蓝牙示例控制台——连接后的功能面板
class BleDemoDashboardPage extends StatefulWidget {
  const BleDemoDashboardPage({super.key});

  @override
  State<BleDemoDashboardPage> createState() => _BleDemoDashboardPageState();
}

class _BleDemoDashboardPageState extends State<BleDemoDashboardPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _tabIndex = 0;

  static const _titles = ['发送数据', 'OTA 升级'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BleDemoController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: _titles.asMap().entries.map((e) {
            final active = e.key == _tabIndex;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  e.key,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value,
                      style: TextStyle(
                        color: active
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontSize: active ? 16 : 15,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 20 : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: active
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          Obx(
            () => ctrl.isConnected.value
                ? TextButton.icon(
                    onPressed: ctrl.disconnectDevice,
                    icon: Icon(
                      Icons.bluetooth_disabled,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      '断开',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _tabIndex = index);
        },
        children: const [SendDataTab(), OtaUpgradeTab()],
      ),
    );
  }
}

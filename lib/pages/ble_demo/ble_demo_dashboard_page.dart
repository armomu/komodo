import 'package:flutter/material.dart';
import 'tabs/send_data_tab.dart';
import 'tabs/ota_upgrade_tab.dart';

/// 蓝牙示例控制台——连接后的功能面板
class BleDemoDashboardPage extends StatelessWidget {
  const BleDemoDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const TabBar(
            dividerHeight: 0,
            tabs: [
              Tab(text: '发送数据'),
              Tab(text: 'OTA升级'),
            ],
          ),
        ),
        body: const TabBarView(children: [SendDataTab(), OtaUpgradeTab()]),
      ),
    );
  }
}

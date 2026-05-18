import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/components/switch_theme.dart';
import 'package:komodo/pages/ble_demo/ble_demo_page.dart';
import 'package:komodo/pages/lifecycle/lifecycle_demo_page.dart';
import 'package:komodo/pages/reactive_demo/reactive_demo_page.dart';
import 'package:komodo/pages/webrtc/pages/call_entry_page.dart';
import 'sections/colors_section.dart';
import 'sections/typography_section.dart';
import 'sections/spacing_radius_section.dart';
import 'sections/buttons_section.dart';
import 'sections/form_section.dart';
import 'sections/cards_section.dart';
import 'sections/lists_section.dart';
import 'sections/navigation_section.dart';
import 'sections/feedback_section.dart';
import 'sections/dialogs_section.dart';
import 'sections/bottom_sheets_section.dart';
import 'sections/other_section.dart';

/// ========================================
/// KOMODO 设计规范展示页面 - 导航入口
/// Material 3 组件完整展示
/// ========================================
class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设计规范'),
        actions: const [SwitchThemeWidget()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildDesignSystemSectionGrid(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

Widget buildDesignSystemSectionGrid(BuildContext context) {
  final sections = [
    _SectionItem(
      title: '颜色系统',
      subtitle: '基础色板、灰色阶梯、语义色、ColorScheme',
      icon: Icons.color_lens_outlined,
      color: const Color(0xFF6750A4),
      page: const ColorsSection(),
    ),
    _SectionItem(
      title: '字体规范',
      subtitle: 'Display、Headline、Title、Body、Label',
      icon: Icons.text_fields,
      color: const Color(0xFF625B71),
      page: const TypographySection(),
    ),
    _SectionItem(
      title: '间距与圆角',
      subtitle: '8px 基准间距、圆角阶梯',
      icon: Icons.straighten,
      color: const Color(0xFF7D5260),
      page: const SpacingRadiusSection(),
    ),
    _SectionItem(
      title: '按钮规范',
      subtitle: 'Elevated、Filled、Outlined、Text、FAB',
      icon: Icons.smart_button_outlined,
      color: const Color(0xFF006D3B),
      page: const ButtonsSection(),
    ),
    _SectionItem(
      title: '表单组件',
      subtitle: 'TextField、Switch、Checkbox、Slider、Chip',
      icon: Icons.edit_note,
      color: const Color(0xFF006493),
      page: const FormSection(),
    ),
    _SectionItem(
      title: '卡片组件',
      subtitle: '基础卡片、带图标、水平、卡片组',
      icon: Icons.dashboard_outlined,
      color: const Color(0xFF984061),
      page: const CardsSection(),
    ),
    _SectionItem(
      title: '列表组件',
      subtitle: 'ListTile、CheckboxListTile、SwitchListTile',
      icon: Icons.list_alt,
      color: const Color(0xFF7E5700),
      page: const ListsSection(),
    ),
    _SectionItem(
      title: '导航组件',
      subtitle: 'AppBar、TabBar、NavigationBar、Drawer',
      icon: Icons.navigation_outlined,
      color: const Color(0xFF4F5B62),
      page: const NavigationSection(),
    ),
    _SectionItem(
      title: '反馈组件',
      subtitle: 'SnackBar、Tooltip、Badge、ProgressIndicator',
      icon: Icons.notifications_outlined,
      color: const Color(0xFF8C4A64),
      page: const FeedbackSection(),
    ),
    _SectionItem(
      title: '对话框',
      subtitle: 'AlertDialog、SimpleDialog、DatePicker',
      icon: Icons.message_outlined,
      color: const Color(0xFF5E5CE5),
      page: const DialogsSection(),
    ),
    _SectionItem(
      title: '底部弹窗',
      subtitle: 'ModalBottomSheet、DraggableScrollableSheet',
      icon: Icons.vertical_align_bottom_outlined,
      color: const Color(0xFF006874),
      page: const BottomSheetsSection(),
    ),
    _SectionItem(
      title: '其他组件',
      subtitle: 'Avatar、AnimatedContainer、GridView',
      icon: Icons.widgets_outlined,
      color: const Color(0xFF785900),
      page: const OtherSection(),
    ),
  ];

  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...sections.map((section) => _SectionCard(item: section))],
    ),
  );
}

Widget buildDemoGrid(BuildContext context) {
  final sections = [
    _SectionItem(
      title: '路由演示',
      subtitle: '路由、生命周期演示',
      icon: Icons.route_rounded,
      color: const Color.fromARGB(79, 0, 174, 255),
      page: const LifecycleDemoPage(),
    ),
    _SectionItem(
      title: '蓝牙通信',
      subtitle: '蓝牙连接设备',
      icon: Icons.bluetooth_connected,
      color: const Color.fromARGB(216, 153, 212, 43),
      page: const BleDemoPage(),
    ),
    _SectionItem(
      title: '视频通话',
      subtitle: 'WebRTC  P2P 通信',
      icon: Icons.videocam_outlined,
      color: const Color.fromARGB(215, 103, 67, 221),
      page: const CallEntryPage(),
    ),
    _SectionItem(
      title: '响应式 DI',
      subtitle: '类 GetX 响应式依赖注入 Demo',
      icon: Icons.electric_bolt_outlined,
      color: const Color.fromARGB(220, 255, 152, 0),
      page: const ReactiveDemoPage(),
    ),
  ];

  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...sections.map((section) => _SectionCard(item: section))],
    ),
  );
}

class _SectionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  _SectionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class _SectionCard extends StatelessWidget {
  final _SectionItem item;

  const _SectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Get.to(() => item.page),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: item.color.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: item.color, size: 24),
      ),
      title: Text(item.title),
      subtitle: Container(
        padding: const EdgeInsets.only(top: 4),
        child: Text(item.subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
    // CircleAvatar(
    //     backgroundColor: item.color.withAlpha(30),
    //     child: Icon(item.icon, color: item.color),
    //   )
    // return GestureDetector(
    //   onTap: () => Get.to(() => item.page),
    //   child: Card(
    //     clipBehavior: Clip.antiAlias,
    //     child: Padding(
    //       padding: const EdgeInsets.all(16),
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Container(
    //             padding: const EdgeInsets.all(10),
    //             decoration: BoxDecoration(
    //               color: item.color.withAlpha(30),
    //               borderRadius: BorderRadius.circular(10),
    //             ),
    //             child: Icon(item.icon, color: item.color, size: 24),
    //           ),
    //           const SizedBox(height: 12),
    //           Text(
    //             item.title,
    //             style: Theme.of(
    //               context,
    //             ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    //             maxLines: 1,
    //             overflow: TextOverflow.ellipsis,
    //           ),
    //           const SizedBox(height: 4),
    //           Text(
    //             item.subtitle,
    //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
    //               color: Theme.of(context).colorScheme.onSurfaceVariant,
    //             ),
    //             maxLines: 2,
    //             overflow: TextOverflow.ellipsis,
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}

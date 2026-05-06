import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题切换演示')),
              );
            },
            tooltip: '切换主题',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSectionGrid(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KOMODO 设计规范',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Material 3 组件库完整展示',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildStatRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context, '13', '分类'),
        _buildStatItem(context, '40+', '组件'),
        _buildStatItem(context, '200+', '示例'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionGrid(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '组件分类',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _SectionCard(item: section);
          },
        ),
      ],
    );
  }
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Get.to(() => item.page, transition: Transition.cupertino);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

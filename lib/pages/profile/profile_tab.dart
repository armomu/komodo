import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/components/app_bottom_sheet.dart';
import 'package:komodo/components/switch_theme.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/pages/design_system/design_system_page.dart';
import 'package:komodo/routes/app_routes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['DEMO', 'M3-UI组件', '动画', '歌单'];

  // Mock data
  final int _followers = 13;
  final int _following = 7;
  final int _activities = 109;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final userController = Get.find<UserController>();
    final list = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(child: buildDemoGrid(context)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(child: buildDesignSystemSectionGrid(context)),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        actions: [
          const SwitchThemeWidget(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.toNamed(Routes.settings);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Avatar with user info — 根据登录态动态展示
          Obx(
            () => GestureDetector(
              onTap: () {
                if (userController.isLoggedIn) {
                  Get.toNamed(Routes.profileEdit);
                } else {
                  Get.toNamed(Routes.login);
                }
              },
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 头像
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 5,
                                offset: const Offset(0, 0),
                              ),
                            ],
                            color: userController.isLoggedIn
                                ? null
                                : colorScheme.surfaceContainerHighest,
                            image:
                                userController.isLoggedIn &&
                                    userController.avatar.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(userController.avatar),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: !userController.isLoggedIn
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : (userController.avatar.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: colorScheme.onSurfaceVariant,
                                      )
                                    : null),
                        ),
                        // Plus badge
                        Positioned(
                          bottom: 0,
                          right: -4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              userController.isLoggedIn
                                  ? Icons.edit
                                  : Icons.add,
                              size: 16,
                              color: colorScheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 用户名 / 登录提示
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 16),
                        child: Text(
                          userController.isLoggedIn
                              ? userController.nickname.isNotEmpty
                                    ? userController.nickname
                                    : '用户'
                              : '登录',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Container(
                        margin: const EdgeInsets.only(left: 16),
                        child: Text(
                          userController.isLoggedIn
                              ? 'ID：${userController.userId}'
                              : '~',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // User info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Tag $_following',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 1,
                  height: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                Text(
                  'Tag  $_followers',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 1,
                  height: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                Text(
                  'Tag $_following',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),

          // Stats cards row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    icon: Icons.change_history,
                    count: '$_activities',
                    title: 'Activities',
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatsCard(
                    icon: Icons.multitrack_audio,
                    count: '6,815',
                    title: 'Multitrack',
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab navigation
          _buildTabNavigation(context, isDark),

          const SizedBox(height: 12),
          if (_selectedTabIndex < list.length) list[_selectedTabIndex],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String count,
    required ColorScheme colorScheme,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: colorScheme.onSurface),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.onSurface;
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isSelected
                                ? primaryColor
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: isSelected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            onPressed: () => _showAllTabs(context),
          ),
        ],
      ),
    );
  }

  void _showAllTabs(BuildContext context) {
    AppBottomSheet.show(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._tabs.map(
            (tab) => ListTile(
              title: Text(tab),
              trailing: _tabs.indexOf(tab) == _selectedTabIndex
                  ? const Icon(Icons.check, color: Color(0xFF2D5016))
                  : null,
              onTap: () {
                setState(() => _selectedTabIndex = _tabs.indexOf(tab));
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
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
  }
}

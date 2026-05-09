import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 列表组件 - Material 3 Lists
/// ========================================
class ListsSection extends StatelessWidget {
  const ListsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('列表组件'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _ListTileDemo(),
            SizedBox(height: 24),
            _ListTileVariantsDemo(),
            SizedBox(height: 24),
            _CheckboxListTileDemo(),
            SizedBox(height: 24),
            _SwitchListTileDemo(),
            SizedBox(height: 24),
            _RadioListTileDemo(),
            SizedBox(height: 24),
            _DividerDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ListTile 基础
class _ListTileDemo extends StatelessWidget {
  const _ListTileDemo();

  @override
  Widget build(BuildContext context) {
    return _ListCategory(
      title: 'ListTile 基础',
      description: '基础的列表项组件',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('首页'),
              subtitle: const Text('返回主页面'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('搜索'),
              subtitle: const Text('搜索内容'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              subtitle: const Text('应用设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ListTile 变体
class _ListTileVariantsDemo extends StatelessWidget {
  const _ListTileVariantsDemo();

  @override
  Widget build(BuildContext context) {
    return _ListCategory(
      title: 'ListTile 变体',
      description: '不同形态的列表项',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Text('A')),
              title: Text('带头像'),
              subtitle: Text('带头像的列表项'),
            ),
            const Divider(height: 1, indent: 72),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.accent,
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: Text('带头像图标'),
              subtitle: Text('头像为彩色图标'),
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              title: const Text('仅标题'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            const Divider(height: 1, indent: 16),
            const ListTile(
              title: Text('三行文本'),
              subtitle: Text('这是第二行\n这是第三行'),
              leading: Icon(Icons.notes),
            ),
            const Divider(height: 1, indent: 56),
            const ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage('https://picsum.photos/100'),
              ),
              title: Text('带头像图片'),
              subtitle: Text('网络图片'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

// CheckboxListTile
class _CheckboxListTileDemo extends StatefulWidget {
  const _CheckboxListTileDemo();

  @override
  State<_CheckboxListTileDemo> createState() => _CheckboxListTileDemoState();
}

class _CheckboxListTileDemoState extends State<_CheckboxListTileDemo> {
  bool _notification = true;
  bool _darkMode = false;
  bool _autoSave = true;

  @override
  Widget build(BuildContext context) {
    return _ListCategory(
      title: 'CheckboxListTile',
      description: '带复选框的列表项',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            CheckboxListTile(
              value: _notification,
              onChanged: (v) => setState(() => _notification = v ?? false),
              title: const Text('接收通知'),
              subtitle: const Text('接收应用推送通知'),
              secondary: const Icon(Icons.notifications),
            ),
            const Divider(height: 1, indent: 56),
            CheckboxListTile(
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v ?? false),
              title: const Text('深色模式'),
              subtitle: const Text('使用深色主题'),
              secondary: const Icon(Icons.dark_mode),
            ),
            const Divider(height: 1, indent: 56),
            CheckboxListTile(
              value: _autoSave,
              onChanged: (v) => setState(() => _autoSave = v ?? false),
              title: const Text('自动保存'),
              subtitle: const Text('自动保存草稿'),
              secondary: const Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}

// SwitchListTile
class _SwitchListTileDemo extends StatefulWidget {
  const _SwitchListTileDemo();

  @override
  State<_SwitchListTileDemo> createState() => _SwitchListTileDemoState();
}

class _SwitchListTileDemoState extends State<_SwitchListTileDemo> {
  bool _wifi = true;
  bool _bluetooth = false;
  bool _airplane = false;

  @override
  Widget build(BuildContext context) {
    return _ListCategory(
      title: 'SwitchListTile',
      description: '带开关的列表项',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            SwitchListTile(
              value: _wifi,
              onChanged: (v) => setState(() => _wifi = v),
              title: const Text('Wi-Fi'),
              subtitle: const Text('已连接到网络'),
              secondary: const Icon(Icons.wifi),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              value: _bluetooth,
              onChanged: (v) => setState(() => _bluetooth = v),
              title: const Text('蓝牙'),
              subtitle: const Text('蓝牙已关闭'),
              secondary: const Icon(Icons.bluetooth),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              value: _airplane,
              onChanged: (v) => setState(() => _airplane = v),
              title: const Text('飞行模式'),
              subtitle: const Text('关闭所有无线连接'),
              secondary: const Icon(Icons.airplanemode_active),
            ),
          ],
        ),
      ),
    );
  }
}

// RadioListTile
class _RadioListTileDemo extends StatefulWidget {
  const _RadioListTileDemo();

  @override
  State<_RadioListTileDemo> createState() => _RadioListTileDemoState();
}

class _RadioListTileDemoState extends State<_RadioListTileDemo> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return _ListCategory(
      title: 'RadioListTile',
      description: '带单选框的列表项',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            RadioGroup<int>(
              groupValue: _selectedOption,
              onChanged: (int? v) => setState(() => _selectedOption = v),
              child: const Column(
                children: [
                  RadioListTile<int>(
                    value: 0,
                    title: Text('标准模式'),
                    subtitle: Text('默认显示设置'),
                    secondary: Icon(Icons.grid_view),
                  ),
                  RadioListTile<int>(
                    value: 1,
                    title: Text('紧凑模式'),
                    subtitle: Text('显示更多内容'),
                    secondary: Icon(Icons.view_list),
                  ),
                  RadioListTile<int>(
                    value: 2,
                    title: Text('列表模式'),
                    subtitle: Text('显示详细信息'),
                    secondary: Icon(Icons.view_agenda),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Divider
class _DividerDemo extends StatelessWidget {
  const _DividerDemo();

  @override
  Widget build(BuildContext context) {
    return const _ListCategory(
      title: 'Divider',
      description: '分割线组件',
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(title: Text('上面')),
            Divider(),
            ListTile(title: Text('默认分割线')),
            Divider(color: AppTheme.accent, thickness: 2),
            ListTile(title: Text('彩色分割线')),
            Divider(indent: 32, endIndent: 32),
            ListTile(title: Text('带缩进的分割线')),
            Divider(height: 2, thickness: 3),
            ListTile(title: Text('粗分割线')),
          ],
        ),
      ),
    );
  }
}

// 通用分类组件
class _ListCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ListCategory({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
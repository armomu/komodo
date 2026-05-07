import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';

/// ========================================
/// 按钮规范 - Material 3 Buttons
/// ========================================
class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('按钮规范'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _ElevatedButtonDemo(),
            SizedBox(height: 24),
            _FilledButtonDemo(),
            SizedBox(height: 24),
            _OutlinedButtonDemo(),
            SizedBox(height: 24),
            _TextButtonDemo(),
            SizedBox(height: 24),
            _FABDemo(),
            SizedBox(height: 24),
            _IconButtonDemo(),
            SizedBox(height: 24),
            _SegmentedButtonDemo(),
            SizedBox(height: 24),
            _ButtonSizesDemo(),
            SizedBox(height: 24),
            _ButtonStatesDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ElevatedButton
class _ElevatedButtonDemo extends StatelessWidget {
  const _ElevatedButtonDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'ElevatedButton',
      description: '具有阴影和背景色的按钮，适用于主要操作',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '主要按钮点击'),
            child: const Text('主要按钮'),
          ),
          ElevatedButton.icon(
            onPressed: () => _showSnackBar(context, '带图标'),
            icon: const Icon(Icons.add),
            label: const Text('图标按钮'),
          ),
          ElevatedButton(
            onPressed: () => _showSnackBar(context, '长按触发'),
            onLongPress: () => _showSnackBar(context, '长按了！'),
            child: const Text('长按按钮'),
          ),
          const ElevatedButton(onPressed: null, child: Text('禁用状态')),
        ],
      ),
    );
  }
}

// FilledButton
class _FilledButtonDemo extends StatelessWidget {
  const _FilledButtonDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'FilledButton',
      description: '填充色按钮，比 ElevatedButton 更突出',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: () => _showSnackBar(context, 'Filled 按钮'),
            child: const Text('Filled 按钮'),
          ),
          FilledButton.icon(
            onPressed: () => _showSnackBar(context, 'Filled 带图标'),
            icon: const Icon(Icons.check),
            label: const Text('确认'),
          ),
          FilledButton.tonal(
            onPressed: () => _showSnackBar(context, 'Tonal 按钮'),
            child: const Text('Tonal 按钮'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _showSnackBar(context, 'Tonal 带图标'),
            icon: const Icon(Icons.home),
            label: const Text('首页'),
          ),
          const FilledButton(onPressed: null, child: Text('禁用状态')),
        ],
      ),
    );
  }
}

// OutlinedButton
class _OutlinedButtonDemo extends StatelessWidget {
  const _OutlinedButtonDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'OutlinedButton',
      description: '带边框的按钮，适用于次要操作',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton(
            onPressed: () => _showSnackBar(context, '次要按钮'),
            child: const Text('次要按钮'),
          ),
          OutlinedButton.icon(
            onPressed: () => _showSnackBar(context, '分享'),
            icon: const Icon(Icons.share),
            label: const Text('分享'),
          ),
          const OutlinedButton(onPressed: null, child: Text('禁用状态')),
        ],
      ),
    );
  }
}

// TextButton
class _TextButtonDemo extends StatelessWidget {
  const _TextButtonDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'TextButton',
      description: '纯文本按钮，适用于辅助操作',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          TextButton(
            onPressed: () => _showSnackBar(context, '文字按钮'),
            child: const Text('文字按钮'),
          ),
          TextButton.icon(
            onPressed: () => _showSnackBar(context, '详情'),
            icon: const Icon(Icons.info_outline),
            label: const Text('详情'),
          ),
          const TextButton(onPressed: null, child: Text('禁用状态')),
        ],
      ),
    );
  }
}

// FAB
class _FABDemo extends StatelessWidget {
  const _FABDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'FloatingActionButton',
      description: '浮动操作按钮，适用于主要快捷操作',
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          FloatingActionButton.small(
            onPressed: () => _showSnackBar(context, 'Small FAB'),
            heroTag: 'fab1',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () => _showSnackBar(context, 'Regular FAB'),
            heroTag: 'fab2',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton.large(
            onPressed: () => _showSnackBar(context, 'Large FAB'),
            heroTag: 'fab3',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton.extended(
            onPressed: () => _showSnackBar(context, 'Extended FAB'),
            heroTag: 'fab4',
            icon: const Icon(Icons.add),
            label: const Text('新增'),
          ),
          FloatingActionButton.extended(
            onPressed: () => _showSnackBar(context, '扫描'),
            heroTag: 'fab5',
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('扫描'),
          ),
        ],
      ),
    );
  }
}

// IconButton
class _IconButtonDemo extends StatelessWidget {
  const _IconButtonDemo();

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'IconButton',
      description: '图标按钮，适用于工具栏和操作栏',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          IconButton(
            onPressed: () => _showSnackBar(context, '首页'),
            icon: const Icon(Icons.home),
            tooltip: '首页',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '搜索'),
            icon: const Icon(Icons.search),
            tooltip: '搜索',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '设置'),
            icon: const Icon(Icons.settings),
            tooltip: '设置',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '通知'),
            icon: const Icon(Icons.notifications),
            tooltip: '通知',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '消息'),
            icon: const Icon(Icons.message),
            tooltip: '消息',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '书签'),
            icon: const Icon(Icons.bookmark),
            tooltip: '书签',
          ),
          IconButton(
            onPressed: () => _showSnackBar(context, '分享'),
            icon: const Icon(Icons.share),
            tooltip: '分享',
          ),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.home),
            tooltip: '禁用',
          ),
        ],
      ),
    );
  }
}

// SegmentedButton
class _SegmentedButtonDemo extends StatelessWidget {
  const _SegmentedButtonDemo();

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: 'SegmentedButton',
      description: '分段按钮，用于在多个选项间切换',
      child: StatefulBuilder(
        builder: (context, setState) {
          int selected = 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('综合'),
                    icon: Icon(Icons.grid_view),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('最新'),
                    icon: Icon(Icons.schedule),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('最热'),
                    icon: Icon(Icons.local_fire_department),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => selected = newSelection.first);
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('日')),
                  ButtonSegment(value: 1, label: Text('周')),
                  ButtonSegment(value: 2, label: Text('月')),
                  ButtonSegment(value: 3, label: Text('年')),
                ],
                selected: {selected},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => selected = newSelection.first);
                },
                showSelectedIcon: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Button Sizes
class _ButtonSizesDemo extends StatelessWidget {
  const _ButtonSizesDemo();

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: '按钮尺寸',
      description: '通过 styleFrom 设置不同的 padding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('小按钮', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Small', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 12),
          const Text(
            '中按钮 (默认)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Medium', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          const Text('大按钮', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            ),
            child: const Text('Large', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// Button States
class _ButtonStatesDemo extends StatelessWidget {
  const _ButtonStatesDemo();

  @override
  Widget build(BuildContext context) {
    return _ButtonCategory(
      title: '按钮状态与样式',
      description: '不同状态和自定义样式示例',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '自定义颜色',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('红色'),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('绿色'),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('橙色'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '加载状态',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const ElevatedButton(
                onPressed: null,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                label: const Text('加载中...'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 通用分类组件
class _ButtonCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _ButtonCategory({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
        ),
      ),
    );
  }
}

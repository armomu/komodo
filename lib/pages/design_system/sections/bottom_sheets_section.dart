import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';

/// ========================================
/// 底部弹窗 - Material 3 Bottom Sheets
/// ========================================
class BottomSheetsSection extends StatelessWidget {
  const BottomSheetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('底部弹窗'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _ModalBottomSheetDemo(),
            SizedBox(height: 24),
            _ScrollableBottomSheetDemo(),
            SizedBox(height: 24),
            _ExpandableBottomSheetDemo(),
            SizedBox(height: 24),
            _PersistentBottomSheetDemo(),
            SizedBox(height: 24),
            _DraggableSheetDemo(),
            SizedBox(height: 24),
            _ThemedBottomSheetDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// Modal Bottom Sheet
class _ModalBottomSheetDemo extends StatelessWidget {
  const _ModalBottomSheetDemo();

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '底部弹窗标题',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('这是底部弹窗的内容区域。'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showModalBottomSheetWithActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('复制链接'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: 'showModalBottomSheet',
      description: '模态底部弹窗',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showModalBottomSheet(context),
            child: const Text('基础弹窗'),
          ),
          ElevatedButton(
            onPressed: () => _showModalBottomSheetWithActions(context),
            child: const Text('带操作列表'),
          ),
        ],
      ),
    );
  }
}

// Scrollable Bottom Sheet
class _ScrollableBottomSheetDemo extends StatelessWidget {
  const _ScrollableBottomSheetDemo();

  void _showScrollableBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: 30,
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('选项 ${index + 1}'),
            subtitle: Text('这是选项 ${index + 1} 的描述文字'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: '可滚动底部弹窗',
      description: '使用 DraggableScrollableSheet + ListView',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showScrollableBottomSheet(context),
            child: const Text('可滚动列表'),
          ),
        ],
      ),
    );
  }
}

// Expandable Bottom Sheet
class _ExpandableBottomSheetDemo extends StatelessWidget {
  const _ExpandableBottomSheetDemo();

  void _showExpandableBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '可展开底部弹窗',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text('向上拖动可以展开更多内容区域。'),
                const SizedBox(height: 16),
                ...List.generate(
                  15,
                  (index) => ListTile(title: Text('列表项 ${index + 1}')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: '可展开底部弹窗',
      description: 'isScrollControlled + DraggableScrollableSheet',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showExpandableBottomSheet(context),
            child: const Text('可展开弹窗'),
          ),
        ],
      ),
    );
  }
}

// Persistent Bottom Sheet
class _PersistentBottomSheetDemo extends StatelessWidget {
  const _PersistentBottomSheetDemo();

  void _showPersistentBottomSheet(BuildContext context) {
    Scaffold.of(context).showBottomSheet(
      (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '持久底部栏',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomSheetActionButton(
                  icon: Icons.home,
                  label: '首页',
                  onTap: () {},
                ),
                _BottomSheetActionButton(
                  icon: Icons.search,
                  label: '搜索',
                  onTap: () {},
                ),
                _BottomSheetActionButton(
                  icon: Icons.person,
                  label: '我的',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: 'Persistent Bottom Sheet',
      description: '持久底部栏（非模态）',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showPersistentBottomSheet(context),
            child: const Text('显示持久底部栏'),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomSheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Draggable Sheet
class _DraggableSheetDemo extends StatelessWidget {
  const _DraggableSheetDemo();

  void _showDraggableSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 50,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('DraggableScrollableSheet Item ${index + 1}'),
                      subtitle: Text('内容描述 ${index + 1}'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: 'DraggableScrollableSheet',
      description: '可拖动滚动面板',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showDraggableSheet(context),
            child: const Text('可拖动滚动面板'),
          ),
        ],
      ),
    );
  }
}

// Themed Bottom Sheet
class _ThemedBottomSheetDemo extends StatelessWidget {
  const _ThemedBottomSheetDemo();

  void _showThemedBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.palette,
              size: 48,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              '自定义主题底部弹窗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '使用 primaryContainer 背景色',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetCategory(
      title: '自定义主题底部弹窗',
      description: '使用透明背景 + 自定义颜色',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElevatedButton(
            onPressed: () => _showThemedBottomSheet(context),
            child: const Text('自定义主题'),
          ),
        ],
      ),
    );
  }
}

// 通用分类组件
class _BottomSheetCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _BottomSheetCategory({
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

import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 其他组件 - Material 3 Other Components
/// ========================================
class OtherSection extends StatelessWidget {
  const OtherSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('其他组件'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _AvatarDemo(),
            SizedBox(height: 24),
            _AnimatedContainerDemo(),
            SizedBox(height: 24),
            _ExpansionTileDemo(),
            SizedBox(height: 24),
            _WrapDemo(),
            SizedBox(height: 24),
            _AnimatedCrossFadeDemo(),
            SizedBox(height: 24),
            _GridViewDemo(),
            SizedBox(height: 24),
            _AspectRatioFittedBoxDemo(),
            SizedBox(height: 24),
            _GestureDetectorDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// Avatar
class _AvatarDemo extends StatelessWidget {
  const _AvatarDemo();

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'Avatar',
      description: '头像组件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基础 Avatar',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const CircleAvatar(child: Text('A')),
              const CircleAvatar(child: Icon(Icons.person)),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const CircleAvatar(
                backgroundImage: NetworkImage('https://picsum.photos/100'),
                radius: 28,
              ),
              const CircleAvatar(
                backgroundColor: AppTheme.accent,
                child: Text(
                  '99+',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '不同尺寸',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text('S', style: TextStyle(fontSize: 12)),
              ),
              SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                child: Text('M', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(width: 12),
              CircleAvatar(
                radius: 32,
                child: Text('L', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(width: 12),
              CircleAvatar(
                radius: 40,
                child: Text('XL', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('带边框', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage('https://picsum.photos/100'),
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/2/100',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// AnimatedContainer
class _AnimatedContainerDemo extends StatefulWidget {
  const _AnimatedContainerDemo();

  @override
  State<_AnimatedContainerDemo> createState() => _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<_AnimatedContainerDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'AnimatedContainer',
      description: '动画容器，属性变化时有平滑过渡',
      child: Column(
        children: [
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _expanded ? 200 : 100,
              height: _expanded ? 200 : 100,
              decoration: BoxDecoration(
                color: _expanded
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(_expanded ? 24 : 8),
              ),
              child: Center(
                child: Text(
                  _expanded ? '展开' : '收起',
                  style: TextStyle(
                    color: _expanded
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? '收起' : '展开'),
          ),
        ],
      ),
    );
  }
}

// ExpansionTile
class _ExpansionTileDemo extends StatelessWidget {
  const _ExpansionTileDemo();

  @override
  Widget build(BuildContext context) {
    return const _OtherCategory(
      title: 'ExpansionTile',
      description: '可展开的列表项',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ExpansionTile(
              leading: Icon(Icons.folder),
              title: Text('文件夹'),
              subtitle: Text('点击展开'),
              children: [
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('文件 1.txt'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text('文件 2.txt'),
                  dense: true,
                ),
              ],
            ),
            Divider(height: 1),
            ExpansionTile(
              leading: Icon(Icons.image),
              title: Text('图片'),
              subtitle: Text('3 个项目'),
              children: [
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('photo1.jpg'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('photo2.jpg'),
                  dense: true,
                ),
              ],
            ),
            Divider(height: 1),
            ExpansionTile(
              leading: Icon(Icons.settings),
              title: Text('设置'),
              subtitle: Text('展开查看更多'),
              initiallyExpanded: true,
              children: [
                ListTile(title: Text('子设置 1'), dense: true),
                ListTile(title: Text('子设置 2'), dense: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Wrap
class _WrapDemo extends StatelessWidget {
  const _WrapDemo();

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'Wrap',
      description: '自动换行的布局组件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wrap 布局',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              15,
              (index) => Chip(
                label: Text('标签 ${index + 1}'),
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// AnimatedCrossFade
class _AnimatedCrossFadeDemo extends StatefulWidget {
  const _AnimatedCrossFadeDemo();

  @override
  State<_AnimatedCrossFadeDemo> createState() => _AnimatedCrossFadeDemoState();
}

class _AnimatedCrossFadeDemoState extends State<_AnimatedCrossFadeDemo> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'AnimatedCrossFade',
      description: '两个子组件之间的交叉淡入淡出动画',
      child: Column(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '喜欢',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            secondChild: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '收藏',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _showFirst
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _showFirst = !_showFirst),
            child: Text(_showFirst ? '切换到收藏' : '切换到喜欢'),
          ),
        ],
      ),
    );
  }
}

// GridView
class _GridViewDemo extends StatelessWidget {
  const _GridViewDemo();

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'GridView',
      description: '网格视图',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GridView.count',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(
                8,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      [
                        Icons.home,
                        Icons.search,
                        Icons.settings,
                        Icons.person,
                        Icons.star,
                        Icons.favorite,
                        Icons.notifications,
                        Icons.email,
                      ][index],
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// AspectRatio & FittedBox
class _AspectRatioFittedBoxDemo extends StatelessWidget {
  const _AspectRatioFittedBoxDemo();

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'AspectRatio & FittedBox',
      description: '调整组件比例和缩放',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '16:9',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '16:9',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '4:3',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '4:3',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1:1',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '1:1',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// GestureDetector
class _GestureDetectorDemo extends StatefulWidget {
  const _GestureDetectorDemo();

  @override
  State<_GestureDetectorDemo> createState() => _GestureDetectorDemoState();
}

class _GestureDetectorDemoState extends State<_GestureDetectorDemo> {
  String _lastGesture = '无';

  @override
  Widget build(BuildContext context) {
    return _OtherCategory(
      title: 'GestureDetector',
      description: '手势检测',
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _lastGesture = '点击'),
            onDoubleTap: () => setState(() => _lastGesture = '双击'),
            onLongPress: () => setState(() => _lastGesture = '长按'),
            onHorizontalDragEnd: (_) => setState(() => _lastGesture = '水平滑动'),
            onVerticalDragEnd: (_) => setState(() => _lastGesture = '垂直滑动'),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '尝试各种手势',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gesture),
                const SizedBox(width: 8),
                Text(
                  '最后手势: $_lastGesture',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 通用分类组件
class _OtherCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _OtherCategory({
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

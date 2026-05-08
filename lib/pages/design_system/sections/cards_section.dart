import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';

/// ========================================
/// 卡片组件 - Material 3 Cards
/// ========================================
class CardsSection extends StatelessWidget {
  const CardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片组件'),
        actions: const [SwitchThemeWidget()],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _BasicCardDemo(),
            SizedBox(height: 24),
            _IconCardDemo(),
            SizedBox(height: 24),
            _ClickableCardDemo(),
            SizedBox(height: 24),
            _HorizontalCardDemo(),
            SizedBox(height: 24),
            _CardGroupDemo(),
            SizedBox(height: 24),
            _OutlinedCardDemo(),
            SizedBox(height: 24),
            _FilledCardDemo(),
            SizedBox(height: 24),
            _ElevatedCardDemo(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// 基础卡片
class _BasicCardDemo extends StatelessWidget {
  const _BasicCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: '基础卡片 Card',
      description: '最基础的卡片组件',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '卡片标题',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '卡片内容描述文字，显示卡片内部的具体信息。',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 带图标的卡片
class _IconCardDemo extends StatelessWidget {
  const _IconCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: '带图标的卡片',
      description: 'ListTile 形式的图标卡片',
      child: Card(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: const Text('通知中心'),
          subtitle: const Text('您有 3 条新消息'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ),
    );
  }
}

// 可点击的卡片
class _ClickableCardDemo extends StatelessWidget {
  const _ClickableCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: '可点击的卡片',
      description: '使用 InkWell 实现点击波纹效果',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('点击卡片'))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '图片卡片',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击可触发 InkWell 波纹效果',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 水平卡片
class _HorizontalCardDemo extends StatelessWidget {
  const _HorizontalCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: '水平卡片',
      description: '水平布局的卡片',
      child: Card(
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.music_note,
                size: 40,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '音乐标题',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '艺术家名称',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_filled, size: 40),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// 卡片组
class _CardGroupDemo extends StatelessWidget {
  const _CardGroupDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: '卡片组 Card Group',
      description: '包含多个 ListTile 的卡片',
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('个人资料'),
              subtitle: const Text('查看和编辑您的信息'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('隐私设置'),
              subtitle: const Text('管理您的隐私选项'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('通知设置'),
              subtitle: const Text('配置通知偏好'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// OutlinedCard
class _OutlinedCardDemo extends StatelessWidget {
  const _OutlinedCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: 'OutlinedCard (带边框)',
      description: '使用 elevation: 0 + 边框替代阴影',
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OutlinedCard 示例',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '使用带边框的卡片组件',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            child: ListTile(
              leading: Icon(
                Icons.tips_and_updates,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('提示信息'),
              subtitle: const Text('点击查看更多'),
            ),
          ),
        ],
      ),
    );
  }
}

// FilledCard
class _FilledCardDemo extends StatelessWidget {
  const _FilledCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: 'FilledCard (填充色)',
      description: '使用填充色替代阴影',
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FilledCard 示例',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '使用填充色的卡片组件',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              title: Text(
                '创意提示',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              subtitle: Text(
                '尝试新功能',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer.withAlpha(180),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ElevatedCard
class _ElevatedCardDemo extends StatelessWidget {
  const _ElevatedCardDemo();

  @override
  Widget build(BuildContext context) {
    return _CardCategory(
      title: 'ElevatedCard (带阴影)',
      description: '使用阴影提升视觉层次',
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.architecture,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('建筑设计'),
              subtitle: const Text('查看建筑作品集'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            child: ListTile(
              leading: Icon(
                Icons.landscape,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: const Text('景观设计'),
              subtitle: const Text('探索自然之美'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 8,
            child: ListTile(
              leading: Icon(
                Icons.chair,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('室内设计'),
              subtitle: const Text('打造温馨家居'),
            ),
          ),
        ],
      ),
    );
  }
}

// 通用分类组件
class _CardCategory extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _CardCategory({
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

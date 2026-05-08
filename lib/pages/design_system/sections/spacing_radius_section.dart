import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';

/// ========================================
/// 间距与圆角规范 - Material 3 Spacing & Radius
/// ========================================
class SpacingRadiusSection extends StatelessWidget {
  const SpacingRadiusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('间距与圆角'),
        actions: const [SwitchThemeWidget()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSpacingSection(context),
          const SizedBox(height: 24),
          _buildBorderRadiusSection(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSpacingSection(BuildContext context) {
    final spacingValues = [
      (2, '0.5x'),
      (4, 'xs'),
      (8, 'sm'),
      (12, 'md'),
      (16, 'base'),
      (20, 'lg'),
      (24, 'xl'),
      (32, '2xl'),
      (40, '3xl'),
      (48, '4xl'),
      (64, '5xl'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.straighten,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '间距规范',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '基于 8px 基准网格系统，确保元素间距一致',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        ...spacingValues.map((item) => _SpacingPreview(item.$1, item.$2)),
        const SizedBox(height: 16),
        _SpacingCode(),
      ],
    );
  }

  Widget _buildBorderRadiusSection(BuildContext context) {
    final radiusValues = [
      (0, 'none', '用于特殊分割'),
      (4, 'xs', '紧凑元素'),
      (8, 'sm', '小按钮、标签'),
      (12, 'md', '中卡片'),
      (16, 'lg', '大卡片'),
      (20, 'xl', '模态框'),
      (24, '2xl', '底部弹窗'),
      (28, '3xl', '特殊卡片'),
      (32, 'full', '圆形元素'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.rounded_corner,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '圆角规范',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '圆角大小根据元素类型和使用场景选择',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 20,
          children: radiusValues
              .map((item) => _RadiusPreview(item.$1, item.$2, item.$3))
              .toList(),
        ),
        const SizedBox(height: 16),
        _RadiusCode(),
      ],
    );
  }
}

class _SpacingPreview extends StatelessWidget {
  final int size;
  final String label;

  const _SpacingPreview(this.size, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '${size}px',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 24,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: Container(
                width: size.toDouble(),
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SpacingCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          children: [
            const TextSpan(text: '// 使用 EdgeInsets\n'),
            TextSpan(
              text: 'EdgeInsets.all(16)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 全边 16px\n'),
            TextSpan(
              text: 'EdgeInsets.symmetric(horizontal: 16, vertical: 8)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 对称\n'),
            TextSpan(
              text: 'EdgeInsets.only(left: 16)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 单边'),
          ],
        ),
      ),
    );
  }
}

class _RadiusPreview extends StatelessWidget {
  final int radius;
  final String label;
  final String description;

  const _RadiusPreview(this.radius, this.label, this.description);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(radius.toDouble()),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${radius}px',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadiusCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          children: [
            const TextSpan(text: '// 使用 BorderRadius\n'),
            TextSpan(
              text: 'BorderRadius.circular(12)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 统一圆角\n'),
            TextSpan(
              text: 'BorderRadius.only(topLeft: Radius.circular(16))',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 单角\n'),
            TextSpan(
              text: 'BorderRadius.vertical(topRadius: Radius.circular(24))',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: ' // 顶部圆角'),
          ],
        ),
      ),
    );
  }
}

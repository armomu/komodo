import 'package:flutter/material.dart';
import 'package:komodo/components/switch_theme.dart';

/// ========================================
/// 字体规范 - Material 3 Typography
/// ========================================
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('字体规范'),
        actions: const [SwitchThemeWidget()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(context),
          const SizedBox(height: 24),
          _buildDisplaySection(context),
          const SizedBox(height: 24),
          _buildHeadlineSection(context),
          const SizedBox(height: 24),
          _buildTitleSection(context),
          const SizedBox(height: 24),
          _buildBodySection(context),
          const SizedBox(height: 24),
          _buildLabelSection(context),
          const SizedBox(height: 24),
          _buildCodeStyle(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '字体系统',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Material 3 使用系统字体，通过 TextTheme 定义不同的文本样式层次。字体规范确保应用内的文本具有一致的视觉层次和可读性。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(BuildContext context) {
    return _TypographyCategory(
      title: 'Display',
      description: '用于超大尺寸的显示文字，如欢迎页面或空状态',
      styles: [
        ('Display Large', Theme.of(context).textTheme.displayLarge!),
        ('Display Medium', Theme.of(context).textTheme.displayMedium!),
        ('Display Small', Theme.of(context).textTheme.displaySmall!),
      ],
    );
  }

  Widget _buildHeadlineSection(BuildContext context) {
    return _TypographyCategory(
      title: 'Headline',
      description: '用于分隔内容的标题文字',
      styles: [
        ('Headline Large', Theme.of(context).textTheme.headlineLarge!),
        ('Headline Medium', Theme.of(context).textTheme.headlineMedium!),
        ('Headline Small', Theme.of(context).textTheme.headlineSmall!),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return _TypographyCategory(
      title: 'Title',
      description: '用于卡片标题、对话框标题等',
      styles: [
        ('Title Large', Theme.of(context).textTheme.titleLarge!),
        ('Title Medium', Theme.of(context).textTheme.titleMedium!),
        ('Title Small', Theme.of(context).textTheme.titleSmall!),
      ],
    );
  }

  Widget _buildBodySection(BuildContext context) {
    return _TypographyCategory(
      title: 'Body',
      description: '用于主要内容文字',
      styles: [
        ('Body Large', Theme.of(context).textTheme.bodyLarge!),
        ('Body Medium', Theme.of(context).textTheme.bodyMedium!),
        ('Body Small', Theme.of(context).textTheme.bodySmall!),
      ],
    );
  }

  Widget _buildLabelSection(BuildContext context) {
    return _TypographyCategory(
      title: 'Label',
      description: '用于按钮文字、标签等小尺寸文字',
      styles: [
        ('Label Large', Theme.of(context).textTheme.labelLarge!),
        ('Label Medium', Theme.of(context).textTheme.labelMedium!),
        ('Label Small', Theme.of(context).textTheme.labelSmall!),
      ],
    );
  }

  Widget _buildCodeStyle(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '代码样式',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'Text(\n  \'Hello World\',\n  style: Theme.of(context).textTheme.bodyLarge,\n)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypographyCategory extends StatelessWidget {
  final String title;
  final String description;
  final List<(String, TextStyle)> styles;

  const _TypographyCategory({
    required this.title,
    required this.description,
    required this.styles,
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
            const Divider(),
            const SizedBox(height: 8),
            ...styles.map(
              (style) => _TextPreview(name: style.$1, style: style.$2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  final String name;
  final TextStyle style;

  const _TextPreview({required this.name, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${style.fontSize?.toInt() ?? 0}px / ${style.fontWeight?.toString().replaceAll('FontWeight.w', '') ?? 'normal'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('文字示例 Text Sample', style: style),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';

/// 设计规范展示页面
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('颜色系统'),
          _ColorSection(),
          SizedBox(height: 24),

          _SectionTitle('字体规范'),
          _TypographySection(),
          SizedBox(height: 24),

          _SectionTitle('间距规范'),
          _SpacingSection(),
          SizedBox(height: 24),

          _SectionTitle('圆角规范'),
          _BorderRadiusSection(),
          SizedBox(height: 24),

          _SectionTitle('按钮规范'),
          _ButtonSection(),
          SizedBox(height: 24),

          _SectionTitle('组件规范'),
          _ComponentSection(),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ==================== 颜色规范 ====================
class _ColorSection extends StatelessWidget {
  const _ColorSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubTitle('基础色板'),
        const SizedBox(height: 12),
        _ColorGrid(
          colors: [
            _ColorItem('Black', AppTheme.black, isDark: isDark),
            _ColorItem('White', AppTheme.white, isDark: isDark, isWhite: true),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('灰色阶梯'),
        const SizedBox(height: 12),
        _ColorGrid(
          colors: [
            _ColorItem('50', AppTheme.gray50, isDark: isDark),
            _ColorItem('100', AppTheme.gray100, isDark: isDark),
            _ColorItem('200', AppTheme.gray200, isDark: isDark),
            _ColorItem('300', AppTheme.gray300, isDark: isDark),
            _ColorItem('400', AppTheme.gray400, isDark: isDark),
            _ColorItem('500', AppTheme.gray500, isDark: isDark),
            _ColorItem('600', AppTheme.gray600, isDark: isDark),
            _ColorItem('700', AppTheme.gray700, isDark: isDark),
            _ColorItem('800', AppTheme.gray800, isDark: isDark),
            _ColorItem('900', AppTheme.gray900, isDark: isDark),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('语义色'),
        const SizedBox(height: 12),
        _ColorGrid(
          colors: [
            _ColorItem('Primary', AppTheme.primary, isDark: isDark),
            _ColorItem('Accent', AppTheme.accent, isDark: isDark),
            _ColorItem('Success', AppTheme.success, isDark: isDark),
            _ColorItem('Warning', AppTheme.warning, isDark: isDark),
            _ColorItem('Error', AppTheme.error, isDark: isDark),
            _ColorItem('Info', AppTheme.info, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String title;

  const _SubTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final List<_ColorItem> colors;

  const _ColorGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((item) => _ColorCard(item: item)).toList(),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;
  final bool isDark;
  final bool isWhite;

  _ColorItem(
    this.name,
    this.color, {
    this.isDark = false,
    this.isWhite = false,
  });

  String get hexCode {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color get textColor {
    if (isWhite) return AppTheme.gray800;
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppTheme.gray800 : AppTheme.white;
  }
}

class _ColorCard extends StatelessWidget {
  final _ColorItem item;

  const _ColorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
            border: item.isWhite
                ? Border.all(color: AppTheme.gray200, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: item.color.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          item.hexCode,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ==================== 字体规范 ====================
class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubTitle('Display (大标题)'),
        SizedBox(height: 8),
        _TextStylePreview(
          'Display Large',
          TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
          ),
        ),
        _TextStylePreview(
          'Display Medium',
          TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        ),
        _TextStylePreview(
          'Display Small',
          TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        ),

        SizedBox(height: 20),
        _SubTitle('Headline (标题)'),
        SizedBox(height: 8),
        _TextStylePreview(
          'Headline Large',
          TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
        ),
        _TextStylePreview(
          'Headline Medium',
          TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        _TextStylePreview(
          'Headline Small',
          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),

        SizedBox(height: 20),
        _SubTitle('Title (副标题)'),
        SizedBox(height: 8),
        _TextStylePreview(
          'Title Large',
          TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        _TextStylePreview(
          'Title Medium',
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        _TextStylePreview(
          'Title Small',
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),

        SizedBox(height: 20),
        _SubTitle('Body (正文)'),
        SizedBox(height: 8),
        _TextStylePreview(
          'Body Large',
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        _TextStylePreview(
          'Body Medium',
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
          ),
        ),
        _TextStylePreview(
          'Body Small',
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
        ),

        SizedBox(height: 20),
        _SubTitle('Label (标签)'),
        SizedBox(height: 8),
        _TextStylePreview(
          'Label Large',
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        _TextStylePreview(
          'Label Medium',
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        _TextStylePreview(
          'Label Small',
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TextStylePreview extends StatelessWidget {
  final String name;
  final TextStyle style;

  const _TextStylePreview(this.name, this.style);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '文字示例 Text',
              style: style.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 间距规范 ====================
class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    final spacingValues = [
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
        const _SubTitle('间距阶梯 (8px 基准)'),
        const SizedBox(height: 12),
        ...spacingValues.map((item) => _SpacingPreview(item.$1, item.$2)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
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
            color: Theme.of(context).colorScheme.primary.withAlpha(30),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 圆角规范 ====================
class _BorderRadiusSection extends StatelessWidget {
  const _BorderRadiusSection();

  @override
  Widget build(BuildContext context) {
    final radiusValues = [
      (0, 'none'),
      (4, 'xs'),
      (8, 'sm'),
      (12, 'md'),
      (16, 'lg'),
      (20, 'xl'),
      (24, '2xl'),
      (28, '3xl'),
      (32, 'full'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubTitle('圆角阶梯'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: radiusValues
              .map((item) => _RadiusPreview(item.$1, item.$2))
              .toList(),
        ),
      ],
    );
  }
}

class _RadiusPreview extends StatelessWidget {
  final int radius;
  final String label;

  const _RadiusPreview(this.radius, this.label);

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
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ==================== 按钮规范 ====================
class _ButtonSection extends StatelessWidget {
  const _ButtonSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubTitle('主要按钮 (Elevated)'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('主要按钮')),
            const ElevatedButton(onPressed: null, child: Text('禁用状态')),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('次要按钮 (Outlined)'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(onPressed: () {}, child: const Text('次要按钮')),
            const OutlinedButton(onPressed: null, child: Text('禁用状态')),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('文字按钮 (Text)'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton(onPressed: () {}, child: const Text('文字按钮')),
            const TextButton(onPressed: null, child: Text('禁用状态')),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('按钮尺寸'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Small', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              child: const Text('Medium', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
              ),
              child: const Text('Large', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('图标按钮'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.home),
              tooltip: '首页',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
              tooltip: '搜索',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              tooltip: '设置',
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.home),
              tooltip: '禁用',
            ),
          ],
        ),
      ],
    );
  }
}

// ==================== 组件规范 ====================
class _ComponentSection extends StatelessWidget {
  const _ComponentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubTitle('输入框'),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            hintText: '请输入文字',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(hintText: '带标签的输入框', labelText: '用户名'),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(hintText: '错误状态', errorText: '输入格式不正确'),
        ),

        const SizedBox(height: 20),
        const _SubTitle('卡片'),
        const SizedBox(height: 12),
        Card(
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
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const _SubTitle('Chip 标签'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Chip(label: Text('标签 1')),
            const Chip(label: Text('标签 2')),
            const Chip(
              label: Text('标签 3'),
              avatar: Icon(Icons.music_note, size: 18),
            ),
            Chip(
              label: const Text('可删除'),
              onDeleted: () {},
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('开关'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: true, onChanged: (_) {}),
                const Text('开'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: false, onChanged: (_) {}),
                const Text('关'),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Switch(value: false, onChanged: null), Text('禁用')],
            ),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('复选框'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const Text('选中'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: false, onChanged: (_) {}),
                const Text('未选中'),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Checkbox(value: false, onChanged: null), Text('禁用')],
            ),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('单选框'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio(value: 1, groupValue: 1, onChanged: (_) {}),
                const Text('选项 A'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio(value: 2, groupValue: 1, onChanged: (_) {}),
                const Text('选项 B'),
              ],
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio(value: 3, groupValue: 1, onChanged: null),
                Text('禁用'),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),
        const _SubTitle('进度指示器'),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),

        const SizedBox(height: 20),
        const _SubTitle('滑块'),
        const SizedBox(height: 12),
        Slider(value: 0.5, onChanged: (_) {}),

        const SizedBox(height: 20),
        const _SubTitle('头像'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CircleAvatar(radius: 20, child: Icon(Icons.person)),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.accent,
              child: Icon(Icons.home, color: Colors.white),
            ),
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage('https://picsum.photos/100'),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// ========================================
/// 颜色系统 - Material 3 颜色规范
/// ========================================
class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('颜色系统'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SubTitle('基础色板'),
          SizedBox(height: 8),
          _BasicColorGrid(),
          SizedBox(height: 24),

          _SubTitle('灰色阶梯'),
          SizedBox(height: 8),
          _GrayColorGrid(),
          SizedBox(height: 24),

          _SubTitle('语义色'),
          SizedBox(height: 8),
          _SemanticColorGrid(),
          SizedBox(height: 24),

          _SubTitle('ColorScheme 颜色'),
          SizedBox(height: 8),
          _ColorSchemeColors(),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  final String title;
  const _SubTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// 基础色板
class _BasicColorGrid extends StatelessWidget {
  const _BasicColorGrid();

  @override
  Widget build(BuildContext context) {
    return _ColorGrid(colors: [
      _ColorItem('Black', AppTheme.black, isWhite: true),
      _ColorItem('White', AppTheme.white),
    ]);
  }
}

// 灰色阶梯
class _GrayColorGrid extends StatelessWidget {
  const _GrayColorGrid();

  @override
  Widget build(BuildContext context) {
    return _ColorGrid(colors: [
      _ColorItem('50', AppTheme.gray50),
      _ColorItem('100', AppTheme.gray100),
      _ColorItem('200', AppTheme.gray200),
      _ColorItem('300', AppTheme.gray300),
      _ColorItem('400', AppTheme.gray400),
      _ColorItem('500', AppTheme.gray500),
      _ColorItem('600', AppTheme.gray600),
      _ColorItem('700', AppTheme.gray700),
      _ColorItem('800', AppTheme.gray800),
      _ColorItem('900', AppTheme.gray900),
    ]);
  }
}

// 语义色
class _SemanticColorGrid extends StatelessWidget {
  const _SemanticColorGrid();

  @override
  Widget build(BuildContext context) {
    return _ColorGrid(colors: [
      _ColorItem('Primary', AppTheme.primary),
      _ColorItem('Accent', AppTheme.accent),
      _ColorItem('Success', AppTheme.success),
      _ColorItem('Warning', AppTheme.warning),
      _ColorItem('Error', AppTheme.error),
      _ColorItem('Info', AppTheme.info),
    ]);
  }
}

// 通用颜色网格
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
  final bool isWhite;
  _ColorItem(this.name, this.color, {this.isWhite = false});
  String get hexCode => '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

class _ColorCard extends StatelessWidget {
  final _ColorItem item;
  const _ColorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final luminance = item.color.computeLuminance();
    final textColor = luminance > 0.5 ? AppTheme.gray800 : AppTheme.white;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
            border: item.isWhite ? Border.all(color: AppTheme.gray200, width: 1) : null,
            boxShadow: [BoxShadow(color: item.color.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              item.name == 'White' || item.name == 'Black' ? '' : item.name[0],
              style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        Text(item.hexCode, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ColorScheme 完整展示
class _ColorSchemeColors extends StatelessWidget {
  const _ColorSchemeColors();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _ColorRow('primary', cs.primary, cs.onPrimary),
        _ColorRow('onPrimary', cs.onPrimary, cs.primary),
        _ColorRow('primaryContainer', cs.primaryContainer, cs.onPrimaryContainer),
        _ColorRow('onPrimaryContainer', cs.onPrimaryContainer, cs.primaryContainer),
        const SizedBox(height: 8),
        _ColorRow('secondary', cs.secondary, cs.onSecondary),
        _ColorRow('onSecondary', cs.onSecondary, cs.secondary),
        _ColorRow('secondaryContainer', cs.secondaryContainer, cs.onSecondaryContainer),
        _ColorRow('onSecondaryContainer', cs.onSecondaryContainer, cs.secondaryContainer),
        const SizedBox(height: 8),
        _ColorRow('tertiary', cs.tertiary, cs.onTertiary),
        _ColorRow('onTertiary', cs.onTertiary, cs.tertiary),
        _ColorRow('tertiaryContainer', cs.tertiaryContainer, cs.onTertiaryContainer),
        _ColorRow('onTertiaryContainer', cs.onTertiaryContainer, cs.tertiaryContainer),
        const SizedBox(height: 8),
        _ColorRow('surface', cs.surface, cs.onSurface),
        _ColorRow('onSurface', cs.onSurface, cs.surface),
        _ColorRow('surfaceVariant (deprecated)', cs.surfaceVariant, cs.onSurfaceVariant),
        _ColorRow('onSurfaceVariant (deprecated)', cs.onSurfaceVariant, cs.surfaceVariant),
        const SizedBox(height: 8),
        _ColorRow('surfaceContainerLowest', cs.surfaceContainerLowest, cs.onSurface),
        _ColorRow('surfaceContainerLow', cs.surfaceContainerLow, cs.onSurface),
        _ColorRow('surfaceContainer', cs.surfaceContainer, cs.onSurface),
        _ColorRow('surfaceContainerHigh', cs.surfaceContainerHigh, cs.onSurface),
        _ColorRow('surfaceContainerHighest', cs.surfaceContainerHighest, cs.onSurfaceVariant),
        const SizedBox(height: 8),
        _ColorRow('error', cs.error, cs.onError),
        _ColorRow('onError', cs.onError, cs.error),
        _ColorRow('errorContainer', cs.errorContainer, cs.onErrorContainer),
        _ColorRow('onErrorContainer', cs.onErrorContainer, cs.errorContainer),
        const SizedBox(height: 8),
        _ColorRow('outline', cs.outline, cs.surface),
        _ColorRow('outlineVariant', cs.outlineVariant, cs.surface),
        _ColorRow('inverseSurface', cs.inverseSurface, cs.onInverseSurface),
        _ColorRow('onInverseSurface', cs.onInverseSurface, cs.inverseSurface),
        _ColorRow('inversePrimary', cs.inversePrimary, cs.surface),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String name;
  final Color bgColor;
  final Color textColor;
  const _ColorRow(this.name, this.bgColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(name, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
              child: Text(name, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

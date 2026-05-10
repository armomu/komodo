import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/app_bottom_sheet.dart';

/// 十六进制键盘
///
/// 用法：
/// ```dart
/// HexKeyboard.show(value: current, onConfirm: (v) { ... });
/// ```
class HexKeyboard {
  HexKeyboard._();

  /// 弹出十六进制键盘（使用公共 AppBottomSheet 样式）
  static void show({
    required String value,
    required ValueChanged<String> onConfirm,
  }) {
    // 用 ValueNotifier 在 StatelessWidget 内管理输入状态
    final notifier = ValueNotifier<String>(value);

    AppBottomSheet.show(
      maxHeightRatio: 0.75,
      header: AppBottomSheetHeader(
        icon: Icons.keyboard_alt_outlined,
        title: '十六进制输入',
        trailing: ValueListenableBuilder<String>(
          valueListenable: notifier,
          builder: (_, v, __) {
            final bytes = _byteCount(v);
            return Text(
              '$bytes / $_maxBytes 字节',
              style: TextStyle(
                fontSize: 12,
                color: bytes >= _maxBytes
                    ? Colors.redAccent
                    : Colors.white54,
              ),
            );
          },
        ),
      ),
      child: _HexKeyboardBody(
        notifier: notifier,
        onConfirm: onConfirm,
      ),
    );
  }

  static const int _maxBytes = 64;

  static int _byteCount(String v) {
    final clean = v.replaceAll(' ', '');
    return clean.length ~/ 2;
  }
}

// ── 键盘主体（StatefulWidget，持有输入逻辑）───────────────────────
class _HexKeyboardBody extends StatefulWidget {
  final ValueNotifier<String> notifier;
  final ValueChanged<String> onConfirm;

  const _HexKeyboardBody({
    required this.notifier,
    required this.onConfirm,
  });

  @override
  State<_HexKeyboardBody> createState() => _HexKeyboardBodyState();
}

class _HexKeyboardBodyState extends State<_HexKeyboardBody> {
  static const int _maxBytes = 64;

  String get _input => widget.notifier.value;
  set _input(String v) => widget.notifier.value = v;

  void _onChar(String char) {
    final clean = _input.replaceAll(' ', '');
    if (clean.length >= _maxBytes * 2) return;
    final next = clean + char;
    _input = _formatHex(next);
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    final clean = _input.replaceAll(' ', '');
    if (clean.isEmpty) return;
    _input = _formatHex(clean.substring(0, clean.length - 1));
    HapticFeedback.lightImpact();
  }

  void _onClear() {
    _input = '';
    HapticFeedback.mediumImpact();
  }

  /// "AABBCC" → "AA BB CC"
  String _formatHex(String raw) {
    final buf = StringBuffer();
    final upper = raw.toUpperCase();
    for (int i = 0; i < upper.length; i += 2) {
      if (buf.isNotEmpty) buf.write(' ');
      final end = (i + 2 > upper.length) ? upper.length : i + 2;
      buf.write(upper.substring(i, end));
    }
    return buf.toString();
  }

  void _confirm() {
    widget.onConfirm(_input);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // AppBottomSheet 内部已是深色卡片背景，直接渲染键盘内容
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ValueListenableBuilder<String>(
        valueListenable: widget.notifier,
        builder: (_, value, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 输入显示区 ──────────────────────────────────
              _buildDisplay(value),
              const SizedBox(height: 12),

              // ── 键盘按键 ────────────────────────────────────
              _buildRow(['7', '8', '9', 'A', 'B'], hexKeys: {'A', 'B'}),
              const SizedBox(height: 6),
              _buildRow(['4', '5', '6', 'C', 'D'], hexKeys: {'C', 'D'}),
              const SizedBox(height: 6),
              _buildRow(['1', '2', '3', 'E', 'F'], hexKeys: {'E', 'F'}),
              const SizedBox(height: 6),
              _buildSpecialRow(),
              const SizedBox(height: 12),

              // ── 确认按钮 ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDisplay(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.code_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: value.isEmpty
                ? Text(
                    '点击按键输入十六进制数据…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFFFD60A),
                      fontSize: 15,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (value.isNotEmpty)
            GestureDetector(
              onTap: _onClear,
              child: Icon(
                Icons.cancel_outlined,
                size: 18,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, {required Set<String> hexKeys}) {
    return Row(
      children: keys.map((k) {
        final isHex = hexKeys.contains(k);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _KeyButton(
              label: k,
              isHex: isHex,
              onTap: () => _onChar(k),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialRow() {
    return Row(
      children: [
        // CLR
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _KeyButton(
              label: 'CLR',
              isSpecial: true,
              fontSize: 13,
              onTap: _onClear,
            ),
          ),
        ),
        // 0
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _KeyButton(label: '0', onTap: () => _onChar('0')),
          ),
        ),
        // 00
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _KeyButton(
              label: '00',
              isAccent: true,
              fontSize: 14,
              onTap: () {
                _onChar('0');
                _onChar('0');
              },
            ),
          ),
        ),
        // FF
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _KeyButton(
              label: 'FF',
              isHex: true,
              fontSize: 14,
              onTap: () {
                _onChar('F');
                _onChar('F');
              },
            ),
          ),
        ),
        // ⌫
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _BackspaceButton(
              onTap: _onBackspace,
              onLongPress: _onClear,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 普通按键 ──────────────────────────────────────────────────
class _KeyButton extends StatelessWidget {
  final String label;
  final bool isHex;
  final bool isAccent;
  final bool isSpecial; // CLR
  final double fontSize;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isHex = false,
    this.isAccent = false,
    this.isSpecial = false,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    if (isSpecial) {
      bg = Colors.red.withValues(alpha: 0.25);
      fg = Colors.redAccent;
    } else if (isHex) {
      bg = colorScheme.primary.withValues(alpha: 0.18);
      fg = colorScheme.primary;
    } else if (isAccent) {
      bg = Colors.white.withValues(alpha: 0.08);
      fg = Colors.white70;
    } else {
      bg = Colors.white.withValues(alpha: 0.06);
      fg = Colors.white;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isHex || isSpecial
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: fg,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 退格按键 ──────────────────────────────────────────────────
class _BackspaceButton extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BackspaceButton({
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: Colors.white12,
        child: const SizedBox(
          height: 48,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 20,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

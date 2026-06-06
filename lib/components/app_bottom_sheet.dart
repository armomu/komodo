import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ====================================================================
/// AppBottomSheet — 通用底部弹窗组件
///
/// 封装了深色圆角底部弹窗的通用样式，基于 KOMODO 音乐播放列表弹窗
/// (playlist_bottom_sheet.dart) 的 UI 模式提取。
///
/// 用法示例：
/// ```dart
/// AppBottomSheet.show(
///   header: AppBottomSheetHeader(
///     icon: Icons.queue_music,
///     title: '标题',
///     trailing: Text('3/10', style: TextStyle(color: Colors.white54)),
///   ),
///   child: ListView.builder(
///     shrinkWrap: true,
///     itemCount: items.length,
///     itemBuilder: (context, index) => AppBottomSheetItem(
///       leadingIcon: Icons.music_note,
///       title: items[index].title,
///       subtitle: items[index].subtitle,
///       isActive: index == activeIndex,
///       onTap: () => handleTap(index),
///     ),
///   ),
/// );
/// ```
/// ====================================================================

class AppBottomSheet {
  AppBottomSheet._();

  /// 显示底部弹窗
  ///
  /// [child]        — 弹窗主体内容（通常是一个 [ListView] 或 [Column]）
  /// [header]       — 可选的标题栏，放在 [child] 上方
  /// [maxHeightRatio]  — 弹窗最大高度占屏幕比例，默认 0.5
  /// [isScrollControlled] — 是否允许键盘弹出时滚动，默认 true
  static void show({
    required Widget child,
    AppBottomSheetHeader? header,
    double maxHeightRatio = 0.5,
    bool isScrollControlled = true,
  }) {
    Get.bottomSheet(
      Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            if (header != null) header,

            // 标题栏与内容之间的分割线
            if (header != null)
              Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.1),
              ),

            // 主体内容
            Flexible(child: child),

            // 底部安全区域
            SizedBox(height: Get.mediaQuery.padding.bottom),
          ],
        ),
      ),
      backgroundColor: Theme.of(Get.context!).cardTheme.color,
      isScrollControlled: isScrollControlled,
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════
/// 标题栏 — 图标 + 标题 + 尾部附加组件
/// ═════════════════════════════════════════════════════════════════════

class AppBottomSheetHeader extends StatelessWidget {
  /// 左侧图标（可选）
  final IconData? icon;

  /// 标题文字
  final String title;

  /// 标题文字样式
  final TextStyle? titleStyle;

  /// 右侧附加组件（如计数器、操作按钮）
  final Widget? trailing;

  const AppBottomSheetHeader({
    super.key,
    this.icon,
    required this.title,
    this.titleStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style:
                titleStyle ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ═════════════════════════════════════════════════════════════════════
/// 列表项 — 图标 + 标题 + 副标题 + 活跃指示器
/// ═════════════════════════════════════════════════════════════════════

class AppBottomSheetItem extends StatelessWidget {
  /// 左侧图标
  final IconData leadingIcon;

  /// 图标背景色（未选中时使用）
  final Color? leadingColor;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 是否当前选中项
  final bool isActive;

  /// 选中时的强调色
  final Color activeColor;

  /// 选中时右侧显示的图标（默认 [Icons.equalizer]）
  final IconData? activeTrailingIcon;

  /// 点击回调
  final VoidCallback? onTap;

  const AppBottomSheetItem({
    super.key,
    required this.leadingIcon,
    this.leadingColor,
    required this.title,
    this.subtitle,
    this.isActive = false,
    this.activeColor = Colors.white,
    this.activeTrailingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : (leadingColor ?? Colors.white).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isActive
              ? const Icon(Icons.volume_up, color: Colors.white, size: 20)
              : Icon(
                  leadingIcon,
                  color: leadingColor ?? Colors.white70,
                  size: 20,
                ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? Colors.white : Colors.white70,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? Colors.white70
                    : Colors.white.withValues(alpha: 0.4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isActive
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                activeTrailingIcon ?? Icons.equalizer,
                color: Colors.white,
                size: 14,
              ),
            )
          : null,
    );
  }
}

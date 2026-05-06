import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ========================================
/// KOMODO 应用主题配置 - 黑白灰色系
/// ========================================
class AppTheme {
  AppTheme._();

  // ==================== 基础色板 ====================
  // 纯黑白
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // 灰色阶梯 (从浅到深，共11级)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // ==================== 语义化颜色 ====================
  // 主要颜色 - 黑色系
  static const Color primary = black;
  static const Color primaryLight = gray800;
  static const Color primaryDark = Color(0xFF000000);

  // 强调色 - 橙色系（用于重要操作和提示）
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8F66);
  static const Color accentDark = Color(0xFFE55A2B);

  // 状态色
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // 文字颜色
  static const Color textPrimary = black;
  static const Color textSecondary = gray600;
  static const Color textDisabled = gray400;
  static const Color textInverse = white;

  // 分割线
  static const Color divider = gray200;
  static const Color dividerLight = gray100;

  // ==================== 浅色主题 ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: white,
        primaryContainer: gray100,
        onPrimaryContainer: gray900,
        secondary: accent,
        onSecondary: white,
        secondaryContainer: Color(0xFFFFF3E0),
        onSecondaryContainer: accentDark,
        tertiary: gray700,
        onTertiary: white,
        tertiaryContainer: gray100,
        onTertiaryContainer: gray800,
        error: error,
        onError: white,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: error,
        surface: white,
        onSurface: gray900,
        surfaceContainerHighest: gray100,
        onSurfaceVariant: gray600,
        outline: gray300,
        outlineVariant: gray200,
        shadow: black,
        scrim: black,
        inverseSurface: gray900,
        onInverseSurface: white,
        inversePrimary: gray400,
      ),
      scaffoldBackgroundColor: white,

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: white,
        surfaceTintColor: white,
        foregroundColor: gray900,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        iconTheme: IconThemeData(color: gray900),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // 卡片
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gray200, width: 1),
        ),
      ),

      // 列表项
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        iconColor: gray600,
        textColor: gray900,
      ),

      // 分割线
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // 按钮 - 主要按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: white,
          backgroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 按钮 - 次要按钮
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: gray300, width: 1),
          foregroundColor: gray800,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 按钮 - 文字按钮
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gray200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: const TextStyle(color: gray400, fontSize: 16),
        labelStyle: const TextStyle(color: gray600, fontSize: 16),
        errorStyle: const TextStyle(color: error, fontSize: 12),
      ),

      // 底部导航栏
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // Tab 栏
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: gray500,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: gray100,
        selectedColor: gray900,
        disabledColor: gray100,
        labelStyle: const TextStyle(fontSize: 14, color: gray800),
        secondaryLabelStyle: const TextStyle(fontSize: 14, color: white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: gray200, width: 1),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return gray300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(white),
        side: const BorderSide(color: gray400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return gray400;
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: gray700,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: gray300,
        dragHandleSize: Size(40, 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: gray900,
        contentTextStyle: const TextStyle(color: white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: gray200,
        circularTrackColor: gray200,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: gray200,
        thumbColor: white,
        overlayColor: primary.withAlpha(30),
        trackHeight: 4,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: gray800,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ==================== 深色主题 ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: white,
        onPrimary: black,
        primaryContainer: gray800,
        onPrimaryContainer: gray100,
        secondary: accent,
        onSecondary: black,
        secondaryContainer: Color(0xFF5D3F2A),
        onSecondaryContainer: accentLight,
        tertiary: gray400,
        onTertiary: black,
        tertiaryContainer: gray700,
        onTertiaryContainer: gray200,
        error: Color(0xFFEF9A9A),
        onError: black,
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF121212),
        onSurface: gray100,
        surfaceContainerHighest: gray900,
        onSurfaceVariant: gray400,
        outline: gray600,
        outlineVariant: gray700,
        shadow: black,
        scrim: black,
        inverseSurface: gray100,
        onInverseSurface: gray900,
        inversePrimary: gray700,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        foregroundColor: gray100,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray100,
        ),
        iconTheme: IconThemeData(color: gray100),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // 卡片
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gray700, width: 1),
        ),
      ),

      // 列表项
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        iconColor: gray400,
        textColor: gray100,
      ),

      // 分割线
      dividerTheme: const DividerThemeData(
        color: gray700,
        thickness: 1,
        space: 1,
      ),

      // 按钮 - 主要按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: black,
          backgroundColor: white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 按钮 - 次要按钮
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: gray600, width: 1),
          foregroundColor: gray100,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 按钮 - 文字按钮
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gray700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 2),
        ),
        hintStyle: const TextStyle(color: gray600, fontSize: 16),
        labelStyle: const TextStyle(color: gray400, fontSize: 16),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
      ),

      // 底部导航栏
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: white,
        unselectedItemColor: gray500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // Tab 栏
      tabBarTheme: const TabBarThemeData(
        labelColor: white,
        unselectedLabelColor: gray500,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: white, width: 3),
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: gray800,
        selectedColor: white,
        disabledColor: gray800,
        labelStyle: const TextStyle(fontSize: 14, color: gray200),
        secondaryLabelStyle: const TextStyle(fontSize: 14, color: black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: gray700, width: 1),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return black;
          return gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return gray600;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(black),
        side: const BorderSide(color: gray500, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return gray500;
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray100,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: gray400,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: gray600,
        dragHandleSize: Size(40, 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: gray200,
        contentTextStyle: const TextStyle(color: gray900, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: white,
        linearTrackColor: gray700,
        circularTrackColor: gray700,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: white,
        inactiveTrackColor: gray700,
        thumbColor: white,
        overlayColor: white.withAlpha(30),
        trackHeight: 4,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: gray200,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: gray900, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

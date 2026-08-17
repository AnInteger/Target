/// 设计令牌：目标图标 / 颜色的受控枚举与色板（ui-contract.md 极简基调）。
///
/// Goal.iconKey / Goal.colorKey 只存这里的 .name（非自由值，data-model.md）。
library;

import 'package:flutter/material.dart';

/// 目标图标键（Material Symbols 映射）。
enum GoalIcon {
  meal('好好吃饭', Icons.restaurant_outlined),
  fitness('规律运动', Icons.directions_run_outlined),
  sleep('早睡', Icons.bedtime_outlined),
  screenRest('屏幕休息', Icons.mobile_off_outlined),
  project('个人项目', Icons.code_outlined),
  travel('旅行', Icons.flight_takeoff_outlined),
  read('阅读', Icons.menu_book_outlined),
  water('喝水', Icons.water_drop_outlined),
  meditate('冥想', Icons.self_improvement_outlined),
  health('健康', Icons.favorite_outline),
  family('家人', Icons.diversity_1_outlined),
  star('自定义', Icons.star_outline);

  const GoalIcon(this.zhLabel, this.icon);

  final String zhLabel;
  final IconData icon;

  static GoalIcon byKey(String key) =>
      GoalIcon.values.firstWhere((i) => i.name == key, orElse: () => GoalIcon.star);
}

/// 目标颜色键。色板温和低饱和（教练式、非警告性）；深色模式单独映射。
enum GoalColor {
  coral('珊瑚', Color(0xFFE2725B), Color(0xFFF0A292)),
  amber('琥珀', Color(0xFFD99A2B), Color(0xFFE8C078)),
  sage('鼠尾草', Color(0xFF7A9B76), Color(0xFFA9C3A6)),
  teal('青瓷', Color(0xFF4F9D8D), Color(0xFF8BC4B8)),
  sky('晴空', Color(0xFF5B8DB8), Color(0xFF96BADB)),
  indigo('黛蓝', Color(0xFF6674AC), Color(0xFFA2ABD1)),
  plum('紫檀', Color(0xFF9C6B9F), Color(0xFFC3A1C5)),
  stone('石灰', Color(0xFF8A8D8F), Color(0xFFB9BCBE));

  const GoalColor(this.zhLabel, this.light, this.dark);

  final String zhLabel;
  final Color light;
  final Color dark;

  static GoalColor byKey(String key) => GoalColor.values
      .firstWhere((c) => c.name == key, orElse: () => GoalColor.teal);

  Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// App 主题（Material 3，极简留白）。
abstract final class AppTheme {
  static const seed = Color(0xFF4F9D8D);

  static ThemeData light() => _base(ColorScheme.fromSeed(seedColor: seed));

  static ThemeData dark() =>
      _base(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark));

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

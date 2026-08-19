/// 设计令牌 ·「柔彩仪表盘」（FR-009 定稿，2026-08-19）。
///
/// **本文件是三端令牌的唯一真源**（契约 design-language.md §2-4）：
/// - CSS 镜像 `design/tokens.css`（原型侧）
/// - Swift 镜像 `ios/TargetWidgets/DesignTokens.swift`（小组件侧，T029）
/// 改色必须一次提交内完成双侧同步。
///
/// 结构：语义色浅/深成对（[TargetPalette] ThemeExtension）、8 目标色
/// （键名冻结 = Goal.colorKey 持久化数据）、九档字阶（数字一律
/// tabular figures）、间距/圆角/阴影/动效刻度。屏幕代码只准取值于
/// 本文件（token_contract_test.dart 扫描强制）。
///
/// 字体说明：Flutter 侧走系统字体栈（iOS = SF Pro + PingFang SC）；
/// Web 原型的 Inter 为 HTML 侧专属（data URI 内嵌），两侧字形以
/// 字号/字重/行高刻度对齐。
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

/// 目标颜色键（**键名冻结**：Goal.colorKey 只存 .name，校准色值需
/// 同步 design/tokens.css 与 DesignTokens.swift）。浅色 ≈ -500/-600
/// 重量；深色提亮两档保持 8 色互可区分。
enum GoalColor {
  coral('珊瑚', Color(0xFFD9534F), Color(0xFFEF8A80)),
  amber('琥珀', Color(0xFFC98A1B), Color(0xFFEAB54E)),
  sage('鼠尾草', Color(0xFF4E9D68), Color(0xFF7CC796)),
  teal('青瓷', Color(0xFF2B8F84), Color(0xFF6FC4B9)),
  sky('晴空', Color(0xFF4483C4), Color(0xFF85B8E8)),
  indigo('黛蓝', Color(0xFF5B6AB0), Color(0xFF9AA5E0)),
  plum('紫檀', Color(0xFF9A5FA0), Color(0xFFCF9DD2)),
  stone('石灰', Color(0xFF7A7E87), Color(0xFFADAFB6));

  const GoalColor(this.zhLabel, this.light, this.dark);

  final String zhLabel;
  final Color light;
  final Color dark;

  static GoalColor byKey(String key) => GoalColor.values
      .firstWhere((c) => c.name == key, orElse: () => GoalColor.teal);

  Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 头像装饰渐变对（身份填充，非文字场景——取填充级明度，不与
/// 目标文字色共用；浅深同值）。对应 `--grad-avatar-a/b`。
const Color kAvatarGradA = Color(0xFFEAB54E);
const Color kAvatarGradB = Color(0xFFEF8A80);

/// 语义色与材质令牌（浅/深成对，经 [Theme.extension] 注入，
/// 取值：`TargetPalette.of(context)`）。
///
/// 与 CSS 镜像的命名对应：`--on-surface-variant` → `onSurfaceVariant`，
/// `--bg-grad-1..4` → `bgGrad`（四段底幕渐变，135deg）等。
class TargetPalette extends ThemeExtension<TargetPalette> {
  const TargetPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.accent,
    required this.accentOn,
    required this.positive,
    required this.positiveFill,
    required this.positiveOn,
    required this.warning,
    required this.divider,
    required this.bgGrad,
    required this.glassShell,
    required this.glassCard,
    required this.glassBorder,
    required this.blur,
    required this.shadowLow,
    required this.shadowMid,
    required this.shadowHigh,
  });

  /// 页面底色（渐变的近似均值，非渐变兜底）。
  final Color background;

  /// 卡片/容器（白玻璃卡实体等效）。
  final Color surface;

  /// 次级分组底。
  final Color surfaceAlt;

  /// 主文字 / 次级文字。
  final Color onSurface;
  final Color onSurfaceVariant;

  /// 主强调（浅色黑实心 / 深色白实心，反色强调）。
  final Color accent;
  final Color accentOn;

  /// 完成/达成：文本色（浅色深橄榄保 AA，深色直接青柠）与填充对。
  final Color positive;
  final Color positiveFill;
  final Color positiveOn;

  /// 忙碌/落后（克制琥珀）。
  final Color warning;

  /// 发丝分隔线。
  final Color divider;

  /// 四段粉紫底幕渐变（浅）／暗紫（深）。角度恒 135deg（左上→右下）。
  final List<Color> bgGrad;

  /// 玻璃两层景深：手机壳层 / 卡片层 / 描边，及模糊半径。
  final Color glassShell;
  final Color glassCard;
  final Color glassBorder;
  final double blur;

  /// 三档阴影；深色 high 为空列表（以亮度差表达层级，契约禁重阴影）。
  final List<BoxShadow> shadowLow;
  final List<BoxShadow> shadowMid;
  final List<BoxShadow> shadowHigh;

  /// 浅色 ·「柔彩仪表盘」（同步自 design/tokens.css :root）。
  /// R4 修订（2026-08-20）：底幕渐变按参照图屏幕实测锚点重铸为可见的
  /// 粉→紫对角（顶 #f1e0e6 → 底 #d9d3f5）；accent 纯黑 → 墨梅 #252230；
  /// shadowLow 改弥散软影。
  static const TargetPalette light = TargetPalette(
    background: Color(0xFFDED3ED),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F0F9),
    onSurface: Color(0xFF1D1A24),
    onSurfaceVariant: Color(0xFF565264),
    accent: Color(0xFF252230),
    accentOn: Color(0xFFFFFFFF),
    positive: Color(0xFF5C7D10),
    positiveFill: Color(0xFFB5E550),
    positiveOn: Color(0xFF24280F),
    warning: Color(0xFF9A6700),
    divider: Color(0xFFE8E3F0),
    bgGrad: [
      Color(0xFFECD8E0),
      Color(0xFFE2D3E9),
      Color(0xFFD9D1F2),
      Color(0xFFD1CCF8),
    ],
    glassShell: Color(0x99FFFFFF),
    glassCard: Color(0xCCFFFFFF),
    glassBorder: Color(0xA6FFFFFF),
    blur: 24,
    shadowLow: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 10, color: Color(0x0F252230)),
    ],
    shadowMid: [
      BoxShadow(offset: Offset(0, 8), blurRadius: 22, color: Color(0x242E1A42)),
    ],
    shadowHigh: [
      BoxShadow(offset: Offset(0, 14), blurRadius: 38, color: Color(0x3D252230)),
    ],
  );

  /// 深色 · 暗紫底幕 + 深玻璃壳 + 反色强调（同步自 tokens.css dark 块）。
  static const TargetPalette dark = TargetPalette(
    background: Color(0xFF1E1830),
    surface: Color(0xFF241E33),
    surfaceAlt: Color(0xFF2D2640),
    onSurface: Color(0xFFF2EFF7),
    onSurfaceVariant: Color(0xFFA8A1B8),
    accent: Color(0xFFF2EFF7),
    accentOn: Color(0xFF1A1622),
    positive: Color(0xFFB5E550),
    positiveFill: Color(0xFFB5E550),
    positiveOn: Color(0xFF24280F),
    warning: Color(0xFFE8B04B),
    divider: Color(0xFF322B44),
    bgGrad: [
      Color(0xFF2C2036),
      Color(0xFF221A30),
      Color(0xFF1A1526),
      Color(0xFF120E1C),
    ],
    glassShell: Color(0x8C14101C),
    glassCard: Color(0x17FFFFFF),
    glassBorder: Color(0x14FFFFFF),
    blur: 24,
    shadowLow: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 4, color: Color(0x47000000)),
    ],
    shadowMid: [
      BoxShadow(offset: Offset(0, 6), blurRadius: 16, color: Color(0x52000000)),
    ],
    shadowHigh: [],
  );

  /// 取当前主题注入的令牌（[AppTheme] 恒安装，非空）。
  static TargetPalette of(BuildContext context) =>
      Theme.of(context).extension<TargetPalette>()!;

  @override
  TargetPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? accent,
    Color? accentOn,
    Color? positive,
    Color? positiveFill,
    Color? positiveOn,
    Color? warning,
    Color? divider,
    List<Color>? bgGrad,
    Color? glassShell,
    Color? glassCard,
    Color? glassBorder,
    double? blur,
    List<BoxShadow>? shadowLow,
    List<BoxShadow>? shadowMid,
    List<BoxShadow>? shadowHigh,
  }) =>
      TargetPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        onSurface: onSurface ?? this.onSurface,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
        accent: accent ?? this.accent,
        accentOn: accentOn ?? this.accentOn,
        positive: positive ?? this.positive,
        positiveFill: positiveFill ?? this.positiveFill,
        positiveOn: positiveOn ?? this.positiveOn,
        warning: warning ?? this.warning,
        divider: divider ?? this.divider,
        bgGrad: bgGrad ?? this.bgGrad,
        glassShell: glassShell ?? this.glassShell,
        glassCard: glassCard ?? this.glassCard,
        glassBorder: glassBorder ?? this.glassBorder,
        blur: blur ?? this.blur,
        shadowLow: shadowLow ?? this.shadowLow,
        shadowMid: shadowMid ?? this.shadowMid,
        shadowHigh: shadowHigh ?? this.shadowHigh,
      );

  @override
  TargetPalette lerp(TargetPalette? other, double t) {
    if (other is! TargetPalette) return this;
    return TargetPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveFill: Color.lerp(positiveFill, other.positiveFill, t)!,
      positiveOn: Color.lerp(positiveOn, other.positiveOn, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      bgGrad: [
        for (var i = 0; i < bgGrad.length; i++)
          Color.lerp(bgGrad[i], other.bgGrad[i], t)!,
      ],
      glassShell: Color.lerp(glassShell, other.glassShell, t)!,
      glassCard: Color.lerp(glassCard, other.glassCard, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      blur: blur + (other.blur - blur) * t,
      shadowLow:
          BoxShadow.lerpList(shadowLow, other.shadowLow, t) ?? shadowLow,
      shadowMid: BoxShadow.lerpList(shadowMid, other.shadowMid, t) ?? shadowMid,
      shadowHigh:
          BoxShadow.lerpList(shadowHigh, other.shadowHigh, t) ?? shadowHigh,
    );
  }
}

/// 间距刻度（4 的倍数；20 为 2026-08-19 增补档，契约变更记录）。
abstract final class AppSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

/// 圆角刻度（sm 8 / md 12 / lg 16 / xl 24 / full）。
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static final Radius full = Radius.circular(9999);
  static final BorderRadius rSm = BorderRadius.circular(sm);
  static final BorderRadius rMd = BorderRadius.circular(md);
  static final BorderRadius rLg = BorderRadius.circular(lg);
  static final BorderRadius rXl = BorderRadius.circular(xl);
}

/// 动效刻度（统一标准减速曲线族 cubic-bezier(.2,0,0,1)）。
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  /// 成就时刻上限 1200ms 内取 1000ms。
  static const Duration celebration = Duration(milliseconds: 1000);

  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
}

/// 九档字阶的规范名（映射到 Material 槽位，见 [AppTheme._textTheme]）。
/// 数字场景（进度/计数/日期）已全档启用 tabular figures——避免逐场景
/// 判断遗漏，宽度代价可忽略。
extension AppTextX on TextTheme {
  /// displayLarge：36 / 1.25 / 800 / -0.9（两行编辑级 display）。
  TextStyle get displayL => displayLarge!;

  /// displayMedium：28 / 1.25 / 700。
  TextStyle get displayM => displayMedium!;

  /// titleLarge：22 / 1.3 / 700。
  TextStyle get titleL => titleLarge!;

  /// titleMedium：18 / 1.35 / 700。
  TextStyle get titleM => titleMedium!;

  /// titleSmall：16 / 1.45 / 700（卡片目标标题）。
  TextStyle get titleS => titleSmall!;

  /// bodyLarge：17 / 1.5 / 400。
  TextStyle get bodyL => bodyLarge!;

  /// bodyMedium：14 / 1.5 / 400。
  TextStyle get bodyM => bodyMedium!;

  /// bodySmall：12 / 1.4 / 400。
  TextStyle get bodyS => bodySmall!;

  /// labelSmall：11 / 1.3 / 400（胶囊/角标）。
  TextStyle get labelS => labelSmall!;
}

/// App 主题（Material 3）：完整 ColorScheme 由令牌组装（弃 fromSeed），
/// 并安装 [TargetPalette] 扩展与令牌化组件主题。
abstract final class AppTheme {
  static ThemeData light() => _build(TargetPalette.light, Brightness.light);

  static ThemeData dark() => _build(TargetPalette.dark, Brightness.dark);

  static ThemeData _build(TargetPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      // 主强调（浅黑实心 / 深白实心）。
      primary: p.accent,
      onPrimary: p.accentOn,
      // 完成语义对（青柠填充）。
      secondary: p.positiveFill,
      onSecondary: p.positiveOn,
      tertiary: p.accent,
      onTertiary: p.accentOn,
      // 功能色。
      error: brightness == Brightness.light
          ? const Color(0xFFB3261E)
          : const Color(0xFFF2B8B5),
      onError: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF601410),
      // 表面层次。
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      surfaceContainerLowest:
          brightness == Brightness.light
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF241E33),
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh:
          brightness == Brightness.light
              ? const Color(0xFFEDE5F7)
              : const Color(0xFF352D4A),
      surfaceContainerHighest:
          brightness == Brightness.light
              ? const Color(0xFFE5DCEE)
              : const Color(0xFF3D3454),
      outline: brightness == Brightness.light
          ? const Color(0xFF6F6A7C)
          : const Color(0xFF8F88A0),
      outlineVariant: p.divider,
      inverseSurface: brightness == Brightness.light
          ? const Color(0xFF2F2839)
          : const Color(0xFFEDE9F5),
      onInverseSurface: brightness == Brightness.light
          ? const Color(0xFFF2EFF7)
          : const Color(0xFF1A1622),
      scrim: const Color(0xFF1D1A24),
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: _textTheme(p),
      extensions: [p],
    );
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: p.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme(p).titleMedium,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.divider),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s1 + AppSpace.s1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s5,
            vertical: AppSpace.s3,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: p.positiveFill,
      ),
    );
  }

  /// 九档字阶 → Material 15 槽位（全档 tabular figures）。
  static TextTheme _textTheme(TargetPalette p) {
    const f = [FontFeature.tabularFigures()];
    final on = p.onSurface;
    final variant = p.onSurfaceVariant;
    return TextTheme(
      // display：36/28。
      displayLarge: TextStyle(
          fontSize: 36, height: 1.25, fontWeight: FontWeight.w800,
          letterSpacing: -0.9, color: on, fontFeatures: f),
      displayMedium: TextStyle(
          fontSize: 28, height: 1.25, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      displaySmall: TextStyle(
          fontSize: 22, height: 1.3, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      // headline：22 / 18 / 16(700)。
      headlineLarge: TextStyle(
          fontSize: 22, height: 1.3, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      headlineMedium: TextStyle(
          fontSize: 18, height: 1.35, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      headlineSmall: TextStyle(
          fontSize: 16, height: 1.45, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      // title：22 / 18 / 16(700)。
      titleLarge: TextStyle(
          fontSize: 22, height: 1.3, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      titleMedium: TextStyle(
          fontSize: 18, height: 1.35, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      titleSmall: TextStyle(
          fontSize: 16, height: 1.45, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      // body：17 / 14 / 12。
      bodyLarge: TextStyle(
          fontSize: 17, height: 1.5, color: on, fontFeatures: f),
      bodyMedium: TextStyle(
          fontSize: 14, height: 1.5, color: on, fontFeatures: f),
      bodySmall: TextStyle(
          fontSize: 12, height: 1.4, color: variant, fontFeatures: f),
      // label：14 / 12 / 11（500，次级色）。
      labelLarge: TextStyle(
          fontSize: 14, height: 1.3, fontWeight: FontWeight.w400,
          color: variant, fontFeatures: f),
      labelMedium: TextStyle(
          fontSize: 12, height: 1.3, fontWeight: FontWeight.w400,
          color: variant, fontFeatures: f),
      labelSmall: TextStyle(
          fontSize: 11, height: 1.3, fontWeight: FontWeight.w400,
          color: variant, fontFeatures: f),
    );
  }
}

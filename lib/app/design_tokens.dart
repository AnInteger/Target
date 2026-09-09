/// v3 设计令牌（iOS 原生 Cupertino 风格）。
///
/// 真源镜像：design/tokens.css（?v=v3b）↔ 本文件 ↔
/// ios/TargetWidgets/DesignTokens.swift——改值一次提交内三端同步
/// （006 contracts/design-language.md）。
/// 字体：平台默认（iOS=SF Pro/PingFang，不打包字体文件）。
/// 标题族字重 700（R9：整体加重的裁定；iOS 中文 PingFang 止于
/// Semibold 时由系统就近匹配，拉丁/数字走 SF Pro Bold）。
///
/// v3.1（Cupertino 重构）：令牌脱离 Material ThemeExtension，配色值
/// 原样保留；退役 Liquid Glass 仿制令牌（glassShell/glassCard/
/// glassBorder/glassHighlight/blur）——组件全面改用官方 Cupertino 库，
/// 不再手绘玻璃（design/ 与 ios/ 侧镜像变量不动，供原型/原生组件自用）。
library;

import 'package:flutter/cupertino.dart';

// ---------------------------------------------------------------------------
// 分类色板（iOS 系统色 · 浅深成对；goals.colorKey 值域）
// ---------------------------------------------------------------------------

/// 目标颜色板（9 键；gray 为未分类/其他默认）。
abstract final class GoalPalette {
  static const Map<String, Color> light = {
    'blue': Color(0xFF007AFF),
    'green': Color(0xFF34C759),
    'orange': Color(0xFFFF9500),
    'purple': Color(0xFFAF52DE),
    'pink': Color(0xFFFF2D55),
    'indigo': Color(0xFF5856D6),
    'teal': Color(0xFF30B0C7),
    'red': Color(0xFFFF3B30),
    'gray': Color(0xFF8E8E93),
  };

  static const Map<String, Color> dark = {
    'blue': Color(0xFF0A84FF),
    'green': Color(0xFF30D158),
    'orange': Color(0xFFFF9F0A),
    'purple': Color(0xFFBF5AF2),
    'pink': Color(0xFFFF375F),
    'indigo': Color(0xFF5E5CE6),
    'teal': Color(0xFF40C8E0),
    'red': Color(0xFFFF453A),
    'gray': Color(0xFF98989F),
  };

  /// 按 colorKey 取色（未知键回退 gray）。
  static Color byKey(String key, {required Brightness brightness}) =>
      (brightness == Brightness.light ? light : dark)[key] ??
      (brightness == Brightness.light ? light : dark)['gray']!;
}

// ---------------------------------------------------------------------------
// TargetPalette（v3.1 起为纯常量类，经 context 亮度解析）
// ---------------------------------------------------------------------------

///
/// ### 语义槽位
/// * [background]——页面底色（iOS 分组底）；
/// * [surface]/[surfaceAlt]——卡片 / 卡上内嵌控件底；
/// * [onSurface] 一族——主文 / 次文（AA）/ 三档（时间戳、占位）；
/// * [accent] 一族——行动色、实底按钮标签、淡底、正文级蓝；
/// * [milestone] 一族——里程碑橙系；
/// * [positive]/[warning]/[danger]——达成/落后/危险；
/// * [headerGrad]——tab 屏头部渐变；
/// * [shadow*]——卡 / 悬浮 / sheet / 主行动钮光晕。
class TargetPalette {
  const TargetPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceTertiary,
    required this.accent,
    required this.accentOn,
    required this.accentTint,
    required this.accentText,
    required this.milestone,
    required this.milestoneTint,
    required this.milestoneText,
    required this.positive,
    required this.positiveFill,
    required this.positiveOn,
    required this.warning,
    required this.divider,
    required this.scrim,
    required this.danger,
    required this.dangerOn,
    required this.headerGrad,
    required this.shadowLow,
    required this.shadowMid,
    required this.shadowHigh,
    required this.shadowCta,
  });

  /// 页面底色（iOS 分组底）。
  final Color background;

  /// 卡片。
  final Color surface;

  /// 卡上内嵌控件底。
  final Color surfaceAlt;

  /// 主文 / 次文（AA）/ 三档（时间戳、占位，非正文级）。
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceTertiary;

  /// 行动色（填充/图形）与实底按钮标签（17px/700 大字号档）。
  final Color accent;
  final Color accentOn;

  /// 选中态淡底（tab 胶囊之外的内嵌底）。
  final Color accentTint;

  /// 正文级蓝（链接；≥4.5:1）。
  final Color accentText;

  /// 里程碑语义：图形橙 / 暖色 tile / 正文级橙。
  final Color milestone;
  final Color milestoneTint;
  final Color milestoneText;

  /// 完成/达成（iOS 绿族）。
  final Color positive;
  final Color positiveFill;
  final Color positiveOn;

  /// 落后/注意（克制琥珀）。
  final Color warning;

  /// 发丝分隔线。
  final Color divider;

  /// sheet/菜单遮罩。
  final Color scrim;

  /// 危险操作（删除）。
  final Color danger;
  final Color dangerOn;

  /// tab 屏头部渐变（淡紫→粉→灰；深色暗紫系；自上而下）。
  final List<Color> headerGrad;

  /// 阴影：low=卡 / mid=悬浮 / high=sheet / cta=主行动钮光晕。
  final List<BoxShadow> shadowLow;
  final List<BoxShadow> shadowMid;
  final List<BoxShadow> shadowHigh;
  final List<BoxShadow> shadowCta;

  /// 浅色 · v3（同步 tokens.css :root ?v=v3b）。
  static const TargetPalette light = TargetPalette(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F2F7),
    onSurface: Color(0xFF1C1C1E),
    onSurfaceVariant: Color(0xFF6C6C70),
    onSurfaceTertiary: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    accentOn: Color(0xFFFFFFFF),
    accentTint: Color(0x1A007AFF),
    accentText: Color(0xFF0066D6),
    milestone: Color(0xFFFF9500),
    milestoneTint: Color(0xFFFFF3E0),
    milestoneText: Color(0xFF9A5700),
    positive: Color(0xFF188038),
    positiveFill: Color(0xFF34C759),
    positiveOn: Color(0xFF0A3D1D),
    warning: Color(0xFF9A5700),
    divider: Color(0xFFE5E5EA),
    scrim: Color(0x52000000),
    danger: Color(0xFFFF3B30),
    dangerOn: Color(0xFFFFFFFF),
    headerGrad: [
      Color(0xFFE2D5F0),
      Color(0xFFEDD8E8),
      Color(0xFFF2F2F7),
      Color(0xFFF2F2F7),
    ],
    shadowLow: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0x12000000)),
    ],
    shadowMid: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 16, color: Color(0x1A000000)),
    ],
    shadowHigh: [
      BoxShadow(
        offset: Offset(0, -6),
        blurRadius: 40,
        color: Color(0x2E000000),
      ),
    ],
    shadowCta: [
      BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x59007AFF)),
    ],
  );

  /// 深色 · v3（iOS 暗色系：纯黑分组底 + #1C1C1E 卡）。
  static const TargetPalette dark = TargetPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2C2C2E),
    onSurface: Color(0xFFF5F5F7),
    onSurfaceVariant: Color(0xFFA5A5AB),
    onSurfaceTertiary: Color(0xFF7C7C83),
    accent: Color(0xFF0A84FF),
    accentOn: Color(0xFFFFFFFF),
    accentTint: Color(0x380A84FF),
    accentText: Color(0xFF409CFF),
    milestone: Color(0xFFFF9F0A),
    milestoneTint: Color(0xFF3A2A10),
    milestoneText: Color(0xFFFFB86B),
    positive: Color(0xFF30D158),
    positiveFill: Color(0xFF30D158),
    positiveOn: Color(0xFF062B15),
    warning: Color(0xFFFFB86B),
    divider: Color(0xFF38383A),
    scrim: Color(0x8C000000),
    danger: Color(0xFFFF453A),
    dangerOn: Color(0xFFFFFFFF),
    headerGrad: [
      Color(0xFF362F4A),
      Color(0xFF2B2539),
      Color(0xFF161618),
      Color(0xFF000000),
    ],
    shadowLow: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0x59000000)),
    ],
    shadowMid: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 16, color: Color(0x73000000)),
    ],
    shadowHigh: [
      BoxShadow(
        offset: Offset(0, -6),
        blurRadius: 40,
        color: Color(0x8C000000),
      ),
    ],
    shadowCta: [
      BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x660A84FF)),
    ],
  );

  /// 当前上下文的亮暗（CupertinoApp 无 Material Theme）。
  static Brightness brightnessOf(BuildContext context) =>
      CupertinoTheme.maybeBrightnessOf(context) ??
      MediaQuery.platformBrightnessOf(context);

  /// 取当前亮暗对应的令牌。
  static TargetPalette of(BuildContext context) =>
      brightnessOf(context) == Brightness.light
      ? TargetPalette.light
      : TargetPalette.dark;
}

// ---------------------------------------------------------------------------
// 刻度（间距 / 屏级 / 圆角 / 动效）
// ---------------------------------------------------------------------------

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

abstract final class AppScreen {
  /// 页缘 20（R1 Figma px-5）。
  static const double padX = 20;

  /// 卡缘 16。
  static const double cardPadX = 16;
  static const double titleTop = 8;
  static const double titleBand = 44;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 12;

  /// 标准卡片（R11b：与导航条胶囊同圆角 28）。
  static const double lg = 28;

  /// sheet 顶部/大容器（与卡片同步 28）。
  static const double xl = 28;

  static const double full = 9999;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  /// sheet 升降。
  static const Duration sheet = Duration(milliseconds: 320);
  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
}

// ---------------------------------------------------------------------------
// 字阶（SF 阶梯；全档 tabular；标题族 700、次文族 500——R9 裁定）
// ---------------------------------------------------------------------------

/// 字阶取用（v3.1 起独立于 Material TextTheme）。
///
/// 用法：`final text = AppText.of(context); Text(t, style: text.titleM)`。
/// 颜色按旧 v3 Material 字阶等价烘焙（标题/正文=主文，bodyM/S=次文，
/// labelS=三档）；调用点沿用 `.copyWith` 微调。
class AppText {
  AppText._(this._p);

  final TargetPalette _p;

  /// 当前上下文的字阶（颜色随亮暗令牌）。
  static AppText of(BuildContext context) =>
      AppText._(TargetPalette.of(context));

  static const _tabular = [FontFeature.tabularFigures()];

  // 标题族（700）。

  /// displayL：34 / 700（tab 屏大标题）。
  late final TextStyle displayL = _title(34, letterSpacing: -0.02);

  /// displayM：32 / 700（次级屏题）。
  late final TextStyle displayM = _title(32, letterSpacing: -0.02);

  /// displayS：26 / 700（sheet 主标题）。
  late final TextStyle displayS = _title(26, letterSpacing: -0.01);

  /// titleL：22 / 700（卡题/大数字）。
  late final TextStyle titleL = _title(22);

  /// titleM：17 / 700（区块头/行主文）。
  late final TextStyle titleM = _title(17);

  /// titleS：15 / 700（行内强调）。
  late final TextStyle titleS = _title(15);

  // 正文族。

  /// bodyL：17 / 400（iOS body；主文色）。
  late final TextStyle bodyL = _body(17, color: _p.onSurface);

  /// bodyM：15 / 500（次文色；R9 随标题族微升）。
  late final TextStyle bodyM = _body(
    15,
    color: _p.onSurfaceVariant,
    weight: FontWeight.w500,
  );

  /// bodyS：13 / 500（辅助；次文色）。
  late final TextStyle bodyS = _body(
    13,
    color: _p.onSurfaceVariant,
    weight: FontWeight.w500,
  );

  /// labelS：11 / 400（三档色）。
  late final TextStyle labelS = _body(11, color: _p.onSurfaceTertiary);

  TextStyle _title(double size, {double? letterSpacing}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: letterSpacing,
    color: _p.onSurface,
    fontFeatures: _tabular,
  );

  TextStyle _body(
    double size, {
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: _tabular,
  );
}

// ---------------------------------------------------------------------------
// App 主题（Cupertino）
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  /// 亮暗 → 令牌。
  static TargetPalette paletteOf(Brightness brightness) =>
      brightness == Brightness.light ? TargetPalette.light : TargetPalette.dark;

  /// 令牌 + 亮暗 → CupertinoThemeData。
  ///
  /// 注：CupertinoApp 无 darkTheme/themeMode 参数，由 [TargetApp] 按三档
  /// 设置先行解析亮暗后传入唯一 theme（brightness 必须显式固定）。
  static CupertinoThemeData cupertino(TargetPalette p, Brightness brightness) {
    final text = AppText._(p);
    final on = p.onSurface;
    final bodyL = text.bodyL.copyWith(color: on);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: p.accent,
      primaryContrastingColor: p.accentOn,
      scaffoldBackgroundColor: p.background,
      barBackgroundColor: p.surface,
      textTheme: CupertinoTextThemeData(
        textStyle: bodyL,
        actionTextStyle: text.bodyL.copyWith(
          color: p.accentText,
          fontWeight: FontWeight.w700,
        ),
        navTitleTextStyle: text.titleM.copyWith(color: on),
        navLargeTitleTextStyle: text.displayL.copyWith(color: on),
        navActionTextStyle: text.bodyL.copyWith(
          color: p.accentText,
          fontWeight: FontWeight.w700,
        ),
        pickerTextStyle: text.bodyM.copyWith(color: on),
        dateTimePickerTextStyle: text.bodyM.copyWith(color: on),
        tabLabelTextStyle: text.bodyS.copyWith(color: on),
      ),
    );
  }
}

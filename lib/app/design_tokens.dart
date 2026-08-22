/// 设计令牌 ·「v2 基准图语言」（004 D1 全量换值，2026-08-23）。
///
/// **本文件是三端令牌的唯一真源**（契约 design-language.md §2-4）：
/// - CSS 镜像 `design/tokens.css`（原型侧）
/// - Swift 镜像 `ios/TargetWidgets/DesignTokens.swift`（小组件侧，T029）
/// 改色必须一次提交内完成双侧同步。
///
/// 结构：语义色浅/深成对（[TargetPalette] ThemeExtension）、三大类
/// 常驻色（[MajorColors]，004 起 8 目标色 GoalColor 退役——colorKey
/// 列 003 已恒空）、九档字阶（数字一律 tabular figures）、间距/圆角/
/// 阴影/动效刻度。屏幕代码只准取值于本文件（token_contract_test.dart
/// 扫描强制 + 三端值对账）。
///
/// 值基准：specs/004-ui-v2-redesign/references/ 四图——深 #121212 底 /
/// 浅 #F5F5F7 底、白卡/深灰卡、蓝色主强调、绿色完成语义、大圆角、
/// 克制留白；「柔彩仪表盘」的粉紫底幕/玻璃材质令牌位保留但换为
/// v2 平实值（结构不变、值全换，D1）。
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

/// 浅/深成对色值（004 v2：三大类常驻色等非语义槽位的通用载体）。
class MajorColor {
  const MajorColor(this.light, this.dark);

  final Color light;
  final Color dark;

  Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 三大类常驻色（004 D1：健康/习惯/目标——三环、关注卡与分类
/// 筛选消费；键位 health/habit/goal 与 T005 MajorCategory 对齐，
/// 值域冻结见 data-model.md）。基准图 02 chips 三色：绿/橙/蓝。
abstract final class MajorColors {
  /// 健康：绿。
  static const MajorColor health =
      MajorColor(Color(0xFF34A853), Color(0xFF4ADE80));

  /// 习惯：橙。
  static const MajorColor habit =
      MajorColor(Color(0xFFFF9800), Color(0xFFFFA726));

  /// 目标：蓝（= 主强调同族，关注主色）。
  static const MajorColor goal =
      MajorColor(Color(0xFF2196F3), Color(0xFF00B0FF));

  static MajorColor byKey(String key) => switch (key) {
        'health' => health,
        'habit' => habit,
        _ => goal,
      };
}

/// 大类渐变对（004 R3 统一梯度裁定 2026-08-23）：关注卡底
/// `LinearGradient(begin: topLeft, end: bottomRight)` 消费 a→b；
/// 构造冻结 = 135° · a 起点亮度≈61 / b 终点亮度≈45，三色仅色相
/// 不同（对应 tokens.css `--grad-{health|habit|goal}-{a|b}`，
/// Widget 侧无此面）。
class MajorGradient {
  const MajorGradient(this.a, this.b);

  /// 渐变起点/终点（各自浅深成对）。
  final MajorColor a;
  final MajorColor b;
}

abstract final class MajorGradients {
  /// 健康：绿。
  static const MajorGradient health = MajorGradient(
    MajorColor(Color(0xFF34A853), Color(0xFF3FB96A)),
    MajorColor(Color(0xFF26803F), Color(0xFF1D6B35)),
  );

  /// 习惯：橙。
  static const MajorGradient habit = MajorGradient(
    MajorColor(Color(0xFFF5923E), Color(0xFFF59E4E)),
    MajorColor(Color(0xFFC26E1B), Color(0xFFB06018)),
  );

  /// 目标：蓝。
  static const MajorGradient goal = MajorGradient(
    MajorColor(Color(0xFF2196F3), Color(0xFF3FA4F0)),
    MajorColor(Color(0xFF1668BA), Color(0xFF155FA0)),
  );

  static MajorGradient byKey(String key) => switch (key) {
        'health' => health,
        'habit' => habit,
        _ => goal,
      };
}

/// 头像环 8 色（004 v2：8 预设头像的装饰环色，键即持久化 avatarKey
/// 值域——profile 专属但色值必须出自本真源文件）。浅深成对，深色
/// 提亮一档保持 8 色互可区分。
const Map<String, MajorColor> kAvatarRingByKey = {
  'favorite': MajorColor(Color(0xFFFF5C8A), Color(0xFFFF7FA5)), // 玫红
  'directions_run': MajorColor(Color(0xFF34A853), Color(0xFF4ADE80)), // 绿
  'menu_book': MajorColor(Color(0xFF2196F3), Color(0xFF00B0FF)), // 蓝
  'brush': MajorColor(Color(0xFF8B5CF6), Color(0xFFA78BFA)), // 紫
  'flight': MajorColor(Color(0xFF00BFA5), Color(0xFF4DD8C3)), // 青
  'savings': MajorColor(Color(0xFFFFC400), Color(0xFFFFD54F)), // 金
  'pets': MajorColor(Color(0xFF8E8E93), Color(0xFFB3B3B3)), // 石墨
  'spa': MajorColor(Color(0xFF5C6BC0), Color(0xFF9FA8DA)), // 黛蓝
};

/// 庆祝迸点 7 色环（celebration 专属装饰，浅/深成对，循环取用）。
const List<MajorColor> kCelebrationDotPalette = [
  MajorColor(Color(0xFFFF5C8A), Color(0xFFFF7FA5)), // 玫红
  MajorColor(Color(0xFF34A853), Color(0xFF4ADE80)), // 绿
  MajorColor(Color(0xFF2196F3), Color(0xFF00B0FF)), // 蓝
  MajorColor(Color(0xFF8B5CF6), Color(0xFFA78BFA)), // 紫
  MajorColor(Color(0xFFFF9800), Color(0xFFFFA726)), // 橙
  MajorColor(Color(0xFF00BFA5), Color(0xFF4DD8C3)), // 青
  MajorColor(Color(0xFFFFC400), Color(0xFFFFD54F)), // 金
];

/// 头像装饰渐变对（身份填充，非文字场景——取填充级明度，不与
/// 文字色共用；浅深同值，004 v2 = 品牌绿→蓝）。对应 `--grad-avatar-a/b`。
const Color kAvatarGradA = Color(0xFF34C759);
const Color kAvatarGradB = Color(0xFF2196F3);

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
    required this.scrim,
    required this.badge,
    required this.badgeOn,
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

  /// 落后/注意（克制琥珀）。
  final Color warning;

  /// 发丝分隔线。
  final Color divider;

  /// 弹层遮罩（003：通知列表/资料编辑等 bottom sheet 的底幕）。
  final Color scrim;

  /// 未读角标及其上文字（003：铃铛红点/计数，目标色退役后语义化独立）。
  final Color badge;
  final Color badgeOn;

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

  /// 浅色 · v2（同步自 design/tokens.css :root；基准图 02）：
  /// #F5F5F7 灰底 + 纯白卡 + 蓝色主强调 + 绿色完成语义；底幕渐变
  /// 收敛为近平的极淡纵向（v2 无可见渐变，四段结构保留）。
  static const TargetPalette light = TargetPalette(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F2F7),
    onSurface: Color(0xFF1C1C1E),
    onSurfaceVariant: Color(0xFF6E6E73),
    accent: Color(0xFF2196F3),
    accentOn: Color(0xFFFFFFFF),
    positive: Color(0xFF188038),
    positiveFill: Color(0xFF34C759),
    positiveOn: Color(0xFF0A3D1D),
    warning: Color(0xFFB26100),
    divider: Color(0xFFE5E5EA),
    scrim: Color(0x591C1C1E),
    badge: Color(0xFFFF3B30),
    badgeOn: Color(0xFFFFFFFF),
    bgGrad: [
      Color(0xFFFAFAFC),
      Color(0xFFF5F5F7),
      Color(0xFFF5F5F7),
      Color(0xFFF0F0F5),
    ],
    glassShell: Color(0xB8FFFFFF),
    glassCard: Color(0xEBFFFFFF),
    glassBorder: Color(0x0F000000),
    blur: 24,
    shadowLow: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 10, color: Color(0x0F1C1C1E)),
    ],
    shadowMid: [
      BoxShadow(offset: Offset(0, 8), blurRadius: 22, color: Color(0x243C3C43)),
    ],
    shadowHigh: [
      BoxShadow(offset: Offset(0, 14), blurRadius: 38, color: Color(0x3D3C3C43)),
    ],
  );

  /// 深色 · v2（同步自 tokens.css dark 块；基准图 01）：#121212 近黑
  /// 底 + #1E1E1E 深灰卡 + 亮蓝主强调 + 亮绿完成语义。
  static const TargetPalette dark = TargetPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceAlt: Color(0xFF252525),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFB3B3B3),
    accent: Color(0xFF00B0FF),
    accentOn: Color(0xFFFFFFFF),
    positive: Color(0xFF4ADE80),
    positiveFill: Color(0xFF4ADE80),
    positiveOn: Color(0xFF062B15),
    warning: Color(0xFFFFB86B),
    divider: Color(0xFF333333),
    scrim: Color(0x80000000),
    badge: Color(0xFFFF453A),
    badgeOn: Color(0xFFFFFFFF),
    bgGrad: [
      Color(0xFF1B1B1B),
      Color(0xFF161616),
      Color(0xFF121212),
      Color(0xFF101010),
    ],
    glassShell: Color(0xB8121212),
    glassCard: Color(0xEB1E1E1E),
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
    Color? scrim,
    Color? badge,
    Color? badgeOn,
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
        scrim: scrim ?? this.scrim,
        badge: badge ?? this.badge,
        badgeOn: badgeOn ?? this.badgeOn,
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
      scrim: Color.lerp(scrim, other.scrim, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      badgeOn: Color.lerp(badgeOn, other.badgeOn, t)!,
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

/// 屏级布局语义（003 FR-008 三屏标题带对齐基准；tokens.css --screen-* 镜像）。
/// 今日/回顾/我的 同构：左缘 24、顶垫 8、最小带高 44。
abstract final class AppScreen {
  static const double padX = 24;
  static const double titleTop = 8;
  static const double titleBand = 44;
}

/// 圆角刻度（sm 8 / md 12 / lg 16 / xl 24 / full）。
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static final Radius full = Radius.circular(9999);
  static final BorderRadius rFull = BorderRadius.circular(9999);
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
  /// displayLarge：32 / 1.25 / 800 / -0.8（大标题「今日/回顾」，004 v2）。
  TextStyle get displayL => displayLarge!;

  /// displayMedium：28 / 1.25 / 700。
  TextStyle get displayM => displayMedium!;

  /// displaySmall：22 / 1.3 / 700（页题）。
  TextStyle get displayS => displaySmall!;

  /// titleLarge：22 / 1.3 / 700。
  TextStyle get titleL => titleLarge!;

  /// titleMedium：20 / 1.35 / 600（区块头，004 v2）。
  TextStyle get titleM => titleMedium!;

  /// titleSmall：16 / 1.45 / 700（卡片目标标题）。
  TextStyle get titleS => titleSmall!;

  /// bodyLarge：16 / 1.5 / 400（正文，004 v2）。
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
              : const Color(0xFF121212),
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh:
          brightness == Brightness.light
              ? const Color(0xFFEBEBF0)
              : const Color(0xFF252525),
      surfaceContainerHighest:
          brightness == Brightness.light
              ? const Color(0xFFE3E3EA)
              : const Color(0xFF2D2D2D),
      outline: brightness == Brightness.light
          ? const Color(0xFF8A8A8E)
          : const Color(0xFF8E8E93),
      outlineVariant: p.divider,
      inverseSurface: brightness == Brightness.light
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFF2F2F7),
      onInverseSurface: brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      scrim: const Color(0xFF1C1C1E),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surface,
        contentTextStyle:
            _textTheme(p).bodyM.copyWith(color: p.onSurface),
        actionTextColor: p.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
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
      // display：32/28（004 v2：大标题 32）。
      displayLarge: TextStyle(
          fontSize: 32, height: 1.25, fontWeight: FontWeight.w800,
          letterSpacing: -0.8, color: on, fontFeatures: f),
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
      // title：22 / 20(600) / 16(700)（004 v2：区块头 20/600）。
      titleLarge: TextStyle(
          fontSize: 22, height: 1.3, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      titleMedium: TextStyle(
          fontSize: 20, height: 1.35, fontWeight: FontWeight.w600,
          color: on, fontFeatures: f),
      titleSmall: TextStyle(
          fontSize: 16, height: 1.45, fontWeight: FontWeight.w700,
          color: on, fontFeatures: f),
      // body：16 / 14 / 12（004 v2：正文 16）。
      bodyLarge: TextStyle(
          fontSize: 16, height: 1.5, color: on, fontFeatures: f),
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

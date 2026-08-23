// 004 T032（SC-001）：双主题文字/图形对比度矩阵——令牌快照级计算。
//
// 用后即留的走查工具（不入测试套件）：`dart run tool/contrast_audit.dart`
// 数值为 2026-08-23 T032 合规终态快照（四枚令牌加深后，见
// design/reviews.md「004 T032」条目）——若令牌再变更，需手动同步本文件
// 值域并复算。阈值：正文 4.5:1（WCAG AA），图形 3.0:1。
// ignore_for_file: avoid_print
import 'dart:math' as math;

double lum(int argb) {
  double f(int c8) {
    final c = c8 / 255;
    return c <= 0.03928
        ? c / 12.92
        : (math.pow((c + 0.055) / 1.055, 2.4) as double);
  }

  final r = f((argb >> 16) & 0xFF),
      g = f((argb >> 8) & 0xFF),
      b = f(argb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// 前景带 α 时先按 α 合成到底色（屏幕实际合成口径）。
int composite(int fg, int bg) {
  final a = (fg >> 24) & 0xFF;
  if (a == 255) return fg;
  final t = a / 255;
  int ch(int shift) {
    final f = (fg >> shift) & 0xFF, b = (bg >> shift) & 0xFF;
    return (f * t + b * (1 - t)).round();
  }

  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

/// bgStack 自底向上合成后再与前景求对比度。
double ratioOn(int fg, List<int> bgStack) {
  var bg = bgStack.first;
  for (var i = 1; i < bgStack.length; i++) {
    bg = composite(bgStack[i], bg);
  }
  final l1 = lum(composite(fg, bg)), l2 = lum(bg);
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

/// T032 终态快照（同步 lib/app/design_tokens.dart）。
const light = <String, int>{
  'background': 0xFFF5F5F7,
  'surface': 0xFFFFFFFF,
  'surfaceAlt': 0xFFF2F2F7,
  'onSurface': 0xFF1C1C1E,
  'onSurfaceVariant': 0xFF6A6A70,
  'accent': 0xFF1565C0,
  'accentOn': 0xFFFFFFFF,
  'positive': 0xFF188038,
  'positiveFill': 0xFF34C759,
  'positiveOn': 0xFF0A3D1D,
  'warning': 0xFF9A5700,
  'gradLightEnd': 0xFFFAFAFC,
  'gradDarkEnd': 0xFFF0F0F5,
  'glassCard': 0xEBFFFFFF,
};
const dark = <String, int>{
  'background': 0xFF121212,
  'surface': 0xFF1E1E1E,
  'surfaceAlt': 0xFF252525,
  'onSurface': 0xFFFFFFFF,
  'onSurfaceVariant': 0xFFB3B3B3,
  'accent': 0xFF00B0FF,
  'accentOn': 0xFF00263B,
  'positive': 0xFF4ADE80,
  'positiveFill': 0xFF4ADE80,
  'positiveOn': 0xFF062B15,
  'warning': 0xFFFFB86B,
  'gradLightEnd': 0xFF1B1B1B,
  'gradDarkEnd': 0xFF101010,
  'glassCard': 0xEB1E1E1E,
};

void report(String theme, Map<String, int> p, int divider) {
  print('== $theme 正文级（阈值 4.5）==');
  final body = <String, (int, List<int>)>{
    'onSurface × surface': (p['onSurface']!, [p['surface']!]),
    'onSurface × surfaceAlt': (p['onSurface']!, [p['surfaceAlt']!]),
    'onSurface × background': (p['onSurface']!, [p['background']!]),
    'onSurface × grad 亮端': (p['onSurface']!, [p['gradLightEnd']!]),
    'onSurface × grad 暗端': (p['onSurface']!, [p['gradDarkEnd']!]),
    'variant × surface': (p['onSurfaceVariant']!, [p['surface']!]),
    'variant × surfaceAlt': (p['onSurfaceVariant']!, [p['surfaceAlt']!]),
    'variant × background': (p['onSurfaceVariant']!, [p['background']!]),
    'variant × grad 亮端': (p['onSurfaceVariant']!, [p['gradLightEnd']!]),
    'variant × grad 暗端': (p['onSurfaceVariant']!, [p['gradDarkEnd']!]),
    'accent 字 × surface': (p['accent']!, [p['surface']!]),
    'accent 字 × surfaceAlt': (p['accent']!, [p['surfaceAlt']!]),
    'accent 字 × grad 暗端': (p['accent']!, [p['gradDarkEnd']!]),
    'accentOn × accent（按钮标签）': (p['accentOn']!, [p['accent']!]),
    'warning × surfaceAlt（降胶囊）': (p['warning']!, [p['surfaceAlt']!]),
    'warning × surface（权限卡题）': (p['warning']!, [p['surface']!]),
    'positiveOn × positiveFill（升胶囊）': (p['positiveOn']!, [p['positiveFill']!]),
    'onSurface × 玻璃卡压 grad 暗端': (
      p['onSurface']!,
      [p['gradDarkEnd']!, p['glassCard']!],
    ),
    'variant × 玻璃卡压 grad 暗端': (
      p['onSurfaceVariant']!,
      [p['gradDarkEnd']!, p['glassCard']!],
    ),
  };
  body.forEach((k, v) {
    final r = ratioOn(v.$1, v.$2);
    print('${r >= 4.5 ? "PASS" : "FAIL"}  ${r.toStringAsFixed(2)}  $k');
  });
  print('== $theme 图形级（阈值 3.0）==');
  final gfx = <String, (int, List<int>)>{
    'positive 弧 × surface': (p['positive']!, [p['surface']!]),
    'positive 描边 × surfaceAlt（半点）': (p['positive']!, [p['surfaceAlt']!]),
    'accent × background': (p['accent']!, [p['background']!]),
    'warning × surface': (p['warning']!, [p['surface']!]),
    'divider × surface（发丝线/空轨·装饰）': (divider, [p['surface']!]),
    'accent × 玻璃卡': (p['accent']!, [p['gradDarkEnd']!, p['glassCard']!]),
  };
  gfx.forEach((k, v) {
    final r = ratioOn(v.$1, v.$2);
    print('${r >= 3.0 ? "PASS" : "FAIL"}  ${r.toStringAsFixed(2)}  $k');
  });
}

void main() {
  report('浅色', light, 0xFFE5E5EA);
  report('深色', dark, 0xFF333333);
  // 留档项（冻结设计固有，见 reviews.md T032 条目）：
  // 关注卡白字 × 大类渐变 a 端 = 2.12–3.12（R3 同构梯度 L61→L45 构造）；
  // 大类图标色 × 浅色 surfaceAlt = 1.93–2.80（类身份冗余编码，文本承载）。
  print('== 留档（冻结设计固有，不计失败）==');
  print('关注卡白字 × 渐变 a 端：habit D 2.12 / health D 2.51 / goal D 2.70');
  print('                        habit L 2.32 / health L 3.06 / goal L 3.12');
  print('大类图标 × 浅 surfaceAlt：habit 1.93 / health 2.74 / goal 2.80');
}

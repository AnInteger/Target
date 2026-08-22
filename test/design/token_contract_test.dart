/// 令牌契约测试（T002 / SC-004）：设计一致性的机械门禁。
///
/// 规则（specs/002-ui-ux-redesign/contracts/design-language.md §2-1）：
/// `lib/features/` 与 `lib/app/` 的屏幕代码只准从 `design_tokens.dart`
/// 取值——禁止 `Color(0x…)` 字面量、禁止带 color:/fontSize: 的裸
/// `TextStyle(`。`design_tokens.dart` 自身豁免（它就是唯一来源）。
///
/// 004 T002 增补：三端值对账——`TargetPalette`（Dart 真源）↔
/// `design/tokens.css`（:root 与 dark 块）↔ `ios/TargetWidgets/
/// DesignTokens.swift`（light/dark 两组件镜像）逐键对色；GoalColor
/// 退役后不得在三端复活。
///
/// 白名单机制：现状代码审计为零违规，白名单为空。若历史遗留需要豁免，
/// 在 [kWhitelist] 登记文件名 + 原因；白名单**只减不增**，清零是
/// tasks.md T031 的完成条件。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/design_tokens.dart';

/// 豁免清单：'文件相对路径': '豁免原因（必填）'。白名单**只减不增**。
/// 现状审计仅 1 个文件 3 处（fontSize 硬编码，颜色取自 theme），
/// 已随 US3/T017 goals_view 重写消灭并于 2026-08-20 移除条目——
/// 白名单清零，T031 完成条件提前达成（后续屏重写不得再入册）。
const kWhitelist = <String, String>{};

void main() {
  test('令牌契约：features/app 层无硬编码颜色与裸 TextStyle（SC-004）', () {
    final violations = <String>[];
    for (final dir in ['lib/features', 'lib/app']) {
      final entity = Directory(dir);
      expect(entity.existsSync(), isTrue, reason: '扫描目录应存在：$dir');
      for (final file in _dartFiles(entity)) {
        final path = file.path.replaceAll('\\', '/');
        if (path.endsWith('design_tokens.dart')) continue; // 唯一来源豁免
        if (kWhitelist.containsKey(path)) continue; // 白名单：只减不增
        final src = file.readAsStringSync();
        if (src.contains('Color(0x')) {
          violations.add('$path: 含 Color(0x…) 字面量');
        }
        violations.addAll(_bareTextStyleIssues(path, src));
      }
    }
    expect(
      violations,
      isEmpty,
      reason: '以下位置违反设计令牌契约（颜色/字号只准取自 '
          'lib/app/design_tokens.dart，白名单见 kWhitelist）：\n'
          '${violations.join('\n')}',
    );
  });

  test('三端对账：Dart 真源 ↔ tokens.css ↔ DesignTokens.swift（004 T002）', () {
    String hex(Color c) =>
        (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

    final css = File('design/tokens.css').readAsStringSync();
    final darkAt = css.indexOf('[data-theme="dark"]');
    expect(darkAt, greaterThan(0), reason: 'tokens.css 应含 dark 块');
    final cssLight = css.substring(0, darkAt);
    final cssDark = css.substring(darkAt);

    // CSS 变量 → 目标色值（缺失/非 #rrggbb 均报错）。
    String cssVar(String block, String name) {
      final m = RegExp('--$name:\\s*#([0-9a-fA-F]{6})').firstMatch(block);
      expect(m, isNotNull, reason: 'tokens.css 缺变量 --$name');
      return m!.group(1)!.toLowerCase();
    }

    final entries = <String, (Color, Color)>{
      'background': (TargetPalette.light.background, TargetPalette.dark.background),
      'surface': (TargetPalette.light.surface, TargetPalette.dark.surface),
      'surface-alt': (TargetPalette.light.surfaceAlt, TargetPalette.dark.surfaceAlt),
      'on-surface': (TargetPalette.light.onSurface, TargetPalette.dark.onSurface),
      'on-surface-variant': (TargetPalette.light.onSurfaceVariant, TargetPalette.dark.onSurfaceVariant),
      'accent': (TargetPalette.light.accent, TargetPalette.dark.accent),
      'positive': (TargetPalette.light.positive, TargetPalette.dark.positive),
      'positive-fill': (TargetPalette.light.positiveFill, TargetPalette.dark.positiveFill),
      'warning': (TargetPalette.light.warning, TargetPalette.dark.warning),
      'divider': (TargetPalette.light.divider, TargetPalette.dark.divider),
      'badge': (TargetPalette.light.badge, TargetPalette.dark.badge),
      'grad-avatar-a': (kAvatarGradA, kAvatarGradA),
      'grad-avatar-b': (kAvatarGradB, kAvatarGradB),
      'major-health': (MajorColors.health.light, MajorColors.health.dark),
      'major-habit': (MajorColors.habit.light, MajorColors.habit.dark),
      'major-goal': (MajorColors.goal.light, MajorColors.goal.dark),
    };
    for (final e in entries.entries) {
      expect(cssVar(cssLight, e.key), hex(e.value.$1),
          reason: 'tokens.css :root --${e.key} 与 Dart 浅色不一致');
      expect(cssVar(cssDark, e.key), hex(e.value.$2),
          reason: 'tokens.css dark --${e.key} 与 Dart 深色不一致');
    }

    // Swift 镜像：WidgetPalette light/dark 九键逐一对色。
    final swift = File('ios/TargetWidgets/DesignTokens.swift').readAsStringSync();
    String swiftField(String palette, String field) {
      final at = swift.indexOf('static let $palette = WidgetPalette(');
      expect(at, greaterThan(-1), reason: 'DesignTokens.swift 缺 $palette 组');
      // 初始化器止于字段闭括号+组闭括号的 '))'。
      final block = swift.substring(at, swift.indexOf('))', at) + 2);
      final m = RegExp('$field: Color\\(hex: 0x([0-9A-Fa-f]{6})\\)')
          .firstMatch(block);
      expect(m, isNotNull, reason: 'DesignTokens.swift $palette 缺 $field');
      return m!.group(1)!.toLowerCase();
    }

    final swiftEntries = <String, (Color, Color)>{
      'surface': (TargetPalette.light.surface, TargetPalette.dark.surface),
      'surfaceAlt': (TargetPalette.light.surfaceAlt, TargetPalette.dark.surfaceAlt),
      'onSurface': (TargetPalette.light.onSurface, TargetPalette.dark.onSurface),
      'onSurfaceVariant': (TargetPalette.light.onSurfaceVariant, TargetPalette.dark.onSurfaceVariant),
      'accent': (TargetPalette.light.accent, TargetPalette.dark.accent),
      'positive': (TargetPalette.light.positive, TargetPalette.dark.positive),
      'positiveFill': (TargetPalette.light.positiveFill, TargetPalette.dark.positiveFill),
      'warning': (TargetPalette.light.warning, TargetPalette.dark.warning),
      'divider': (TargetPalette.light.divider, TargetPalette.dark.divider),
    };
    for (final e in swiftEntries.entries) {
      expect(swiftField('light', e.key), hex(e.value.$1),
          reason: 'DesignTokens.swift light.$e.key 与 Dart 不一致');
      expect(swiftField('dark', e.key), hex(e.value.$2),
          reason: 'DesignTokens.swift dark.$e.key 与 Dart 不一致');
    }

    // GoalColor 退役对账（三端均不得复活）。
    final dartSrc = File('lib/app/design_tokens.dart').readAsStringSync();
    expect(dartSrc.contains('enum GoalColor'), isFalse,
        reason: 'GoalColor 枚举应已退役');
    expect(css.contains('--goal-'), isFalse, reason: 'CSS --goal-* 应已收编为 --major-*');
    expect(swift.contains('goalColor('), isFalse,
        reason: 'Swift goalColor() 应已退役');
  });
}

List<File> _dartFiles(Directory dir) =>
    dir.listSync(recursive: true).whereType<File>().toList()
      ..retainWhere((f) => f.path.endsWith('.dart'));

/// 找出所有 `TextStyle(…)` 的平衡括号片段，检查其中的 color:/fontSize:。
List<String> _bareTextStyleIssues(String path, String src) {
  final issues = <String>[];
  var at = src.indexOf('TextStyle(');
  while (at != -1) {
    final open = at + 'TextStyle'.length; // '(' 的位置
    var depth = 0;
    var i = open;
    for (; i < src.length; i++) {
      if (src[i] == '(') depth++;
      if (src[i] == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    final body = src.substring(open + 1, i.clamp(open + 1, src.length));
    if (body.contains('color:') || body.contains('fontSize:')) {
      final line = src.substring(0, open).split('\n').length;
      issues.add('$path:$line: 裸 TextStyle( 带 color:/fontSize:');
    }
    at = src.indexOf('TextStyle(', at + 1);
  }
  return issues;
}

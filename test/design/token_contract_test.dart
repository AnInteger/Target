/// 令牌契约测试（T002 / SC-004）：设计一致性的机械门禁。
///
/// 规则（specs/002-ui-ux-redesign/contracts/design-language.md §2-1）：
/// `lib/features/` 与 `lib/app/` 的屏幕代码只准从 `design_tokens.dart`
/// 取值——禁止 `Color(0x…)` 字面量、禁止带 color:/fontSize: 的裸
/// `TextStyle(`。`design_tokens.dart` 自身豁免（它就是唯一来源）。
///
/// 白名单机制：现状代码审计为零违规，白名单为空。若历史遗留需要豁免，
/// 在 [kWhitelist] 登记文件名 + 原因；白名单**只减不增**，清零是
/// tasks.md T031 的完成条件。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 豁免清单：'文件相对路径': '豁免原因（必填）'。白名单**只减不增**。
/// 现状审计仅 1 个文件 3 处（fontSize 硬编码，颜色取自 theme），
/// 随 US3/T017 goals_view 重写消灭；全部清空是 T031 的完成条件。
const kWhitelist = <String, String>{
  'lib/features/goals/goals_view.dart': '3 处裸 TextStyle(fontSize 13/12 硬编码；US3 T017 整屏重写时消灭',
};

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

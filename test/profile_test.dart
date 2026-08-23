/// T018：账号资料——ProfileAvatar 同源渲染 + 编辑 sheet 往返持久化。
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart' show SettingsRepository;
import 'package:target/core/models/entities.dart' show Profile;
import 'package:target/features/profile/profile.dart';

/// 独立宿主：组件不依赖完整 App（TargetPalette 经 AppTheme 注入）。
Widget _host({Widget? child, VoidCallback? onOpen}) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(
    body: Center(
      child:
          child ?? FilledButton(onPressed: onOpen, child: const Text('open')),
    ),
  ),
);

Future<AppDatabase> _db({Profile? seed}) async {
  final db = AppDatabase(NativeDatabase.memory());
  if (seed != null) await SettingsRepository(db).updateProfile(seed);
  return db;
}

void main() {
  group('profileNicknameOf（FR-004 兜底）', () {
    test('未填/空白 → 默认「我」', () {
      expect(profileNicknameOf(null), Copy.profileDefaultNickname);
      expect(
        profileNicknameOf(const Profile(nickname: '  ')),
        Copy.profileDefaultNickname,
      );
    });

    test('有昵称 → 去首尾空白原值', () {
      expect(profileNicknameOf(const Profile(nickname: ' 小星 ')), '小星');
    });
  });

  testWidgets('ProfileAvatar 默认枚：渐变底 + 首字兜底「我」', (tester) async {
    await tester.pumpWidget(
      _host(child: const ProfileAvatar(profile: Profile.empty)),
    );
    expect(find.text(Copy.profileDefaultNickname), findsOneWidget);
  });

  testWidgets('ProfileAvatar 有昵称：首字取昵称', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const ProfileAvatar(profile: Profile(nickname: '阿星')),
      ),
    );
    expect(find.text('阿'), findsOneWidget);
  });

  testWidgets('ProfileAvatar 预设头像：环色底 + 图标，无首字', (tester) async {
    await tester.pumpWidget(
      _host(
        child: const ProfileAvatar(
          profile: Profile(avatarKey: 'favorite'),
          size: 56,
        ),
      ),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text(Copy.profileDefaultNickname), findsNothing);
  });

  testWidgets('sheet 冒烟：输入昵称 + 选头像 + 完成 → 落库往返', (tester) async {
    final db = await _db();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: _host(
          onOpen: () => showProfileSheet(tester.element(find.text('open'))),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.profileSheetTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField), '阿星');
    await tester.pump();
    // 输入框持有草稿（预览行已随 004 板 4 冻结稿退役）。
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '阿星',
    );

    await tester.tap(find.byKey(const ValueKey('avatarCell-favorite')));
    await tester.pump();
    await tester.tap(find.text(Copy.profileDone));
    await tester.pumpAndSettle();
    expect(find.text(Copy.profileSheetTitle), findsNothing); // 已收起

    final saved = await SettingsRepository(db).getProfile();
    expect(saved.nickname, '阿星');
    expect(saved.avatarKey, 'favorite');

    // 重开回显同源值。
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '阿星');
    await db.close();
  });

  testWidgets('sheet：再点选中格 = 回默认枚；空白昵称落 NULL', (tester) async {
    final db = await _db(
      seed: const Profile(nickname: '阿星', avatarKey: 'favorite'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: _host(
          onOpen: () => showProfileSheet(tester.element(find.text('open'))),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle(); // 异步回显完成
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '阿星'); // 旧值回显

    await tester.enterText(find.byType(TextField), '   '); // 清成空白
    await tester.pump();
    // 再点选中格 = 取消选中（回默认枚）。
    await tester.tap(find.byKey(const ValueKey('avatarCell-favorite')));
    await tester.pump();
    await tester.tap(find.text(Copy.profileDone));
    await tester.pumpAndSettle();

    final saved = await SettingsRepository(db).getProfile();
    expect(saved.nickname, isNull); // trim 后空 → 不落昵称
    expect(saved.avatarKey, isNull); // 回默认枚
    await db.close();
  });

  testWidgets('sheet：昵称上限 12 字', (tester) async {
    final db = await _db();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: _host(
          onOpen: () => showProfileSheet(tester.element(find.text('open'))),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '一二三四五六七八九十一百零一二');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 12);
    await db.close();
  });
}

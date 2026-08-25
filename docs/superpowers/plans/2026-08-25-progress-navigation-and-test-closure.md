# Target Progress, Navigation, and Core Flow Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the redundant Review tab with an objective Progress experience, tighten and unify navigation, clarify goal-detail recording history, ship the approved white app icon, and prove the app's core goal-management journeys end to end.

**Architecture:** Move the existing immutable progress read model out of Today into focused Progress widgets, keep Drift streams as the only refresh mechanism, and reuse the existing atomic progress command for every recording surface. Remove only active legacy review/health-score consumers while keeping dormant database and backup fields readable, then verify the product through real Router + Riverpod + Drift-memory application journeys.

**Tech Stack:** Flutter, Dart 3.13, Riverpod 2.6, Drift 2.34, go_router 17.5, flutter_test, flutter_launcher_icons 0.14.4.

**Spec:** `docs/superpowers/specs/2026-08-25-progress-navigation-and-test-closure-design.md`

## Global Constraints

- `/review` and `target://review` are deleted, not redirected.
- `/progress` and `target://progress` are the only second-tab routes.
- Today contains only the header, goal-status card, and focus carousel.
- Progress contains the real seven-day trend, three-part advice, and attention list; it persists no review result.
- Goal-detail recording continues to use `ProgressRepository.record`; backfill continues to use `CheckInService.backfill`.
- Root full-screen pages hide the dock and share one transition definition.
- Dock content height is 68dp; the system bottom inset is added outside that content geometry.
- Light, dark, and system themes use semantic tokens and 44×44dp minimum hit targets.
- The white app icon has no alpha and no baked rounded corners.
- Legacy WeeklyReview/Frequency/Busy tables and backup keys stay readable but have no active UI/runtime consumer.
- Every feature or bug fix starts with a failing test and ends with a focused commit.

---

## File Structure

**Create**

- `lib/features/progress/progress_view.dart` — Progress page composition and loading/empty states.
- `lib/features/progress/progress_trend_card.dart` — seven-day chart, current dimension values, and advice expansion.
- `lib/features/progress/attention_goal_list.dart` — objective attention cards and detail navigation callbacks.
- `lib/app/dock_glyphs.dart` — custom Target-ring and trend-line painters.
- `lib/features/goals/day_records_sheet.dart` — read-only records for an already-recorded calendar day.
- `design/brand/icon-progress-white.svg` — approved white Target trajectory vector source.
- `tool/brand_icon_golden_test.dart` — reproducible 1024px PNG renderer using Flutter's canvas.
- `test/progress_view_test.dart` — Progress component behavior.
- `test/navigation_redesign_test.dart` — dock geometry, route deletion, and shared full-screen transitions.
- `test/goal_detail_calendar_test.dart` — seven-day calendar and day actions.
- `test/app_journeys_test.dart` — four real application journeys.
- `test/app_icon_asset_test.dart` — app-icon dimensions and opacity contract.

**Modify**

- `lib/features/today/today_view.dart` — remove trend/advice/attention widgets and imports.
- `lib/app/router.dart` — Progress branch, root GoalsAll, shared transition, compact dock, new glyphs/deep link.
- `lib/app/app.dart` — remove weekly settlement and Busy Mode startup work.
- `lib/app/providers.dart` — remove old health/review/settlement/busy runtime providers.
- `lib/core/copy.dart` — replace review copy with progress and calendar copy.
- `lib/features/goals/goal_detail.dart` — redesigned single recording/calendar card.
- `lib/features/settings/reminder_service.dart` — remove Monday review copy.
- `lib/core/stats/stats_engine.dart` — remove review-only derived view types/methods.
- `pubspec.yaml` — new icon source and Android adaptive icon generation.
- `test/today_redesign_test.dart` — Today-only layout contract.
- `test/widget_test.dart` — Progress branch and live score-refresh flow.
- `test/stats_engine_test.dart` — retain core statistics, remove Review-only assertions.
- `test/reminder_service_test.dart` — daily brief no longer mentions Review.
- `test/frequency_version_test.dart` — reduce to dormant legacy-read guarantees and move active-goal cap assertion.
- `test/backup_test.dart` — keep legacy backup readability without active Review behavior.

**Delete**

- `lib/features/review/review_view.dart`
- `lib/core/models/health_score.dart`
- `lib/core/stats/settlement_service.dart`
- `lib/core/stats/busy_mode_service.dart`
- `test/health_score_test.dart`
- `test/settlement_test.dart`

---

### Task 1: Move Progress and Attention Out of Today

**Files:**
- Create: `lib/features/progress/progress_view.dart`
- Create: `lib/features/progress/progress_trend_card.dart`
- Create: `lib/features/progress/attention_goal_list.dart`
- Create: `test/progress_view_test.dart`
- Modify: `lib/features/today/today_view.dart`
- Modify: `test/today_redesign_test.dart`

**Interfaces:**
- Consumes: `GoalProgressSnapshot`, `GoalProgressEvaluation`, `GoalAdvice`, `List<Goal>`, `goalProgressProvider`, `goalsProvider`.
- Produces: `const ProgressView()`, `ProgressTrendCard({required GoalProgressSnapshot snapshot})`, `AttentionGoalList({required GoalProgressEvaluation evaluation, required List<Goal> goals, required ValueChanged<Goal> onOpen})`.

- [ ] **Step 1: Write failing Progress page tests**

Add tests that pump `ProgressView` with a real in-memory database and assert the migrated sections exist:

```dart
testWidgets('progress owns trend advice and attention', (tester) async {
  final db = await pumpProgress(tester, seed: seedPlannedGoal);
  addTearDown(db.close);
  expect(find.byKey(const ValueKey('progressTrendCard')), findsOneWidget);
  expect(find.text('近 7 天'), findsOneWidget);
  expect(find.text('需要关注'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('adviceToggle-goal')));
  await tester.pumpAndSettle();
  expect(find.textContaining('指标原理'), findsOneWidget);
});

testWidgets('progress shows honest empty states', (tester) async {
  final db = await pumpProgress(tester);
  addTearDown(db.close);
  expect(find.byKey(const ValueKey('progressNoTrend')), findsOneWidget);
  expect(find.text('当前没有需要优先处理的计划。'), findsOneWidget);
});
```

- [ ] **Step 2: Rewrite the Today layout contract to fail**

Change `today_redesign_test.dart` so it requires the status and focus sections but rejects migrated content:

```dart
expect(find.byKey(const ValueKey('goalStatusCard')), findsOneWidget);
expect(find.text('关注'), findsOneWidget);
expect(find.byKey(const ValueKey('progressTrendCard')), findsNothing);
expect(find.text('需要关注'), findsNothing);
```

- [ ] **Step 3: Run focused tests and confirm failure**

Run: `flutter test test/progress_view_test.dart test/today_redesign_test.dart`

Expected: ProgressView imports/keys are missing and Today still renders trend/attention.

- [ ] **Step 4: Extract the trend/advice widget**

Move the current `_ProgressCard`, `_TrendPainter`, and `_AdviceBlock` behavior into `ProgressTrendCard`. Preserve `snapshot.evaluation.dailyPoints` as the x-axis source and `snapshot.advice[dimension]` as the only copy source. Add semantic buttons keyed `adviceToggle-${dimension.name}` and a `progressNoTrend` state when every point lacks dimensions.

- [ ] **Step 5: Extract the attention list**

Move `_AttentionSection`, `_AttentionCard`, and `_AttentionEmpty` into `AttentionGoalList`. Preserve real icons via `GoalIconCatalog.byKey(goal.iconKey)` and the evaluation's pre-sorted attention order. Do not recompute reasons in widgets.

- [ ] **Step 6: Compose Progress and simplify Today**

Build `ProgressView` from the two extracted components and remove their slivers from Today. Keep Today loading until goals, steps, stats, and `goalProgressProvider` are ready because the status card and carousel still consume them.

- [ ] **Step 7: Run focused tests and analyzer**

Run: `flutter test test/progress_view_test.dart test/today_redesign_test.dart`

Run: `flutter analyze lib/features/progress lib/features/today`

Expected: all tests pass and no diagnostics.

- [ ] **Step 8: Commit**

```bash
git add lib/features/progress lib/features/today/today_view.dart test/progress_view_test.dart test/today_redesign_test.dart
git commit -m "feat: separate today actions from progress insights"
```

### Task 2: Replace Review Routing and Unify Navigation

**Files:**
- Create: `lib/app/dock_glyphs.dart`
- Create: `test/navigation_redesign_test.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/core/copy.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `ProgressView`, `TodayView`, `ProfileHubPage`, `GoalsAllPage`, `StatefulNavigationShell`.
- Produces: `CustomTransitionPage<void> buildRootPushPage(GoRouterState state, Widget child)`, `TargetRingGlyphPainter`, `ProgressTrendGlyphPainter`, `mapDeepLink(target://progress) == '/progress'`.

- [ ] **Step 1: Write failing route and deep-link tests**

```dart
test('deep links recognize progress and reject review', () {
  expect(mapDeepLink(Uri.parse('target://progress')), '/progress');
  expect(mapDeepLink(Uri.parse('target://review')), isNull);
});

testWidgets('dock contains today and progress only', (tester) async {
  final db = await pumpTarget(tester);
  addTearDown(db.close);
  expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
  expect(find.byKey(const ValueKey('navTab-/progress')), findsOneWidget);
  expect(find.byKey(const ValueKey('navTab-/review')), findsNothing);
});
```

- [ ] **Step 2: Write failing compact-dock and shared-transition tests**

```dart
final dockBar = tester.getRect(find.byKey(const ValueKey('dockBar')));
expect(dockBar.height, 68 + tester.view.padding.bottom / tester.view.devicePixelRatio);

await tester.tap(find.text('查看全部'));
await tester.pump(const Duration(milliseconds: 80));
final allOffset = tester.getTopLeft(find.byKey(const ValueKey('goalsAllPage')));
expect(allOffset.dx, greaterThan(0));
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('dockBar')), findsNothing);
```

Repeat the same 80ms offset assertion for the Profile page and require equal x offsets within 0.5 logical pixels.

- [ ] **Step 3: Run navigation tests and confirm failure**

Run: `flutter test test/navigation_redesign_test.dart test/widget_test.dart`

Expected: `/progress`, new glyphs, 68dp geometry, and root GoalsAll transition do not exist.

- [ ] **Step 4: Implement custom glyph painters**

Create two painters in `dock_glyphs.dart`:

```dart
class TargetRingGlyphPainter extends CustomPainter {
  const TargetRingGlyphPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * .09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .32;
    canvas.drawCircle(center, radius, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    canvas.drawCircle(Offset(center.dx + radius, center.dy), stroke * .9,
        Paint()..color = color);
  }
  @override
  bool shouldRepaint(TargetRingGlyphPainter old) => old.color != color;
}
```

Implement `ProgressTrendGlyphPainter` as one rounded polyline plus one point, using the same 24px square and color contract.

- [ ] **Step 5: Implement canonical Progress routing**

Delete the Review branch and add `GoRoute(path: '/progress', builder: (_, _) => const ProgressView())`. Replace Copy.reviewNav with `Copy.progressNav = '进展'`. Update `mapDeepLink` to recognize only `progress`.

- [ ] **Step 6: Move GoalsAll to the root navigator and share transitions**

Define `buildRootPushPage` once with `AppMotion.base`, `AppMotion.easeStandard`, a right-to-left slide from `Offset(.08, 0)`, and a `0 → 1` fade. Use it in pageBuilder routes for `/profile`, `/goals-all`, and `/settings`; remove `/goals-all` from the Today branch.

- [ ] **Step 7: Tighten dock geometry**

Set `_barHeight = 68`, keep `_fabOverhang = 22`, add `bottomInset` only to the outer size/bar background, and align the icon column so the selected underline ends within the 68dp content area.

- [ ] **Step 8: Run navigation tests and analyzer**

Run: `flutter test test/navigation_redesign_test.dart test/widget_test.dart`

Run: `flutter analyze lib/app`

Expected: all tests pass and both full-screen pushes share identical intermediate offsets.

- [ ] **Step 9: Commit**

```bash
git add lib/app/router.dart lib/app/dock_glyphs.dart lib/core/copy.dart test/navigation_redesign_test.dart test/widget_test.dart
git commit -m "feat: replace review navigation with progress"
```

### Task 3: Redesign Goal-Detail Recording Calendar

**Files:**
- Create: `lib/features/goals/day_records_sheet.dart`
- Create: `test/goal_detail_calendar_test.dart`
- Modify: `lib/features/goals/goal_detail.dart`
- Modify: `lib/core/copy.dart`
- Modify: `test/progress_record_sheet_test.dart`

**Interfaces:**
- Consumes: `List<CheckIn> mine`, `LocalDate today`, `CheckInService.backfill`, `showProgressRecordSheet`.
- Produces: keyed day cells `detailDay-YYYY-MM-DD`, `showDayRecordsSheet(BuildContext, {required LocalDate day, required List<CheckIn> records})`.

- [ ] **Step 1: Write failing calendar semantics tests**

```dart
testWidgets('detail card exposes a recognizable seven-day calendar', (tester) async {
  final db = await pumpGoalDetail(tester, recordedDays: [today.addDays(-2)]);
  addTearDown(db.close);
  expect(find.text('今日进展'), findsOneWidget);
  expect(find.text('最近 7 天'), findsOneWidget);
  expect(find.text('已记录'), findsOneWidget);
  expect(find.text('可补记'), findsOneWidget);
  expect(find.byKey(ValueKey('detailDay-${today.isoString}')), findsOneWidget);
  expect(find.byKey(ValueKey('detailDay-${today.addDays(-2).isoString}')), findsOneWidget);
});
```

- [ ] **Step 2: Write failing day-action tests**

```dart
await tester.tap(find.byKey(ValueKey('detailDay-${today.addDays(-1).isoString}')));
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('backfillSheet')), findsOneWidget);

await closeSheet(tester);
await tester.tap(find.byKey(ValueKey('detailDay-${today.addDays(-2).isoString}')));
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('dayRecordsSheet')), findsOneWidget);
expect(find.text('已完成理论复习'), findsOneWidget);
```

Add an invalid-goal route case and a failed-save retention case:

```dart
await router.push('/goal/missing');
await tester.pumpAndSettle();
expect(find.byType(TodayView), findsOneWidget);
expect(find.text('目标不存在或已删除'), findsOneWidget);

await tester.tap(find.text('保存进展')); // currentStep id is absent in DB
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('progressSaveError')), findsOneWidget);
expect(find.text('不会丢失的输入'), findsOneWidget);
```

- [ ] **Step 3: Run the calendar tests and confirm failure**

Run: `flutter test test/goal_detail_calendar_test.dart`

Expected: labels, stable day keys, and recorded-day sheet are missing.

- [ ] **Step 4: Rebuild the single card hierarchy**

Keep one surface card. Render the current milestone inset and primary record button first, then a divider, a `最近 7 天` header with a real date range, the seven weekday/date cells, and the text legend. Use `Semantics(label: '星期一，8月24日，已记录')` style labels rather than color-only status.

- [ ] **Step 5: Implement recorded-day and empty-day actions**

When a past day has valid records, open `DayRecordsSheet` with notes and backfill tags. When it has no valid record, open the existing BackfillSheet with that day selected. Today does not open backfill and remains tied to the main record button.

When the goal stream resolves without the requested id, schedule `context.go('/today')` after the current frame and show `Copy.goalMissing` through the root ScaffoldMessenger. Do not leave the loading indicator active indefinitely. Keep the progress sheet open on repository failure, set `progressSaveError`, and never clear its text controllers until a successful save.

- [ ] **Step 6: Wire View Calendar to the existing full-month sheet**

The keyed `detailOpenCalendar` button calls `_openBackfill()` with no initial day. It keeps the existing six-month window and prevents duplicate records on already-recorded dates.

- [ ] **Step 7: Run calendar and recording regression tests**

Run: `flutter test test/goal_detail_calendar_test.dart test/progress_record_sheet_test.dart test/progress_record_test.dart`

Run: `flutter analyze lib/features/goals`

Expected: all pass and no diagnostics.

- [ ] **Step 8: Commit**

```bash
git add lib/features/goals/goal_detail.dart lib/features/goals/day_records_sheet.dart lib/core/copy.dart test/goal_detail_calendar_test.dart
git commit -m "feat: clarify goal detail recording calendar"
```

### Task 4: Remove Active Legacy Review and Health-Score Runtime

**Files:**
- Delete: `lib/features/review/review_view.dart`
- Delete: `lib/core/models/health_score.dart`
- Delete: `lib/core/stats/settlement_service.dart`
- Delete: `lib/core/stats/busy_mode_service.dart`
- Delete: `test/health_score_test.dart`
- Delete: `test/settlement_test.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/providers.dart`
- Modify: `lib/core/stats/stats_engine.dart`
- Modify: `lib/features/settings/reminder_service.dart`
- Modify: `lib/features/settings/debug_clock.dart`
- Modify: `test/stats_engine_test.dart`
- Modify: `test/reminder_service_test.dart`
- Modify: `test/frequency_version_test.dart`

**Interfaces:**
- Preserves: Drift WeeklyReviews/FrequencyVersions/BusyMode tables, repositories required by backup import/export, and JSON keys.
- Removes: `healthScoreProvider`, `reviewsProvider`, `settlementServiceProvider`, `busyModeServiceProvider`, `versionsProvider`, `busySessionsProvider`, review-only StatsEvaluation methods.

- [ ] **Step 1: Add a failing runtime-leak contract test**

Extend a design contract test to scan `lib/` and reject active legacy identifiers outside database/backup compatibility paths:

```dart
expect(runtimeSources, isNot(contains('healthScoreProvider')));
expect(runtimeSources, isNot(contains('settlementServiceProvider')));
expect(runtimeSources, isNot(contains("path: '/review'")));
expect(runtimeSources, isNot(contains('dailyBriefReviewLine')));
```

- [ ] **Step 2: Run the contract and confirm failure**

Run: `flutter test test/design/token_contract_test.dart`

Expected: current providers, route copy, and reminder text violate the contract.

- [ ] **Step 3: Remove app-start side effects and unused providers**

Delete weekly settlement and Busy Mode resume work from `app.dart`. Remove the associated providers/imports from `providers.dart`. Build `statsProvider` from goals and check-ins without loading Busy sessions; preserved old rows do not influence current UI.

- [ ] **Step 4: Remove the obsolete score model**

Delete `health_score.dart`, `healthScoreProvider`, and all imports. Keep `goalProgressProvider` as the only status/score read model.

- [ ] **Step 5: Remove review-only statistics**

Delete `GoalWeekRate`, `WeekOverview`, `DayActivity`, `DayFill`, and the methods `weekRateOf`, `weekOverview`, and `dayActivities`. Keep natural-day status, streak, backfill, revoked-record, week trace totals, and widget snapshot inputs.

- [ ] **Step 6: Remove Review reminder language**

Make daily brief content identical on Monday and other days. Delete Copy.dailyBriefReviewLine and reminderMondayHint and remove the debug-clock Review note.

- [ ] **Step 7: Trim legacy tests**

Delete `health_score_test.dart` and `settlement_test.dart`. Remove Review-only stats cases beginning with the `周视图派生` group. In `frequency_version_test.dart`, retain only old-row readability, check-in backfill invariants, and active-goal cap coverage; no Busy Mode business behavior remains.

- [ ] **Step 8: Run focused legacy-boundary tests**

Run: `flutter test test/design/token_contract_test.dart test/stats_engine_test.dart test/frequency_version_test.dart test/backup_test.dart test/migration_test.dart test/reminder_service_test.dart`

Expected: preserved storage compatibility passes while no runtime legacy identifier remains.

- [ ] **Step 9: Commit**

```bash
git add -A lib test
git commit -m "refactor: remove active review and legacy scoring runtime"
```

### Task 5: Generate the White Target-Trajectory App Icon

**Files:**
- Create: `design/brand/icon-progress-white.svg`
- Create: `design/brand/icon-progress-foreground-1024.png`
- Create: `tool/brand_icon_golden_test.dart`
- Create: `test/app_icon_asset_test.dart`
- Modify: `pubspec.yaml`
- Regenerate: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- Regenerate: `android/app/src/main/res/mipmap-*/*`

**Interfaces:**
- Produces: 1024×1024 opaque PNG at `design/brand/icon-progress-white-1024.png`, transparent adaptive foreground at `design/brand/icon-progress-foreground-1024.png`, iOS AppIcon set, Android launcher/adaptive icon resources.

- [ ] **Step 1: Write the failing asset contract**

```dart
test('marketing icon is 1024 square and fully opaque', () async {
  final bytes = await File('design/brand/icon-progress-white-1024.png').readAsBytes();
  final decoded = img.decodePng(bytes)!;
  expect((decoded.width, decoded.height), (1024, 1024));
  for (final pixel in decoded) {
    expect(pixel.a, 255);
  }
});
```

Declare `image: ^4.9.2` as a dev dependency for this contract. Also assert `pubspec.yaml` references the new path and Android launcher files exist.

- [ ] **Step 2: Run the asset contract and confirm failure**

Run: `flutter test test/app_icon_asset_test.dart`

Expected: the new SVG/PNG/config/resources do not exist.

- [ ] **Step 3: Create the vector source**

Write a 1024 SVG with full white background, cubic blue path from lower-left to upper-right, graphite start circle, and green terminal circle. Keep all geometry inside a 160px safe margin and do not add a rounded-square mask.

- [ ] **Step 4: Create a reproducible Flutter golden renderer**

In `tool/brand_icon_golden_test.dart`, render the same normalized cubic path on a 1024×1024 white `CustomPaint`, set devicePixelRatio to 1, and use `matchesGoldenFile('../design/brand/icon-progress-white-1024.png')`. Add a second golden with a transparent background and only the safe-zone path/start/end artwork for Android adaptive foreground.

- [ ] **Step 5: Generate the 1024 PNG**

Run: `flutter test tool/brand_icon_golden_test.dart --update-goldens`

Expected: the marketing PNG is fully opaque, the adaptive foreground is transparent outside the mark, and both match the approved C geometry.

- [ ] **Step 6: Configure iOS and Android launchers**

Set `flutter_launcher_icons.image_path` to the opaque PNG, enable `android: true`, add `adaptive_icon_background: '#FFFFFF'`, and set `adaptive_icon_foreground` to the transparent foreground PNG. Remove `AppIconDark.png` and its manually maintained Contents entry because the white icon is intentionally identical in both appearances.

- [ ] **Step 7: Regenerate platform assets**

Run: `dart run flutter_launcher_icons`

Expected: iOS and Android launcher resources are regenerated successfully.

- [ ] **Step 8: Run asset tests and inspect representative files**

Run: `flutter test test/app_icon_asset_test.dart`

Inspect: 1024px source, iOS 180px icon, Android xxxhdpi icon, and 29px icon against white and dark backgrounds.

- [ ] **Step 9: Commit**

```bash
git add design/brand tool/brand_icon_golden_test.dart pubspec.yaml ios/Runner/Assets.xcassets/AppIcon.appiconset android/app/src/main/res test/app_icon_asset_test.dart
git commit -m "feat: ship white target trajectory app icon"
```

### Task 6: Prove and Complete the Four Core Application Journeys

**Files:**
- Create: `test/app_journeys_test.dart`
- Modify: `test/goal_editor_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `lib/features/goals/goal_editor.dart`
- Modify: `lib/features/goals/goals_all_view.dart`
- Modify: `lib/features/goals/goal_detail.dart`
- Modify: `lib/features/goals/goal_lifecycle.dart`
- Modify: `lib/features/progress/progress_view.dart`

**Interfaces:**
- Consumes: real `routerProvider`, `dbProvider`, `FixedDateProvider`, repositories, and platform gateway fakes only.
- Produces: four independent application journeys with one fresh in-memory Drift database each.

- [ ] **Step 1: Add the three-type creation journey**

Create long, short, and habit goals through the editor UI. Assert `targetDate/progressCadenceDays`, `deadline/progressCadenceDays`, and `habitTargetPerWeek` respectively, then open GoalsAll and assert all names appear.

```dart
expect(savedLong.progressCadenceDays, 14);
expect(savedShort.progressCadenceDays, 7);
expect(savedHabit.habitTargetPerWeek, 5);
```

- [ ] **Step 2: Add the progression and live-score journey**

Seed a stale goal with one current milestone. Capture its pre-record score from `goalProgressProvider`, record progress through the focus card, complete the milestone, add the next step, switch to `/progress`, and assert the score increased, the latest trend value changed, and needs-planning is absent.

```dart
final before = container.read(goalProgressProvider)!.evaluation.byGoal['g']!.total;
// interact through UI
final after = container.read(goalProgressProvider)!.evaluation.byGoal['g']!.total;
expect(after, greaterThan(before));
expect(find.text('确认一个可以开始的下一步'), findsNothing);
```

- [ ] **Step 3: Add the date-backfill journey**

Open GoalDetail, tap yesterday's empty calendar cell, confirm backfill, and assert the cell changes to recorded, history contains the backfill tag, CheckIn.isBackfill is true, and the current score refreshes.

- [ ] **Step 4: Add the management journey**

Open GoalsAll, edit the goal name, pause it, resume it, mark a short goal achieved, and delete another goal after confirmation. Assert Today, Progress, GoalsAll, and repository state all converge after each action.

- [ ] **Step 5: Run journeys and verify the missing UI contracts fail**

Run: `flutter test test/app_journeys_test.dart`

Expected: stable GoalsAll management keys and post-delete/post-achieve navigation are absent or inconsistent, so the management journey fails at those assertions.

- [ ] **Step 6: Implement stable management and navigation contracts**

Key every GoalsAll card as `goalCard-${goal.id}` and its edit/pause/resume/delete actions as `goalAction-${action.name}-${goal.id}`. Await every repository mutation. After a detail-page delete or achieve, use the canonical route rather than a local pop:

```dart
await ref.read(goalRepoProvider).deleteGoal(goal.id);
if (context.mounted) context.go('/today');
```

Keep GoalsAll on screen after pause/resume and let its Drift stream redraw the status badge. Ensure editor saves type-specific values from the active draft only, and add `ValueKey('progressPage')` so the progression journey can prove the final route.

- [ ] **Step 7: Run journeys, focused domain tests, and analyzer**

Run: `flutter test test/app_journeys_test.dart test/goal_editor_test.dart test/progress_record_test.dart test/goal_progress_test.dart test/goal_progress_provider_test.dart`

Run: `flutter analyze lib/features lib/app`

Expected: all pass and no diagnostics.

- [ ] **Step 8: Commit**

```bash
git add lib test/app_journeys_test.dart test/goal_editor_test.dart test/widget_test.dart
git commit -m "test: verify complete goal management journeys"
```

### Task 7: Accessibility, Theme Matrix, and Final Regression

**Files:**
- Modify: `test/progress_view_test.dart`
- Modify: `test/navigation_redesign_test.dart`
- Modify: `test/goal_detail_calendar_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `docs/superpowers/specs/2026-08-25-progress-navigation-and-test-closure-design.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: one clean, analyzed, fully tested, release-buildable branch and an implementation-complete spec status.

- [ ] **Step 1: Add the width and theme matrix**

Pump Today, Progress, and GoalDetail at 320, 375, and 430 logical pixels in both light and dark themes. Scroll every page and assert `tester.takeException()` is null.

- [ ] **Step 2: Add accessibility assertions**

Use `tester.ensureSemantics()` and assert meaningful labels for the two dock icons, advice buttons, seven date cells, View Calendar, profile, and GoalsAll. Assert measured hit rectangles are at least 44×44dp.

- [ ] **Step 3: Run formatting**

Run: `dart format lib test tool`

Expected: formatter exits 0.

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze`

Expected: no issues found.

- [ ] **Step 5: Run the complete test suite**

Run: `flutter test`

Expected: all retained and newly added tests pass; the count may be below the old 162 because legacy tests are intentionally removed.

- [ ] **Step 6: Build the release web app**

Run: `flutter build web --release`

Expected: `build/web` is produced successfully.

- [ ] **Step 7: Inspect stale identifiers and final diff**

Run: `rg -n "ReviewView|healthScoreProvider|evaluateHealth|settlementServiceProvider|dailyBriefReviewLine|path: '/review'" lib test`

Expected: no matches outside explicit migration/backup compatibility comments.

Run: `git diff --check`

Expected: no whitespace errors.

- [ ] **Step 8: Mark the spec implemented and commit**

Change the spec status to `已实现并验证`, append the final retained/new test count and platform verification evidence, then commit:

```bash
git add lib test tool design pubspec.yaml ios android docs/superpowers/specs/2026-08-25-progress-navigation-and-test-closure-design.md
git commit -m "test: close progress navigation regression matrix"
```

- [ ] **Step 9: Verify clean worktree and reviewable history**

Run: `git status --short`

Run: `git log --oneline --max-count=10`

Expected: clean worktree and one focused commit per task.

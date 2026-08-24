# Target UI and Goal Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Target home, profile/settings, goal creation, progress scoring, and next-step flow with the approved light-first goal-management experience.

**Architecture:** Extend the existing pure Dart domain model and Drift schema first, then expose one Riverpod read model for status, trend, and attention. Keep scoring, icon classification, and advice outside widgets; split the large Today and editor widgets into focused components that consume immutable view data.

**Tech Stack:** Flutter, Dart 3.13, Riverpod 2.6, Drift 2.34, go_router 17.5, flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-25-target-ui-goal-management-design.md`

## Global Constraints

- Light mode is the primary acceptance baseline; dark and system modes must remain complete.
- Short-term goals require a deadline and default to a 7-day progress cadence.
- Long-term goals use an optional target date and default to a 14-day progress cadence.
- Habits require a weekly frequency and default to no end date.
- The first milestone or first action is optional and derives an attention state when absent.
- Scoring uses only objective goal data and must not infer mood, health diagnoses, workload, or causality.
- Health, habit, and goal dimensions are independent views and are never summed.
- Existing backups, migrations, reminders, widgets, and deep links must remain readable.
- Do not add network image or icon dependencies; use the existing Material icon catalog.
- Every interactive control must provide at least a 44×44dp hit target and a semantic label.

---

### Task 1: Persist cadence, category override, long-term target date, habit frequency, and milestone order

**Files:**
- Modify: `lib/core/models/entities.dart`
- Modify: `lib/core/models/goal_icon_catalog.dart`
- Modify: `lib/core/db/tables.dart`
- Modify: `lib/core/db/app_database.dart`
- Modify: `lib/core/db/repositories.dart`
- Modify: `lib/core/backup/backup_exporter.dart`
- Modify: `lib/core/backup/backup_importer.dart`
- Regenerate: `lib/core/db/app_database.g.dart`
- Test: `test/goal_progress_model_test.dart`
- Test: `test/migration_test.dart`
- Test: `test/backup_test.dart`

**Interfaces:**
- Produces: `Goal.progressCadenceDays`, `Goal.categoryOverride`, `Goal.targetDate`, `Goal.habitTargetPerWeek`, `Goal.effectiveDomain`, `MilestoneStep.position`.
- Produces: `Settings.defaultShortCadenceDays`, `Settings.defaultLongCadenceDays`, `Settings.scoreAlgorithmStartedOn`.
- Consumes: existing `GoalType`, `GoalIconDomain`, `LocalDate`, and Drift repository mappings.

- [ ] **Step 1: Write failing model tests**

```dart
test('goal defaults follow type and category override wins', () {
  final short = Goal(
    name: 'OW',
    goalType: GoalType.shortTerm,
    iconKey: GoalIconCatalog.pool.key,
    colorKey: '',
    createdAt: const LocalDate(2026, 8, 25),
    deadline: const LocalDate(2026, 10, 2),
  );
  expect(short.progressCadenceDays, 7);
  expect(short.effectiveDomain, GoalIconDomain.fitness);
  expect(short.copyWith(categoryOverride: GoalIconDomain.travel).effectiveDomain,
      GoalIconDomain.travel);
});

test('milestones retain stable manual order', () {
  final step = MilestoneStep(goalId: 'g', title: 'DSD', position: 20);
  expect(step.position, 20);
});
```

- [ ] **Step 2: Run the model tests and confirm the new properties are missing**

Run: `flutter test test/goal_progress_model_test.dart`

Expected: compile failure for `progressCadenceDays`, `categoryOverride`, or `position`.

- [ ] **Step 3: Extend the pure domain entities**

Add nullable constructor inputs with deterministic defaults:

```dart
final int progressCadenceDays;
final GoalIconDomain? categoryOverride;
final LocalDate? targetDate;
final int? habitTargetPerWeek;

GoalIconDomain get effectiveDomain =>
    categoryOverride ?? GoalIconCatalog.byKey(iconKey).domain;

static int defaultCadenceFor(GoalType type) =>
    type == GoalType.longTerm ? 14 : 7;
```

Allow `targetDate` only for long-term goals, `deadline` only for short-term goals, and `habitTargetPerWeek` only for habits with range 1–7. Add `position` to `MilestoneStep`, preserve it in `toggled`, equality, hash code, and repository mapping.

- [ ] **Step 4: Write the schema-v6 migration test**

Extend the existing migration fixture to open a v5 database and assert:

```dart
expect(db.schemaVersion, 6);
expect(migratedShort.progressCadenceDays, 7);
expect(migratedLong.progressCadenceDays, 14);
expect(migratedHabit.habitTargetPerWeek, isNotNull);
expect((await repo.stepsOf(goalId)).single.position, 0);
```

- [ ] **Step 5: Add Drift columns and migration**

Add nullable storage columns so old rows migrate safely:

```dart
IntColumn get progressCadenceDays => integer().nullable()();
TextColumn get categoryOverride => text().nullable()();
TextColumn get targetDate => text().nullable().map(const LocalDateText())();
IntColumn get habitTargetPerWeek => integer().nullable()();
IntColumn get position => integer().withDefault(const Constant(0))();
```

Add settings defaults and algorithm start date. In `_migrateV6`, backfill 7/14-day cadence by goal type, derive habit weekly targets from the latest legacy frequency version when possible and otherwise use 5, and assign existing milestones positions in stable row order.

- [ ] **Step 6: Update repositories and backup mapping**

Map every new field in both directions. Export optional keys and accept missing keys during import. Sort `watchStepsOf` and `stepsOf` by `position`, then `id` for deterministic ties.

- [ ] **Step 7: Regenerate Drift code and run focused tests**

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `flutter test test/goal_progress_model_test.dart test/migration_test.dart test/backup_test.dart`

Expected: all pass.

- [ ] **Step 8: Commit the domain migration**

```bash
git add lib/core/models lib/core/db lib/core/backup test/goal_progress_model_test.dart test/migration_test.dart test/backup_test.dart
git commit -m "feat: persist goal progress planning fields"
```

### Task 2: Replace the seven-day penalty with explainable progress scoring

**Files:**
- Create: `lib/core/models/goal_progress.dart`
- Create: `lib/core/models/goal_advice.dart`
- Modify: `lib/app/providers.dart`
- Replace tests: `test/health_score_test.dart`
- Create: `test/goal_progress_test.dart`
- Create: `test/goal_advice_test.dart`

**Interfaces:**
- Produces: `GoalProgressEvaluation evaluateGoalProgress({required List<Goal> goals, required List<CheckIn> checkIns, required Map<String, List<MilestoneStep>> milestones, required LocalDate today})`.
- Produces: `goalProgressProvider`, returning current dimension scores, seven daily points, per-goal scores, attention items, and advice.
- Consumes: Task 1 fields and existing `goalsProvider`, `checkInsProvider`, `stepsProvider` repository data.

- [ ] **Step 1: Write failing score tests for every threshold**

```dart
test('short-term score uses 40/30/30 weights', () {
  final result = evaluateGoalProgress(
    goals: [shortGoal(cadence: 7, deadlineDays: 10)],
    checkIns: [checkIn(daysAgo: 8)],
    milestones: {'g': [openStep('next')]},
    today: today,
  );
  final score = result.byGoal['g']!;
  expect(score.momentum, 70);
  expect(score.clarity, 100);
  expect(score.deadlineBuffer, 70);
  expect(score.total, 79);
});

test('missing next step has clarity 40 and becomes attention', () {
  final result = evaluateGoalProgress(
    goals: [longGoal(cadence: 14)],
    checkIns: const [],
    milestones: const {'g': []},
    today: today,
  );
  expect(result.byGoal['g']!.clarity, 40);
  expect(result.attention.single.reason, AttentionReason.needsPlanning);
});
```

Cover new-goal grace, cadence thresholds 100/70/40/0, deadline buffer 100/70/40/0, habit weekly completion, empty dimensions, archived goals, and revoked check-ins.

- [ ] **Step 2: Run score tests and verify failure**

Run: `flutter test test/goal_progress_test.dart`

Expected: compile failure because `evaluateGoalProgress` does not exist.

- [ ] **Step 3: Implement immutable score and attention types**

Define:

```dart
enum ProgressDimension { health, habit, goal }
enum ScoreBand { stable, calibrate, adjust, replan }
enum ScoreDriver { momentum, clarity, deadlineBuffer, frequency }
enum AttentionReason { needsPlanning, rhythmInterrupted, deadlineNear }

class GoalScore {
  const GoalScore({required this.goalId, required this.total,
    required this.momentum, required this.clarity,
    this.deadlineBuffer, this.frequency});
  // fields
}
```

Implement pure helpers for cadence, clarity, deadline buffer, habit completion, equal-weight dimension aggregation, and seven real-date evaluations. Exclude inactive goals and return `null` for dimensions without data.

- [ ] **Step 4: Add advice selection tests**

```dart
test('advice chooses the largest objective loss driver', () {
  final advice = buildDimensionAdvice(
    dimension: ProgressDimension.goal,
    band: ScoreBand.calibrate,
    facts: const ProgressFacts(overdueCadence: 1, missingNextStep: 2),
  );
  expect(advice.driver, ScoreDriver.clarity);
  expect(advice.principle, isNotEmpty);
  expect(advice.currentInterpretation, contains('2 个'));
  expect(advice.action, contains('下一步'));
});
```

- [ ] **Step 5: Implement deterministic advice content**

`GoalAdvice` must contain `principle`, `currentInterpretation`, and `action`. Build copy from score band and the largest objective loss driver. Do not include mood, workload, medical, or causal language.

- [ ] **Step 6: Expose one provider read model**

Add a repository stream for all milestones rather than watching a provider family in a loop. Build `goalProgressProvider` only when goals, check-ins, and steps are all loaded. Keep `healthScoreProvider` as a deprecated alias during UI migration, then remove it with its old tests after all consumers switch.

- [ ] **Step 7: Run focused tests and analyzer**

Run: `flutter test test/goal_progress_test.dart test/goal_advice_test.dart`

Run: `flutter analyze lib/core/models lib/app/providers.dart`

Expected: all pass, no analyzer diagnostics.

- [ ] **Step 8: Commit scoring**

```bash
git add lib/core/models/goal_progress.dart lib/core/models/goal_advice.dart lib/app/providers.dart lib/core/db/repositories.dart test/goal_progress_test.dart test/goal_advice_test.dart test/health_score_test.dart
git commit -m "feat: add explainable goal progress scoring"
```

### Task 3: Add atomic progress recording and next-step planning

**Files:**
- Create: `lib/core/db/progress_repository.dart`
- Create: `lib/core/models/progress_record.dart`
- Modify: `lib/app/providers.dart`
- Create: `lib/features/goals/progress_record_sheet.dart`
- Modify: `lib/features/goals/goal_detail.dart`
- Test: `test/progress_record_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `Future<void> ProgressRepository.record(ProgressRecordInput input)`.
- Produces: `Future<bool?> showProgressRecordSheet(BuildContext context, {required Goal goal, required MilestoneStep? currentStep})`.
- Consumes: goal, check-in, milestone, and repository types from Tasks 1–2.

- [ ] **Step 1: Write failing transaction tests**

```dart
test('record can check in, complete current milestone and add next step', () async {
  await progressRepo.record(ProgressRecordInput(
    goalId: 'g',
    day: today,
    createdAt: now,
    note: '完成 DSD',
    completedMilestoneId: 'm1',
    nextMilestoneTitle: '完成理论课程',
  ));
  expect((await checkRepo.all()).single.note, '完成 DSD');
  final steps = await goalRepo.stepsOf('g');
  expect(steps.first.isDone, isTrue);
  expect(steps.last.title, '完成理论课程');
});
```

Also test blank next step, failed transaction rollback, and position assignment.

- [ ] **Step 2: Run transaction tests and verify failure**

Run: `flutter test test/progress_record_test.dart`

Expected: compile failure for `ProgressRepository`.

- [ ] **Step 3: Implement the atomic repository command**

Use one Drift transaction. Insert the check-in, mark the selected milestone done with the supplied UTC timestamp, and append the trimmed next step only when non-empty. Never create a placeholder milestone.

- [ ] **Step 4: Build the record sheet**

The sheet contains progress text, an optional “同时完成当前里程碑” checkbox, and a conditional next-step input. Preserve input on repository errors and show a retry message.

- [ ] **Step 5: Replace detail-page record actions**

Route detail and home card record buttons through the same sheet. Invalidate no providers manually; Drift streams must refresh the read model.

- [ ] **Step 6: Run repository and widget tests**

Run: `flutter test test/progress_record_test.dart test/widget_test.dart`

Expected: all pass.

- [ ] **Step 7: Commit the recording flow**

```bash
git add lib/core/db/progress_repository.dart lib/core/models/progress_record.dart lib/app/providers.dart lib/features/goals test/progress_record_test.dart test/widget_test.dart
git commit -m "feat: unify progress and milestone recording"
```

### Task 4: Redesign goal creation and icon classification

**Files:**
- Create: `lib/features/goals/goal_icon_picker.dart`
- Create: `lib/features/goals/goal_editor_sections.dart`
- Modify: `lib/features/goals/goal_editor.dart`
- Modify: `lib/core/copy.dart`
- Test: `test/goal_editor_test.dart`
- Test: `test/goal_icon_catalog_test.dart`

**Interfaces:**
- Produces: `Future<GoalIconCatalog?> showGoalIconPicker(...)` and type-specific editor draft state.
- Consumes: Task 1 goal fields, existing 38-icon `GoalIconCatalog`, repositories, and settings defaults.

- [ ] **Step 1: Write failing editor widget tests**

```dart
testWidgets('editor has no template or motivation fields', (tester) async {
  await pumpEditor(tester);
  expect(find.text('目标名称'), findsOneWidget);
  expect(find.text('为什么想完成'), findsNothing);
  expect(find.text('一句话描述'), findsNothing);
});

testWidgets('type switch shows only relevant fields and keeps drafts',
    (tester) async {
  await pumpEditor(tester);
  await tester.tap(find.text('长期'));
  await tester.pumpAndSettle();
  expect(find.text('目标日期'), findsOneWidget);
  expect(find.text('每 14 天'), findsOneWidget);
  await tester.tap(find.text('习惯'));
  await tester.pumpAndSettle();
  expect(find.text('执行频率'), findsOneWidget);
});
```

- [ ] **Step 2: Run editor tests and verify current layout fails**

Run: `flutter test test/goal_editor_test.dart`

Expected: assertions fail against the current expanded editor.

- [ ] **Step 3: Extract an icon picker using the existing 38 icons**

Show six recent/common icons plus “更多”. The bottom sheet groups `GoalIconCatalog.byDomain`, uses semantic Chinese domain and icon labels, shows the inferred domain immediately, and allows category override without forcing an icon change.

- [ ] **Step 4: Replace the editor with ordered dynamic sections**

Render name, type, icon/inferred category, type settings, optional first step, and create button. Remove template chips, motivation, and description inputs. Keep per-type draft state in memory when the segmented control changes.

- [ ] **Step 5: Save the new fields**

For short goals require deadline and use the settings default 7-day cadence; for long goals allow target date and use 14 days; for habits require 1–7 weekly target and optional end date. Create the optional first milestone only when its trimmed title is non-empty.

- [ ] **Step 6: Run editor, icon, migration, and backup tests**

Run: `flutter test test/goal_editor_test.dart test/goal_icon_catalog_test.dart test/migration_test.dart test/backup_test.dart`

Expected: all pass.

- [ ] **Step 7: Commit the editor redesign**

```bash
git add lib/features/goals/goal_editor.dart lib/features/goals/goal_editor_sections.dart lib/features/goals/goal_icon_picker.dart lib/core/copy.dart test/goal_editor_test.dart test/goal_icon_catalog_test.dart
git commit -m "feat: redesign type-aware goal creation"
```

### Task 5: Redesign the home status, goal carousel, trend, and attention sections

**Files:**
- Create: `lib/features/today/goal_status_card.dart`
- Create: `lib/features/today/progress_trend_card.dart`
- Create: `lib/features/today/attention_goal_list.dart`
- Modify: `lib/features/today/today_view.dart`
- Modify: `lib/features/today/focus_carousel.dart`
- Modify: `lib/core/copy.dart`
- Test: `test/today_redesign_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `goalProgressProvider`, `GoalProgressEvaluation`, `GoalAdvice`, `AttentionItem`, and `showProgressRecordSheet`.
- Produces: focused presentational widgets with no embedded scoring or category logic.

- [ ] **Step 1: Write failing home layout tests**

```dart
testWidgets('home orders status, focus, progress and attention', (tester) async {
  await pumpToday(tester, seededEvaluation());
  expect(find.byKey(const ValueKey('goalStatusCard')), findsOneWidget);
  expect(find.text('关注'), findsOneWidget);
  expect(find.text('进展'), findsOneWidget);
  expect(find.text('需要关注'), findsOneWidget);
});

testWidgets('focus carousel has a visible inter-card gap', (tester) async {
  await pumpToday(tester, seededEvaluation(goalCount: 2));
  final gap = tester.getTopLeft(find.byKey(const ValueKey('focusCard-1'))).dx -
      tester.getTopRight(find.byKey(const ValueKey('focusCard-0'))).dx;
  expect(gap, greaterThanOrEqualTo(12));
});
```

Add tests for no-data state, long names, advice expansion, real goal icons, and 320dp overflow.

- [ ] **Step 2: Run home tests and verify failure**

Run: `flutter test test/today_redesign_test.dart`

Expected: missing keys and current carousel gap assertion failure.

- [ ] **Step 3: Build the status card**

Move the ring into an opaque themed card. Center label is “目标状态”; render three independent values without a composite score and preserve no-data semantics.

- [ ] **Step 4: Redesign the focus carousel**

Use `PageView.builder` with explicit horizontal padding and child padding or a fraction that yields 12–16dp actual gaps. Each card displays status, real icon, type, deadline/target date, latest completed step, next step, record button, and cadence. Keep the indicator immediately below the card.

- [ ] **Step 5: Build the seven-day progress trend**

Use a `CustomPainter` with seven real `LocalDate` points and three stable series colors. Draw neutral horizontal guides, direct current values, and a date axis. Do not connect category labels. The exclamation control expands the corresponding three-part advice below the plot.

- [ ] **Step 6: Build the attention list**

Render independent cards with each goal’s real icon, objective reason tag, one-line action, and detail chevron. Sort by needs-planning, deadline-near, then rhythm-interrupted; within a reason sort by urgency and name.

- [ ] **Step 7: Compose the scrolling page**

Use one `CustomScrollView` or `SingleChildScrollView` without fixed spacer heights. Keep the dock safe-area behavior unchanged.

- [ ] **Step 8: Run home tests and golden-size smoke checks**

Run: `flutter test test/today_redesign_test.dart test/widget_test.dart`

Run: `flutter analyze lib/features/today`

Expected: all pass and no overflow exceptions.

- [ ] **Step 9: Commit the home redesign**

```bash
git add lib/features/today lib/core/copy.dart test/today_redesign_test.dart test/widget_test.dart
git commit -m "feat: redesign home progress experience"
```

### Task 6: Separate the profile hub from traditional settings

**Files:**
- Create: `lib/features/profile/profile_hub.dart`
- Create: `lib/features/settings/appearance_sheet.dart`
- Modify: `lib/features/settings/settings_view.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/core/copy.dart`
- Test: `test/profile_settings_test.dart`
- Test: `test/profile_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: root route `/profile`, child route `/settings`, and bottom-sheet appearance selection.
- Consumes: existing `profileProvider`, `settingsProvider`, `goalsProvider`, `stepsProvider`, reminders, and theme mode persistence.

- [ ] **Step 1: Write failing navigation and layout tests**

```dart
testWidgets('profile is a light themed hub with compact counts', (tester) async {
  await pumpProfile(tester);
  expect(find.text('进行中'), findsOneWidget);
  expect(find.text('本月里程碑'), findsOneWidget);
  expect(find.text('已归档'), findsOneWidget);
  expect(find.text('设置'), findsOneWidget);
});

testWidgets('appearance opens a bottom sheet instead of inline rows',
    (tester) async {
  await pumpSettings(tester);
  expect(find.text('跟随系统'), findsOneWidget);
  expect(find.byKey(const ValueKey('themeLight')), findsNothing);
  await tester.tap(find.text('外观模式'));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('appearanceSheet')), findsOneWidget);
});
```

- [ ] **Step 2: Run profile/settings tests and verify failure**

Run: `flutter test test/profile_settings_test.dart test/profile_test.dart`

Expected: current combined settings page fails the hub and sheet assertions.

- [ ] **Step 3: Build the profile hub**

Use an opaque scaffold background, profile card, three counts, target management, category management, and a settings entry. Counts are static summaries only; do not add review trends.

- [ ] **Step 4: Simplify the settings list**

Keep appearance, default cadence, notification/reminder, daily brief, per-goal reminders, and about in traditional grouped rows. Preserve backup/debug features under their existing conditional or secondary sections without promoting them above the approved primary rows.

- [ ] **Step 5: Add the appearance sheet**

Present system, light, and dark options with the current checkmark. Persist immediately through `SettingsRepository.update`; closing and reopening reflects the saved value.

- [ ] **Step 6: Update routes and avatar entry**

The Today avatar pushes `/profile`; profile settings pushes `/settings`; both cover the dock as root routes. Preserve `/settings` deep links.

- [ ] **Step 7: Run settings, profile, router, and theme tests**

Run: `flutter test test/profile_settings_test.dart test/profile_test.dart test/widget_test.dart test/design/token_contract_test.dart`

Expected: all pass in light and dark theme pumps.

- [ ] **Step 8: Commit profile/settings**

```bash
git add lib/features/profile lib/features/settings lib/app/router.dart lib/core/copy.dart test/profile_settings_test.dart test/profile_test.dart test/widget_test.dart
git commit -m "feat: separate profile hub and settings"
```

### Task 7: Final integration, accessibility, migration boundary, and regression

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/app/design_tokens.dart`
- Modify: `lib/core/copy.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/migration_test.dart`
- Modify: `README.md` only if it already documents current UI behavior

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: one integrated, analyzable, testable application with no old scoring consumers.

- [ ] **Step 1: Search for stale scoring, transparent root backgrounds, and retired copy**

Run:

```bash
rg -n "healthScoreProvider|evaluateHealth|Colors\.transparent|一句话描述|补一句为什么|themeSystem|themeLight|themeDark" lib test
```

Expected: only intentional migration compatibility or tests remain.

- [ ] **Step 2: Add integration tests for approved edge states**

Cover no goals, no history, no next step, overdue short goal, classification fallback, notification denied, long names, text scale 1.3, light, dark, and system theme.

- [ ] **Step 3: Add the score-algorithm boundary treatment**

Use `Settings.scoreAlgorithmStartedOn` to suppress pre-v2 trend points. When the seven-day range crosses the boundary, show “评分规则已更新” at that date instead of connecting incompatible values.

- [ ] **Step 4: Run formatting and static analysis**

Run: `dart format lib test`

Run: `flutter analyze`

Expected: zero diagnostics.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 6: Run platform build smoke tests available in the workspace**

Run: `flutter build web --debug`

Run iOS analyze/build only when an iOS toolchain is available; otherwise record that platform limitation without claiming it passed.

- [ ] **Step 7: Commit final integration**

```bash
git add lib test README.md
git commit -m "test: verify Target redesign integration"
```

- [ ] **Step 8: Inspect the final diff and commit history**

Run: `git status --short`

Run: `git log --oneline --max-count=10`

Expected: clean worktree and one reviewable commit per task.

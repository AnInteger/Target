# Goal Foundation and Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the rigid goal-type workflow with a compatible unified goal plan, add reversible lifecycle management, and make Goals a first-class compact management tab.

**Architecture:** Add schema-v7 planning fields while retaining legacy columns for old consumers and backup compatibility. A `GoalPlanRepository` owns atomic goal, milestone, and reminder writes; the editor and compact Goals list consume that boundary instead of coordinating multiple repositories in widgets. The existing Today, detail, progress, scoring, and review consumers remain operational through derived legacy compatibility values until their dedicated follow-up phases replace them.

**Tech Stack:** Flutter, Dart 3, Riverpod, go_router, Drift/SQLite, flutter_test, build_runner

**Spec:** `docs/superpowers/specs/2026-08-26-target-product-structure-redesign.md`

## Global Constraints

- Work only on `fix/ui-v2-first-run-and-shell-polish` and preserve existing user data.
- New and edited goals must not expose `GoalType`, templates, or `progressCadenceDays`.
- A goal name is the only required creation field; target date, frequency, milestones, category, and reminder are optional.
- All goals may combine a target date, a `FrequencyPattern`, milestones, and a reminder.
- Goal structure is edited only in the goal editor; milestone completion remains outside this phase and continues to work in detail.
- Archive is reversible and must not delete records; delete remains a separately confirmed destructive action.
- The repository must allow more than five active goals. This phase does not add a focus-selection model.
- The Goals tab uses compact management rows and a visible overflow button; it must not reuse Today focus cards.
- Keep old `goal_type`, `deadline`, `progress_cadence_days`, and `habit_target_per_week` columns readable until the Today/detail/review phases stop consuming them.
- Do not change the current progress-record sheet, Today cards, detail history, progress scoring, Profile, Settings, or notification content in this phase except for compile-safe route and compatibility updates.
- Every schema change must have v6→v7 migration, fresh-install, backup round-trip, and old-backup import coverage.

## Program Decomposition

This is phase 1 of three independently reviewed plans:

1. **This plan:** unified goal foundation, editor, lifecycle, Goals list, and navigation.
2. **Follow-up scope:** Today overview/cards, goal detail ownership, and simplified progress recording.
3. **Follow-up scope:** Review timeline/achievements and cleanup of Profile, Settings, notifications, and legacy scoring.

The current phase is complete only when the app builds and existing Today/detail/progress behavior still runs against migrated or newly created goals.

---

### Task 1: Add schema-v7 unified planning fields and migration

**Files:**
- Modify: `lib/core/db/tables.dart`
- Modify: `lib/core/db/app_database.dart`
- Regenerate: `lib/core/db/app_database.g.dart`
- Modify: `test/migration_test.dart`
- Modify: `test/version_seed.dart`

**Interfaces:**
- Consumes: existing `FrequencyPatternJson`, `GoalIconCatalog.byKey`, v6 goal columns, and legacy `frequency_versions` rows.
- Produces: nullable Drift columns `Goals.frequencyPattern` and `Goals.archivedAt`; schema version `7`.

- [x] **Step 1: Add a failing v6→v7 migration test**

Add a `_V6Database` fixture whose goal table matches schema v6, then add this test to `test/migration_test.dart`:

```dart
test('v6→v7：日期、频率、分类和归档语义迁移且历史不丢失', () async {
  {
    final v6 = _V6Database(NativeDatabase(file));
    await v6.customStatement(
      "INSERT INTO goals "
      "(id,name,goal_type,icon_key,status,created_at,deadline,"
      "progress_cadence_days,habit_target_per_week) VALUES "
      "('dated','拿到潜水证','shortTerm','pool','active',"
      "'2026-08-01','2026-10-01',7,NULL),"
      "('habit','保持跑步','habit','directions_run','active',"
      "'2026-08-01',NULL,7,3),"
      "('old-archive','旧目标','longTerm','explore','archived',"
      "'2026-08-01',NULL,14,NULL)",
    );
    await v6.close();
  }

  final db = AppDatabase(NativeDatabase(file));
  addTearDown(db.close);
  final rows = await db.select(db.goals).get();
  final byId = {for (final row in rows) row.id: row};

  expect(byId['dated']!.targetDate, const LocalDate(2026, 10, 1));
  expect(byId['dated']!.frequencyPattern, isNull);
  expect(
    byId['habit']!.frequencyPattern,
    const WeeklyFrequency(3),
  );
  expect(byId['dated']!.categoryOverride, 'fitness');
  expect(byId['old-archive']!.archivedAt, isNotNull);
  expect(byId['old-archive']!.status, GoalStatus.paused);
});
```

- [x] **Step 2: Run the migration test and verify it fails**

Run:

```bash
flutter test test/migration_test.dart --plain-name "v6→v7：日期、频率、分类和归档语义迁移且历史不丢失"
```

Expected: FAIL because schema version 7 and the two new columns do not exist.

- [x] **Step 3: Add the Drift columns**

In `Goals` add:

```dart
TextColumn get frequencyPattern =>
    text().nullable().map(const FrequencyPatternJson())();
TextColumn get archivedAt => text().nullable().map(const IsoDateTimeText())();
```

Do not drop or rename legacy columns in this migration.

- [x] **Step 4: Implement `_migrateV7`**

Set `schemaVersion => 7`, call `_migrateV7(m)` from `onUpgrade` when `from < 7`, and implement the migration with these exact rules:

```dart
Future<void> _migrateV7(Migrator m) async {
  await m.addColumn(goals, goals.frequencyPattern);
  await m.addColumn(goals, goals.archivedAt);

  await customUpdate(
    'UPDATE goals SET target_date = deadline '
    'WHERE target_date IS NULL AND deadline IS NOT NULL',
    updates: {goals},
  );

  final rows = await customSelect(
    'SELECT id, goal_type, icon_key, habit_target_per_week, status '
    'FROM goals',
    readsFrom: {goals},
  ).get();
  final versions = await select(frequencyVersions).get();

  for (final row in rows) {
    final id = row.read<String>('id');
    final latest = versions.where((v) => v.goalId == id).toList()
      ..sort((a, b) => a.effectiveFromWeek.compareTo(b.effectiveFromWeek));
    FrequencyPattern? pattern = latest.isEmpty ? null : latest.last.pattern;
    if (pattern == null && row.read<String>('goal_type') == 'habit') {
      pattern = WeeklyFrequency(
        row.readNullable<int>('habit_target_per_week') ?? 5,
      );
    }
    final category = GoalIconCatalog.byKey(
      row.read<String>('icon_key'),
    ).domain.name;
    final archived = row.read<String>('status') == 'archived';
    await customUpdate(
      'UPDATE goals SET frequency_pattern = ?, '
      'category_override = COALESCE(category_override, ?), '
      'archived_at = CASE WHEN ? THEN ? ELSE archived_at END, '
      "status = CASE WHEN status = 'archived' THEN 'paused' ELSE status END "
      'WHERE id = ?',
      variables: [
        Variable(pattern?.toJsonString()),
        Variable(category),
        Variable(archived),
        Variable(archived ? DateTime.now().toUtc().toIso8601String() : null),
        Variable(id),
      ],
      updates: {goals},
    );
  }
}
```

Import `FrequencyPattern`, `WeeklyFrequency`, and `GoalIconCatalog`. Keep migration time UTC and test only non-nullness because the exact upgrade instant is environment-dependent.

- [x] **Step 5: Regenerate Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/core/db/app_database.g.dart` contains nullable `frequencyPattern` and `archivedAt` members and no generator errors.

- [x] **Step 6: Run migration and schema tests**

Run:

```bash
flutter test test/migration_test.dart test/version_seed.dart
```

Expected: PASS, including all v1–v6 upgrade paths.

- [x] **Step 7: Commit the schema slice**

```bash
git add lib/core/db/tables.dart lib/core/db/app_database.dart lib/core/db/app_database.g.dart test/migration_test.dart test/version_seed.dart
git commit -m "feat: add unified goal planning schema"
```

---

### Task 2: Introduce compatible unified Goal semantics and lifecycle

**Files:**
- Modify: `lib/core/models/entities.dart`
- Create: `lib/core/db/goal_row_mapper.dart`
- Modify: `lib/core/db/repositories.dart`
- Modify: `lib/features/goals/goal_lifecycle.dart`
- Create: `test/goal_lifecycle_v7_test.dart`
- Modify: `test/frequency_version_test.dart`

**Interfaces:**
- Consumes: Task 1 columns and existing `FrequencyPattern` subclasses.
- Produces: `Goal.frequency`, `Goal.archivedAt`, `Goal.isArchived`, `Goal.isActive`, clearable `Goal.copyWith`, unrestricted active-goal repository writes, and lifecycle functions `archiveGoal`, `unarchiveGoal`, `reopenGoal`.

- [x] **Step 1: Write failing domain tests**

Create `test/goal_lifecycle_v7_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';

Goal _goal(String id) => Goal(
  id: id,
  name: '目标 $id',
  goalType: GoalType.longTerm,
  iconKey: 'explore',
  colorKey: '',
  createdAt: const LocalDate(2026, 8, 1),
  targetDate: const LocalDate(2026, 12, 31),
  frequency: const WeeklyFrequency(3),
);

void main() {
  test('日期、频率和里程碑能力不再由 legacy goalType 互斥', () {
    final goal = _goal('combined');
    expect(goal.targetDate, isNotNull);
    expect(goal.frequency, const WeeklyFrequency(3));
  });

  test('归档可逆且重新开启会清除达成时间', () {
    final achieved = _goal('done').copyWith(
      status: GoalStatus.achieved,
      achievedAt: DateTime.utc(2026, 8, 20),
      archivedAt: DateTime.utc(2026, 8, 21),
    );
    final reopened = achieved.copyWith(
      status: GoalStatus.active,
      clearAchievedAt: true,
      clearArchivedAt: true,
    );
    expect(reopened.status, GoalStatus.active);
    expect(reopened.achievedAt, isNull);
    expect(reopened.archivedAt, isNull);
  });

  test('仓储允许超过五个进行中目标', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = GoalRepository(db);
    for (var i = 0; i < 8; i++) {
      await repo.create(_goal('$i'));
    }
    expect((await repo.getGoals()).length, 8);
  });
}
```

- [x] **Step 2: Run the domain tests and verify failure**

Run:

```bash
flutter test test/goal_lifecycle_v7_test.dart
```

Expected: FAIL because `frequency`, `archivedAt`, and clear flags do not exist and the sixth active goal throws.

- [x] **Step 3: Extend `Goal` without breaking legacy consumers**

Make the constructor's existing `goalType` parameter optional and derive its compatibility value when omitted:

```dart
goalType = goalType ??
    (targetDate != null
        ? GoalType.shortTerm
        : frequency != null
        ? GoalType.habit
        : GoalType.longTerm),
progressCadenceDays = progressCadenceDays ??
    (targetDate == null && frequency == null ? 14 : 7),
deadline = deadline ?? targetDate;
```

Remove constructor assertions that restrict deadline, target date, or weekly frequency to one legacy type. Keep value-range assertions. Existing call sites may still pass `goalType`; the new editor must not.

Add these fields:

```dart
final FrequencyPattern? frequency;
final DateTime? archivedAt;
bool get isArchived => archivedAt != null;
bool get isActive => status == GoalStatus.active && !isArchived;
```

Keep `goalType`, `progressCadenceDays`, `deadline`, and `habitTargetPerWeek` as documented compatibility fields for current Today/detail/progress code. Mark their comments as legacy and do not expose them in new UI.

Extend `copyWith` with explicit clearing:

```dart
Goal copyWith({
  String? name,
  GoalStatus? status,
  String? iconKey,
  GoalIconDomain? categoryOverride,
  LocalDate? targetDate,
  bool clearTargetDate = false,
  FrequencyPattern? frequency,
  bool clearFrequency = false,
  DateTime? achievedAt,
  bool clearAchievedAt = false,
  DateTime? archivedAt,
  bool clearArchivedAt = false,
  // retain existing compatibility parameters
})
```

Use `clearX ? null : (x ?? this.x)` for nullable fields and include new fields in equality and `hashCode`.

- [x] **Step 4: Expand lifecycle semantics**

Change `canTransitTo` so every non-archived goal can be achieved, including legacy habits:

```dart
bool canTransitTo(GoalStatus to) {
  if (isArchived) return false;
  return switch (status) {
    GoalStatus.active =>
      to == GoalStatus.paused || to == GoalStatus.achieved,
    GoalStatus.paused =>
      to == GoalStatus.active || to == GoalStatus.achieved,
    GoalStatus.achieved => to == GoalStatus.active,
    GoalStatus.archived => false,
  };
}
```

`GoalStatus.archived` remains only to decode old rows and backups; repositories must not write it after schema v7.

- [x] **Step 5: Centralize row mapping and remove the active cap**

Create `goal_row_mapper.dart` with one shared mapper used by both repositories:

```dart
abstract final class GoalRowMapper {
  static Goal fromRow(db.Goal row);
  static db.GoalsCompanion toCompanion(Goal goal);
  static GoalType legacyTypeOf(Goal goal);
  static int legacyCadenceOf(Goal goal);
  static int? legacyWeeklyTargetOf(Goal goal);
}
```

Map `frequencyPattern` and `archivedAt` both directions. Change `watchActiveGoals` to require `status == active` and `archived_at IS NULL`. Delete active-count checks from `create` and `update`; keep `ActiveGoalLimitException` only until all compile references are removed in this task, then delete the class and its UI catches.

When writing compatibility columns, derive them from the unified settings:

```dart
static GoalType legacyTypeOf(Goal goal) {
  if (goal.targetDate != null) return GoalType.shortTerm;
  if (goal.frequency != null) return GoalType.habit;
  return GoalType.longTerm;
}

static int legacyCadenceOf(Goal goal) =>
    goal.targetDate == null && goal.frequency == null ? 14 : 7;

static int? legacyWeeklyTargetOf(Goal goal) => switch (goal.frequency) {
  WeeklyFrequency(:final timesPerWeek) => timesPerWeek,
  DailyFrequency() => 7,
  WeekdaysFrequency(:final days) => days.length,
  null => null,
};
```

Write `deadline = targetDate` for compatibility and write the explicit category to the existing `category_override` column.

- [x] **Step 6: Add lifecycle orchestration functions**

In `goal_lifecycle.dart` add:

```dart
Future<void> archiveGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(goal.copyWith(archivedAt: DateTime.now().toUtc()));

Future<void> unarchiveGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(goal.copyWith(clearArchivedAt: true));

Future<void> reopenGoal(WidgetRef ref, Goal goal) => ref
    .read(goalRepoProvider)
    .update(
      goal.copyWith(
        status: GoalStatus.active,
        clearAchievedAt: true,
        clearArchivedAt: true,
      ),
    );
```

Update `achieveGoal` to work for every goal and write UTC. Remove focus-limit dialogs and exception handling.

- [x] **Step 7: Run lifecycle and affected repository tests**

Run:

```bash
flutter test test/goal_lifecycle_v7_test.dart test/frequency_version_test.dart test/goal_progress_model_test.dart
```

Expected: PASS. Update old “sixth active goal is rejected” assertions to expect successful creation; do not simply delete the coverage.

- [x] **Step 8: Commit the domain slice**

```bash
git add lib/core/models/entities.dart lib/core/db/goal_row_mapper.dart lib/core/db/repositories.dart lib/features/goals/goal_lifecycle.dart test/goal_lifecycle_v7_test.dart test/frequency_version_test.dart test/goal_progress_model_test.dart
git commit -m "refactor: unify goal planning and lifecycle semantics"
```

---

### Task 3: Add atomic goal-plan persistence

**Files:**
- Create: `lib/core/models/goal_plan.dart`
- Create: `lib/core/db/goal_plan_repository.dart`
- Modify: `lib/app/providers.dart`
- Create: `test/goal_plan_repository_test.dart`

**Interfaces:**
- Consumes: `Goal`, `MilestoneStep`, `Reminder`, `FrequencyPattern`, and Task 2 repository mapping.
- Produces: `GoalPlanInput`, `GoalPlanSnapshot`, `GoalPlanRepository.load`, `GoalPlanRepository.create`, and `GoalPlanRepository.update`.

- [x] **Step 1: Write failing atomic-persistence tests**

Create `test/goal_plan_repository_test.dart` with this fixture and these three cases:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/db/app_database.dart';
import 'package:target/core/db/goal_plan_repository.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/models/goal_plan.dart';

Goal baseGoal(String id) => Goal(
  id: id,
  name: '21 天跑步计划',
  goalType: GoalType.shortTerm,
  iconKey: 'directions_run',
  colorKey: '',
  createdAt: const LocalDate(2026, 8, 1),
  targetDate: const LocalDate(2026, 9, 1),
  frequency: const WeeklyFrequency(3),
);

void main() {
  late AppDatabase db;
  late GoalPlanRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GoalPlanRepository(db);
  });

  tearDown(() => db.close());

test('create atomically stores goal, ordered milestones, and reminder', () async {
  final input = GoalPlanInput(
    goal: baseGoal('create'),
    milestones: const [
      MilestoneDraft(title: '坚持 7 天'),
      MilestoneDraft(title: '坚持 21 天'),
    ],
    reminder: ReminderDraft(
      enabled: true,
      time: const LocalTime(9, 0),
      cadence: Cadence.daily,
    ),
  );
  final created = await repo.create(input);
  final loaded = await repo.load(created.id);
  expect(loaded!.goal.frequency, const WeeklyFrequency(3));
  expect(loaded.milestones.map((m) => m.position), [0, 1]);
  expect(loaded.reminder!.isEnabled, isTrue);
});

test('update can clear date and frequency and preserves completed milestone', () async {
  final doneAt = DateTime.utc(2026, 8, 20, 8);
  final created = await repo.create(
    GoalPlanInput(
      goal: baseGoal('edit'),
      milestones: [
        MilestoneDraft(
          id: 'keep',
          title: '坚持 7 天',
          isDone: true,
          doneAt: doneAt,
        ),
        const MilestoneDraft(id: 'remove', title: '坚持 14 天'),
      ],
      reminder: const ReminderDraft(
        id: 'edit-reminder',
        enabled: true,
        time: LocalTime(9, 0),
        cadence: Cadence.daily,
      ),
    ),
  );

  await repo.update(
    GoalPlanInput(
      goal: created.copyWith(
        clearTargetDate: true,
        clearFrequency: true,
      ),
      milestones: [
        MilestoneDraft(
          id: 'keep',
          title: '连续完成第一阶段',
          isDone: true,
          doneAt: doneAt,
        ),
      ],
      reminder: null,
    ),
  );

  final loaded = await repo.load(created.id);
  expect(loaded!.goal.targetDate, isNull);
  expect(loaded.goal.frequency, isNull);
  expect(loaded.milestones, hasLength(1));
  expect(loaded.milestones.single.id, 'keep');
  expect(loaded.milestones.single.title, '连续完成第一阶段');
  expect(loaded.milestones.single.isDone, isTrue);
  expect(loaded.milestones.single.doneAt, doneAt);
  expect(loaded.reminder, isNull);
});

test('invalid update leaves goal milestones and reminder unchanged', () async {
  final created = await repo.create(
    GoalPlanInput(
      goal: baseGoal('rollback'),
      milestones: const [MilestoneDraft(id: 'original', title: '原里程碑')],
      reminder: const ReminderDraft(
        id: 'rollback-reminder',
        enabled: true,
        time: LocalTime(9, 0),
        cadence: Cadence.daily,
      ),
    ),
  );

  await expectLater(
    repo.update(
      GoalPlanInput(
        goal: created.copyWith(name: '不应保存的新名称'),
        milestones: [
          MilestoneDraft(title: List.filled(51, '超').join()),
        ],
        reminder: const ReminderDraft(
          id: 'rollback-reminder',
          enabled: false,
          time: LocalTime(18, 0),
          cadence: Cadence.weekly,
        ),
      ),
    ),
    throwsArgumentError,
  );

  final loaded = await repo.load(created.id);
  expect(loaded!.goal.name, '21 天跑步计划');
  expect(loaded.milestones.single.id, 'original');
  expect(loaded.milestones.single.title, '原里程碑');
  expect(loaded.reminder!.isEnabled, isTrue);
  expect(loaded.reminder!.time, const LocalTime(9, 0));
});
}
```

- [x] **Step 2: Run the repository test and verify failure**

Run:

```bash
flutter test test/goal_plan_repository_test.dart
```

Expected: FAIL because the model and repository do not exist.

- [x] **Step 3: Define the plan models**

Create `goal_plan.dart`:

```dart
class MilestoneDraft {
  const MilestoneDraft({
    this.id,
    required this.title,
    this.isDone = false,
    this.doneAt,
  });
  final String? id;
  final String title;
  final bool isDone;
  final DateTime? doneAt;
}

class ReminderDraft {
  const ReminderDraft({
    this.id,
    required this.enabled,
    required this.time,
    required this.cadence,
  });
  final String? id;
  final bool enabled;
  final LocalTime time;
  final Cadence cadence;
}

class GoalPlanInput {
  const GoalPlanInput({
    required this.goal,
    required this.milestones,
    this.reminder,
  });
  final Goal goal;
  final List<MilestoneDraft> milestones;
  final ReminderDraft? reminder;
}

class GoalPlanSnapshot {
  const GoalPlanSnapshot({
    required this.goal,
    required this.milestones,
    this.reminder,
  });
  final Goal goal;
  final List<MilestoneStep> milestones;
  final Reminder? reminder;
}
```

- [x] **Step 4: Implement transactional create/load/update**

`GoalPlanRepository` owns an `AppDatabase` and uses one Drift transaction per create or update.

Rules:

```dart
Future<GoalPlanSnapshot?> load(String goalId);
Future<Goal> create(GoalPlanInput input);
Future<void> update(GoalPlanInput input);
```

- Normalize names and milestone titles with `trim()`.
- Reject an empty goal name, duplicate milestone ids, empty milestone titles, titles over 50 characters, and `isDone == true && doneAt == null` before entering the transaction.
- Assign milestone positions from list order.
- Preserve existing milestone completion state when an existing id is retained.
- Delete omitted milestone ids only during `update`.
- Store zero or one reminder per goal; a null draft removes the existing goal reminder.
- Never touch the daily-brief reminder (`goalId == null`).
- Return the created goal id so the editor can navigate directly to detail.

Use `GoalRowMapper.toCompanion` and `GoalRowMapper.fromRow` from Task 2; do not duplicate compatibility derivation.

- [x] **Step 5: Add the provider**

In `providers.dart` add:

```dart
final goalPlanRepoProvider = Provider(
  (ref) => GoalPlanRepository(ref.watch(dbProvider)),
);
```

- [x] **Step 6: Run repository and transaction tests**

Run:

```bash
flutter test test/goal_plan_repository_test.dart test/progress_record_test.dart
```

Expected: PASS, including rejection-before-mutation coverage and the transaction-backed valid writes.

- [x] **Step 7: Commit the persistence boundary**

```bash
git add lib/core/models/goal_plan.dart lib/core/db/goal_plan_repository.dart lib/app/providers.dart test/goal_plan_repository_test.dart
git commit -m "feat: persist complete goal plans atomically"
```

---

### Task 4: Upgrade backup format for unified planning

**Files:**
- Modify: `lib/core/backup/backup_exporter.dart`
- Modify: `lib/core/backup/backup_importer.dart`
- Modify: `test/backup_test.dart`

**Interfaces:**
- Consumes: schema-v7 `frequencyPattern`, `archivedAt`, legacy backup versions 1–5.
- Produces: backup version `6`, `frequencyPattern` JSON, and `archivedAt` ISO-8601 round-trip.

- [x] **Step 1: Add failing v6 backup round-trip tests**

Add to `test/backup_test.dart`:

```dart
test('v6 round-trip preserves frequency and reversible archive timestamp', () async {
  final archivedAt = DateTime.utc(2026, 8, 26, 9, 30);
  await GoalRepository(src).create(
    Goal(
      id: 'combined',
      name: '21 天跑步计划',
      goalType: GoalType.shortTerm,
      iconKey: 'directions_run',
      colorKey: '',
      createdAt: const LocalDate(2026, 8, 1),
      targetDate: const LocalDate(2026, 9, 1),
      frequency: const WeekdaysFrequency(
        {Weekday.mon, Weekday.wed, Weekday.fri},
        1,
      ),
      archivedAt: archivedAt,
    ),
  );

  final encoded = await BackupExporter(src).exportString();
  final map = jsonDecode(encoded) as Map<String, dynamic>;
  expect(map['version'], 6);
  final restoredData = BackupImporter(target).parse(encoded);
  await BackupImporter(target).replace(restoredData);
  final restored = (await GoalRepository(target).getGoals()).single;
  expect(restored.frequency, isA<WeekdaysFrequency>());
  expect(restored.archivedAt, archivedAt);
});
```

Retain existing tests that import backup versions 1–5.

- [x] **Step 2: Run the backup test and verify failure**

Run:

```bash
flutter test test/backup_test.dart --plain-name "v6 round-trip preserves frequency and reversible archive timestamp"
```

Expected: FAIL because backup version is 5 and the fields are missing.

- [x] **Step 3: Export the new fields**

Set `kBackupVersion = 6` and add:

```dart
if (g.frequencyPattern != null)
  'frequencyPattern': g.frequencyPattern!.toJson(),
'archivedAt': g.archivedAt?.toUtc().toIso8601String(),
```

Continue exporting legacy fields for backward inspection and current-version recovery.

- [x] **Step 4: Validate and import the new fields**

- Accept absent `frequencyPattern` and `archivedAt` for versions 1–5.
- Validate `frequencyPattern` by calling `FrequencyPattern.fromJson` inside a guarded parse and report the exact goal index on failure.
- Validate `archivedAt` with the existing instant validator.
- When a legacy goal has no `frequencyPattern`, derive it with the same migration rules as Task 1.
- When a legacy goal status is `archived`, write `status = paused` plus a non-null archive timestamp using the backup `exportedAt` instant.
- Write both new columns in the import transaction.

- [x] **Step 5: Run all backup tests**

Run:

```bash
flutter test test/backup_test.dart
```

Expected: PASS for versions 1–6, corrupt-field rejection, and atomic replacement.

- [x] **Step 6: Commit backup compatibility**

```bash
git add lib/core/backup/backup_exporter.dart lib/core/backup/backup_importer.dart test/backup_test.dart
git commit -m "feat: back up unified goal planning fields"
```

---

### Task 5: Replace the type/template editor with one unified form

**Files:**
- Create: `lib/features/goals/goal_editor_draft.dart`
- Create: `lib/features/goals/goal_frequency_field.dart`
- Create: `lib/features/goals/goal_milestone_editor.dart`
- Create: `lib/features/goals/goal_reminder_field.dart`
- Delete: `lib/features/goals/goal_templates.dart`
- Rewrite: `lib/features/goals/goal_editor.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/core/copy.dart`
- Rewrite: `test/goal_editor_test.dart`

**Interfaces:**
- Consumes: `GoalPlanRepository`, `GoalPlanInput`, `FrequencyPattern`, `GoalIconDomain`, and the existing icon picker.
- Produces: a single-page create/edit flow with stable test keys and no product-facing goal type or template API.

- [x] **Step 1: Write failing unified-editor widget tests**

Replace type-specific assertions in `test/goal_editor_test.dart` with these behaviors:

```dart
testWidgets('only the name is required and no type or template control exists', (
  tester,
) async {
  await pumpEditor(tester);
  expect(find.byKey(const ValueKey('goalTypeSeg')), findsNothing);
  expect(find.textContaining('模板'), findsNothing);
  await tester.enterText(
    find.byKey(const ValueKey('goalNameField')),
    '学习摄影',
  );
  expect(
    tester.widget<FilledButton>(
      find.byKey(const ValueKey('goalSaveButton')),
    ).onPressed,
    isNotNull,
  );
});

testWidgets('date and frequency can be enabled together', (tester) async {
  await pumpEditor(tester);
  await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
  await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
  await tester.tap(find.text('每周若干次'));
  await tester.tap(find.byKey(const ValueKey('weeklyCount-3')));
  expect(find.byKey(const ValueKey('goalTargetDateField')), findsOneWidget);
  expect(find.text('每周 3 次'), findsOneWidget);
});

testWidgets('milestones are editable for every goal configuration', (
  tester,
) async {
  await pumpEditor(tester);
  await tester.enterText(
    find.byKey(const ValueKey('milestoneDraftInput')),
    '完成理论课程',
  );
  await tester.tap(find.byKey(const ValueKey('milestoneDraftAdd')));
  expect(find.text('完成理论课程'), findsOneWidget);
  expect(find.byKey(const ValueKey('milestoneDraftHandle-0')), findsOneWidget);
});
```

Add create persistence and edit-clear tests that assert the database snapshot returned by `GoalPlanRepository.load`.

- [x] **Step 2: Run the editor tests and verify failure**

Run:

```bash
flutter test test/goal_editor_test.dart
```

Expected: FAIL because the old segmented type editor and first-plan field are still present.

- [x] **Step 3: Implement `GoalEditorDraft`**

The draft owns form state independent of widgets:

```dart
class GoalEditorDraft {
  GoalEditorDraft({
    required this.name,
    required this.iconKey,
    required this.category,
    required this.targetDate,
    required this.frequency,
    required this.milestones,
    required this.reminder,
  });

  String name;
  String iconKey;
  GoalIconDomain? category;
  LocalDate? targetDate;
  FrequencyPattern? frequency;
  List<MilestoneDraft> milestones;
  ReminderDraft? reminder;

  bool get canSave => name.trim().isNotEmpty;
  GoalPlanInput toInput({Goal? existing, required LocalDate today});
}
```

`toInput` preserves existing ids, status, created/achieved/archive timestamps, and legacy envelope fields. For a new goal, use the `explore` icon with a null category and do not set a date, frequency, milestone, or reminder.

- [x] **Step 4: Build focused optional-field widgets**

- `GoalFrequencyField` returns `FrequencyPattern?` and offers: none, daily, weekly 1–7, and weekdays with at least one selected day.
- `GoalMilestoneEditor` edits `List<MilestoneDraft>`, supports add, rename, remove, and reorder, and preserves ids/completion metadata for existing rows.
- `GoalReminderField` returns `ReminderDraft?`, with enabled, time, and the existing daily/three-day/weekly reminder cadence. Its switch key is `goalReminderSwitch`.
- Each interactive control has a minimum 44dp hit target and the test keys used above.

- [x] **Step 5: Rewrite the page composition**

Use this fixed section order:

```text
目标名称
图标与分类
目标日期（开关 + 日期）
执行节奏（可选）
里程碑（可选、完整列表编辑）
提醒（可选）
保存目标
```

Remove `GoalType` segments, template parameters, `_firstPlans`, `progressCadenceDays` controls, and all type-conditioned fields. Category selection writes explicit nullable `GoalIconDomain`; changing the icon must not silently change an already selected category.

- [x] **Step 6: Save through `GoalPlanRepository` and navigate correctly**

- Create: `final created = await repo.create(draft.toInput(...)); context.pushReplacement('/goal/${created.id}')`, preserving the Goals page beneath the editor/detail stack.
- Edit: `await repo.update(draft.toInput(existing: goal, ...)); context.pop()`.
- On persistence failure, keep the form values and show one retryable inline error.
- Remove the `GoalTemplate?` route extra and constructor parameter.

- [x] **Step 7: Run editor, icon, and app-journey tests**

Run:

```bash
flutter test test/goal_editor_test.dart test/goal_icon_catalog_test.dart test/app_journeys_test.dart
```

Expected: PASS after updating creation journeys to fill the unified controls instead of selecting a type.

- [x] **Step 8: Commit the editor slice**

```bash
git add lib/features/goals/goal_editor.dart lib/features/goals/goal_editor_draft.dart lib/features/goals/goal_frequency_field.dart lib/features/goals/goal_milestone_editor.dart lib/features/goals/goal_reminder_field.dart lib/features/goals/goal_templates.dart lib/app/router.dart lib/core/copy.dart test/goal_editor_test.dart test/app_journeys_test.dart
git commit -m "feat: redesign unified goal editor"
```

---

### Task 6: Build the compact Goals management page and state-aware menu

**Files:**
- Create: `lib/features/goals/goals_view.dart`
- Create: `lib/features/goals/goal_list_item.dart`
- Create: `lib/features/goals/goal_management_menu.dart`
- Delete after replacement: `lib/features/goals/goals_all_view.dart`
- Modify: `lib/core/copy.dart`
- Create: `test/goals_management_view_test.dart`
- Modify: `test/app_journeys_test.dart`

**Interfaces:**
- Consumes: goals, check-ins, all milestones, Task 2 lifecycle functions, and `/goal/:id` plus `/goal-editor?id=...` routes.
- Produces: `GoalsView`, `GoalListFilter`, compact `GoalListItem`, and `showGoalManagementMenu`.

- [x] **Step 1: Write failing list and menu tests**

Create `test/goals_management_view_test.dart` with a real in-memory database and router. Cover:

```dart
testWidgets('renders compact rows with visible overflow and no focus card', (
  tester,
) async {
  await pumpGoals(tester);
  expect(find.byKey(const ValueKey('goalListRow-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalOverflow-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('focusCard-active')), findsNothing);
});

testWidgets('status filters separate active paused achieved and archived', (
  tester,
) async {
  await pumpGoals(tester);
  await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('goalListRow-archived')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalListRow-active')), findsNothing);
});

testWidgets('overflow menu exposes state-valid actions', (tester) async {
  await pumpGoals(tester);
  await tester.tap(find.byKey(const ValueKey('goalOverflow-active')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('goalAction-edit-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalAction-pause-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalAction-achieve-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalAction-archive-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalAction-delete-active')), findsOneWidget);
  expect(find.byKey(const ValueKey('goalAction-resume-active')), findsNothing);
});
```

Also test pause, resume, achieve, reopen, archive, unarchive, and confirmed delete against repository state.

- [x] **Step 2: Run the new view tests and verify failure**

Run:

```bash
flutter test test/goals_management_view_test.dart
```

Expected: FAIL because the new classes and visible menu keys do not exist.

- [x] **Step 3: Implement compact row view data**

Define:

```dart
enum GoalListFilter { all, active, paused, achieved, archived }

class GoalListItemData {
  const GoalListItemData({
    required this.goal,
    required this.summary,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.lastActivity,
  });
  final Goal goal;
  final String summary;
  final int completedMilestones;
  final int totalMilestones;
  final LocalDate? lastActivity;
}
```

Summary priority:

1. First incomplete milestone: `当前：<title> · <done>/<total>`.
2. Latest valid progress date: `最近进展：M月D日`.
3. No milestone and no record: `尚无进展记录`.

Sort archived rows after non-archived rows, then active, paused, achieved, and finally by `lastActivity ?? goal.createdAt` descending.

- [x] **Step 4: Implement the compact management page**

Page structure:

```text
目标                         ＋ 新建
全部  进行中  已暂停  已达成  已归档
[compact list rows]
```

Each row contains a 40–44dp icon, one-line name, status badge, one-line summary, and visible overflow button. The whole row opens detail. Do not add a record button or gradient background in this phase.

- [x] **Step 5: Implement the state-aware menu**

`showGoalManagementMenu` must use explicit row buttons, not long-press discovery:

```dart
Future<void> showGoalManagementMenu(
  BuildContext context,
  WidgetRef ref,
  Goal goal,
);
```

Actions in this phase:

- Active: edit, pause, achieve, archive, delete.
- Paused: resume, edit, achieve, archive, delete.
- Achieved: reopen, archive, delete.
- Archived: unarchive, delete.

The record-progress menu action belongs to the phase-2 simplified-record flow and is intentionally absent here so the new Goals page does not expose the old multi-purpose record sheet.

Close the menu before executing actions. Delete uses the existing destructive confirmation copy and must delete only after explicit confirmation.

- [x] **Step 6: Replace old Goals-all tests and journeys**

- Replace long-press steps with taps on `goalOverflow-<id>`.
- Assert archive preserves check-ins and milestones.
- Assert unarchive restores the goal to its previous active/paused/achieved lifecycle state.
- Assert reopen clears `achievedAt`.
- Assert the list form never renders `FocusCarousel` or a Today `focusCard-*` key.

- [x] **Step 7: Run view and lifecycle journeys**

Run:

```bash
flutter test test/goals_management_view_test.dart test/app_journeys_test.dart test/goal_detail_redesign_test.dart
```

Expected: PASS.

- [x] **Step 8: Commit the Goals page**

```bash
git add lib/features/goals/goals_view.dart lib/features/goals/goal_list_item.dart lib/features/goals/goal_management_menu.dart lib/features/goals/goals_all_view.dart lib/core/copy.dart test/goals_management_view_test.dart test/app_journeys_test.dart
git commit -m "feat: add compact goal management page"
```

---

### Task 7: Promote Goals to the main dock and remove duplicate creation chrome

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/app/dock_glyphs.dart`
- Modify: `lib/core/copy.dart`
- Modify: `lib/features/today/today_view.dart`
- Modify: `lib/features/profile/profile_hub.dart`
- Modify: `test/navigation_redesign_test.dart`
- Modify: `test/profile_settings_redesign_test.dart`

**Interfaces:**
- Consumes: `GoalsView` from Task 6 and existing Today/Progress branches.
- Produces: three dock destinations `/today`, `/goals`, `/progress`, a `target://goals` deep link, and `/goals-all` compatibility redirect.

- [x] **Step 1: Write failing three-tab navigation tests**

Update `test/navigation_redesign_test.dart`:

```dart
test('deep links recognize goals', () {
  expect(mapDeepLink(Uri.parse('target://goals')), '/goals');
});

testWidgets('dock contains Today Goals and Progress without a center FAB', (
  tester,
) async {
  final db = await _pumpTarget(tester);
  expect(find.byKey(const ValueKey('navTab-/today')), findsOneWidget);
  expect(find.byKey(const ValueKey('navTab-/goals')), findsOneWidget);
  expect(find.byKey(const ValueKey('navTab-/progress')), findsOneWidget);
  expect(find.byKey(const ValueKey('dockFab')), findsNothing);
  await _disposeTarget(tester, db);
});
```

Add a tab-state test that enters Goals, opens and returns from edit/detail, and verifies the selected tab remains Goals.

- [x] **Step 2: Run navigation tests and verify failure**

Run:

```bash
flutter test test/navigation_redesign_test.dart
```

Expected: FAIL because `/goals` and the three-slot dock do not exist.

- [x] **Step 3: Rebuild the route tree**

- Add a shell branch at `/goals` rendering `GoalsView`.
- Move `/goal-editor` and `/goal/:id` to root push routes so Today and Goals can open the same pages without switching shell branches.
- Redirect `/goals-all` to `/goals`.
- Map `target://goals` to `/goals`.
- Preserve `/today`, `/progress`, and existing invalid-goal fallback behavior.

- [x] **Step 4: Replace the dock with three equal destinations**

Use `_navDests = [today, goals, progress]`. Remove `_DockFab`, its overhang math, and its tooltip. Add a Goals glyph using the existing custom-painter style or a semantically equivalent compact flag/list painter in `dock_glyphs.dart`.

Keep:

- minimum 44dp tab hit areas;
- safe-area behavior;
- selected label plus short underline;
- existing fade-through branch transition.

Update geometry assertions to the new non-overhanging three-tab dock instead of preserving obsolete FAB measurements.

- [x] **Step 5: Route temporary duplicate links to the new tab**

Until phase 2 removes Today “查看全部”, route it with `context.go('/goals')` rather than pushing a duplicate page. Until phase 3 removes Profile goal-management/new-goal rows, route goal management to `/goals` and new goal to the root `/goal-editor`.

- [x] **Step 6: Run navigation, profile, and accessibility tests**

Run:

```bash
flutter test test/navigation_redesign_test.dart test/profile_settings_redesign_test.dart test/responsive_accessibility_test.dart
```

Expected: PASS at 320/375/430 widths, light/dark themes, and bottom safe-area variants.

- [x] **Step 7: Commit navigation**

```bash
git add lib/app/router.dart lib/app/dock_glyphs.dart lib/core/copy.dart lib/features/today/today_view.dart lib/features/profile/profile_hub.dart test/navigation_redesign_test.dart test/profile_settings_redesign_test.dart test/responsive_accessibility_test.dart
git commit -m "feat: promote goals to primary navigation"
```

---

### Task 8: Close compatibility gaps and verify phase 1

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/core/models/goal_progress.dart`
- Modify: `lib/core/stats/stats_engine.dart`
- Modify: `lib/core/platform/widgets/widget_checkin.dart`
- Modify: `lib/core/platform/widgets/widget_snapshot.dart`
- Modify: `lib/features/today/today_view.dart`
- Modify: `lib/features/today/focus_carousel.dart`
- Modify: `lib/features/goals/goal_detail.dart`
- Modify: `lib/features/settings/reminder_service.dart`
- Modify: `lib/features/settings/settings_view.dart`
- Modify: `lib/features/notifications/notification_list.dart`
- Modify: `lib/features/profile/profile_hub.dart`
- Modify: `test/app_journeys_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

**Interfaces:**
- Consumes: all Task 1–7 interfaces.
- Produces: a green analyzer/test/build gate and a documented phase-1 user journey.

- [x] **Step 1: Add one end-to-end unified-goal journey**

Add to `test/app_journeys_test.dart`:

```dart
testWidgets('create combined goal then manage lifecycle from Goals tab', (
  tester,
) async {
  final app = await _pumpApp(tester);
  await tester.tap(find.byKey(const ValueKey('navTab-/goals')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('goalsNewButton')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey('goalNameField')),
    '21 天跑步计划',
  );
  await tester.tap(find.byKey(const ValueKey('goalHasDateSwitch')));
  await tester.tap(find.byKey(const ValueKey('goalTargetDateField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('30'));
  await tester.tap(find.text('确定'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('goalFrequencyField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('每周若干次'));
  await tester.tap(find.byKey(const ValueKey('weeklyCount-3')));
  await tester.pumpAndSettle();

  for (final title in ['坚持 7 天', '坚持 21 天']) {
    await tester.enterText(
      find.byKey(const ValueKey('milestoneDraftInput')),
      title,
    );
    await tester.tap(find.byKey(const ValueKey('milestoneDraftAdd')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('goalReminderSwitch')));
  await tester.tap(find.byKey(const ValueKey('goalSaveButton')));
  await tester.pumpAndSettle();

  final goal = (await GoalRepository(app.db).getGoals()).singleWhere(
    (g) => g.name == '21 天跑步计划',
  );
  final plan = await app.container.read(goalPlanRepoProvider).load(goal.id);
  expect(goal.targetDate, const LocalDate(2026, 8, 30));
  expect(goal.frequency, const WeeklyFrequency(3));
  expect(plan!.milestones.map((m) => m.title), ['坚持 7 天', '坚持 21 天']);
  expect(plan.reminder!.isEnabled, isTrue);

  await tester.tap(find.byKey(const ValueKey('pageTopBarBack')));
  await tester.pumpAndSettle();
  expect(find.byKey(ValueKey('goalListRow-${goal.id}')), findsOneWidget);
  expect(find.textContaining('当前：坚持 7 天'), findsOneWidget);

  Future<void> action(String name) async {
    await tester.tap(find.byKey(ValueKey('goalOverflow-${goal.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('goalAction-$name-${goal.id}')));
    await tester.pumpAndSettle();
  }

  await action('pause');
  expect((await _goalById(app.db, goal.id))!.status, GoalStatus.paused);
  await action('resume');
  expect((await _goalById(app.db, goal.id))!.status, GoalStatus.active);
  await action('achieve');
  expect((await _goalById(app.db, goal.id))!.status, GoalStatus.achieved);
  await action('reopen');
  expect((await _goalById(app.db, goal.id))!.status, GoalStatus.active);
  await action('archive');
  expect((await _goalById(app.db, goal.id))!.isArchived, isTrue);

  await tester.tap(find.byKey(const ValueKey('goalFilter-archived')));
  await tester.pumpAndSettle();
  await action('unarchive');
  final restored = await app.container.read(goalPlanRepoProvider).load(goal.id);
  expect(restored!.goal.isArchived, isFalse);
  expect(restored.milestones.map((m) => m.title), ['坚持 7 天', '坚持 21 天']);
  expect(restored.reminder!.isEnabled, isTrue);
});
```

- [x] **Step 2: Run the focused phase-1 regression set**

Run:

```bash
flutter test test/migration_test.dart test/backup_test.dart test/goal_lifecycle_v7_test.dart test/goal_plan_repository_test.dart test/goal_editor_test.dart test/goals_management_view_test.dart test/navigation_redesign_test.dart test/app_journeys_test.dart
```

Expected: PASS.

- [x] **Step 3: Run static analysis and fix only phase-related diagnostics**

Run:

```bash
flutter analyze
```

Expected: no diagnostics. Remove dead template imports, obsolete focus-limit catches, old Goals-all imports, and unused type-form copy. Replace product-semantic `status == GoalStatus.active` checks with `goal.isActive` so archived goals stay out of Today, scoring, widgets, reminders, notifications, Profile counts, and Settings counts while their underlying lifecycle status remains recoverable. Do not refactor unrelated files.

- [x] **Step 4: Run the complete test suite**

Run:

```bash
flutter test --reporter expanded
```

Expected: all tests pass. Any legacy test that asserts a removed product behavior must be rewritten to assert the new behavior, not deleted without replacement.

- [x] **Step 5: Build the web verification surface**

Run:

```bash
flutter build web --release
```

Expected: build succeeds and creates `build/web`.

- [ ] **Step 6: Perform a manual smoke pass**

Using the web build or a connected device, verify:

1. Old v6 data opens with names, dates, milestones, records, categories, and reminders intact.
2. A goal can be created with name only.
3. A goal can combine date, weekly frequency, milestones, and reminder.
4. Goals rows are compact and use visible overflow controls.
5. Archive/unarchive preserves history; delete requires confirmation.
6. Today, detail, and Progress still render newly created unified goals without crashing.

- [x] **Step 7: Update README navigation and data-model notes**

Document the three primary tabs, unified optional goal settings, schema v7 migration, and backup version 6. Do not describe phase-2 or phase-3 UI as already implemented.

- [x] **Step 8: Commit phase-1 closure**

```bash
git add README.md lib test
git commit -m "test: close unified goal management phase"
```

## Phase-1 Acceptance Criteria

1. The user can create a goal with only a name or any combination of date, frequency, milestones, category, and reminder.
2. No new/edit UI displays long-term, short-term, habit, template, or progress-cadence controls.
3. More than five active goals can be stored.
4. Goals is a primary dock tab with compact rows and a visible overflow action on every row.
5. Active, paused, achieved, and archived filters and lifecycle actions persist correctly.
6. Archive/unarchive is reversible and preserves all child data; delete remains confirmed and destructive.
7. v1–v6 databases and backup versions 1–5 import without data loss; backup version 6 round-trips new fields.
8. Existing Today, detail, and Progress screens continue to render during the compatibility phase.
9. `flutter analyze`, the full `flutter test` suite, and `flutter build web --release` pass.

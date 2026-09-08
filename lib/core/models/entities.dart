/// v3 领域实体（specs/006-app-v3-redesign/data-model.md · schema v8）。
///
/// 纯 Dart、无 Flutter/平台依赖；业务规则（状态机、置顶、达成流）
/// 落在本层，drift 持久化层只做字段映射不添加规则。
/// Instant 一律存 UTC DateTime；自然日/周锚点用 LocalDate/WeekStart。
/// 006 裁定：存量不迁移（清库重建），无任何 legacy 兼容字段。
library;

import 'dart:math';

import 'calendar_types.dart';
import 'frequency_pattern.dart';
import 'goal_icon_catalog.dart' show GoalIconDomain;

/// 生成 UUID v4（实体主键）。无 uuid 依赖，Random.secure 足够。
String newId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-'
      '${h(4)}${h(5)}-${h(6)}${h(7)}-${h(8)}${h(9)}-'
      '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

// ---------------------------------------------------------------------------
// 枚举
// ---------------------------------------------------------------------------

/// 目标状态机（phase 1 语义延续；archivedAt 与 archived 状态绑定）。
enum GoalStatus { active, paused, achieved, archived }

/// 提醒频率档（一天/三天/一周一次；沿 phase 1 值域）。
enum Cadence { daily, threeDay, weekly }

/// 进展记录类型：普通记录 / 里程碑达成事件（FR-003）。
enum RecordKind { normal, milestoneAchievement }

/// v3 分类目录（11 键；展示名与默认色见 copy.dart / CategoryCatalog）。
enum GoalCategory {
  fitness,
  learning,
  language,
  create,
  travel,
  finance,
  life,
  mind,
  social,
  pets,
  other,
}

/// 分类目录元数据：默认色键（--palette-*）与图标域建议。
extension GoalCategoryX on GoalCategory {
  /// 分类默认色（iOS 系统色板键；data-model.md §4）。
  String get defaultColorKey => switch (this) {
    GoalCategory.fitness => 'blue',
    GoalCategory.learning => 'orange',
    GoalCategory.language => 'green',
    GoalCategory.create => 'purple',
    GoalCategory.travel => 'teal',
    GoalCategory.finance => 'teal',
    GoalCategory.life => 'indigo',
    GoalCategory.mind => 'indigo',
    GoalCategory.social => 'pink',
    GoalCategory.pets => 'orange',
    GoalCategory.other => 'gray',
  };

  /// 分类默认图标（GoalIconCatalog 键；编辑器默认联动，手动改过则不覆盖）。
  String get defaultIconKey => switch (this) {
    GoalCategory.fitness => 'directions_run',
    GoalCategory.learning => 'menu_book',
    GoalCategory.language => 'translate',
    GoalCategory.create => 'brush',
    GoalCategory.travel => 'flight',
    GoalCategory.finance => 'savings',
    GoalCategory.life => 'home',
    GoalCategory.mind => 'self_improvement',
    GoalCategory.social => 'groups',
    GoalCategory.pets => 'pets',
    GoalCategory.other => 'explore',
  };

  /// 图标域 → 分类建议（不静默决定，仅编辑器默认值；2026-08-26 §10 边界）。
  static GoalCategory suggestFor(GoalIconDomain domain) => switch (domain) {
    GoalIconDomain.fitness || GoalIconDomain.health => GoalCategory.fitness,
    GoalIconDomain.learning => GoalCategory.learning,
    GoalIconDomain.create => GoalCategory.create,
    GoalIconDomain.travel => GoalCategory.travel,
    GoalIconDomain.finance => GoalCategory.finance,
    GoalIconDomain.life => GoalCategory.life,
    GoalIconDomain.mind => GoalCategory.mind,
    GoalIconDomain.social => GoalCategory.social,
    GoalIconDomain.pets => GoalCategory.pets,
  };
}

/// copyWith 可空字段哨兵（区分「未传」与「显式置 null」）。
const Object _sentinel = Object();

// ---------------------------------------------------------------------------
// Goal
// ---------------------------------------------------------------------------

/// 目标：名称唯一必填；日期/节奏/里程碑/提醒/置顶全部可选、互不排斥。
class Goal {
  Goal({
    String? id,
    required this.name,
    this.why,
    this.categoryKey,
    this.iconKey = 'target',
    String? colorKey,
    this.pinned = false,
    this.pinnedOrder,
    this.targetDate,
    this.frequency,
    this.status = GoalStatus.active,
    this.achievedAt,
    this.archivedAt,
    required this.createdAt,
  }) : id = id ?? newId(),
       colorKey = colorKey ?? _categoryColorOf(categoryKey),
       assert(name.trim().isNotEmpty && name.length <= 40, '目标名 1–40 字'),
       assert(
         why == null || (why.trim().isNotEmpty && why.length <= 60),
         '为什么 1–60 字',
       ),
       assert(
         pinnedOrder == null || pinnedOrder >= 0,
         '置顶序号 ≥0',
       );

  static String _categoryColorOf(GoalCategory? key) => key?.defaultColorKey ?? 'gray';

  final String id;
  final String name;

  /// 为什么想做（R1 Figma：可选 ≤60 字）。
  final String? why;

  /// 分类键（NULL=未分类）；展示名走 copy.dart。
  final GoalCategory? categoryKey;

  /// 图标键（38 枚目录，goal_icon_catalog.dart）。
  final String iconKey;

  /// 颜色键（iOS 8 色板 + gray；默认=分类默认色）。
  final String colorKey;

  /// 置顶（FR-004）：置顶目标出现在目标页置顶分组。
  final bool pinned;

  /// 置顶组内排序（仅置顶目标有值；编辑置顶模式拖拽写入）。
  final int? pinnedOrder;

  /// 目标日期（可选）。
  final LocalDate? targetDate;

  /// 执行节奏（可选；编码见 frequency_pattern.dart）。
  final FrequencyPattern? frequency;

  final GoalStatus status;

  /// 手动「标记达成」时刻（UTC；NULL=未达成）。
  final DateTime? achievedAt;

  /// 归档时刻（UTC）；归档目标从默认视图/记录选择器隐去。
  final DateTime? archivedAt;

  final LocalDate createdAt;

  Goal copyWith({
    String? name,
    Object? why = _sentinel,
    Object? categoryKey = _sentinel,
    String? iconKey,
    String? colorKey,
    bool? pinned,
    Object? pinnedOrder = _sentinel,
    Object? targetDate = _sentinel,
    Object? frequency = _sentinel,
    GoalStatus? status,
    Object? achievedAt = _sentinel,
    Object? archivedAt = _sentinel,
  }) => Goal(
    id: id,
    name: name ?? this.name,
    why: why == _sentinel ? this.why : why as String?,
    categoryKey: categoryKey == _sentinel
        ? this.categoryKey
        : categoryKey as GoalCategory?,
    iconKey: iconKey ?? this.iconKey,
    colorKey: colorKey ?? this.colorKey,
    pinned: pinned ?? this.pinned,
    pinnedOrder: pinnedOrder == _sentinel
        ? this.pinnedOrder
        : pinnedOrder as int?,
    targetDate: targetDate == _sentinel
        ? this.targetDate
        : targetDate as LocalDate?,
    frequency: frequency == _sentinel
        ? this.frequency
        : frequency as FrequencyPattern?,
    status: status ?? this.status,
    achievedAt: achievedAt == _sentinel
        ? this.achievedAt
        : achievedAt as DateTime?,
    archivedAt: archivedAt == _sentinel
        ? this.archivedAt
        : archivedAt as DateTime?,
    createdAt: createdAt,
  );

  /// 状态机（phase 1 语义）：active⇄paused、标记达成⇄重新打开、
  /// 归档⇄取消归档；删除为独立破坏性操作不入状态机。
  bool canTransitTo(GoalStatus to) => switch (status) {
    GoalStatus.active => to == GoalStatus.paused ||
          to == GoalStatus.achieved ||
          to == GoalStatus.archived,
    GoalStatus.paused => to == GoalStatus.active ||
          to == GoalStatus.achieved ||
          to == GoalStatus.archived,
    GoalStatus.achieved => to == GoalStatus.active ||
          to == GoalStatus.archived,
    GoalStatus.archived => to == GoalStatus.active,
  };

  @override
  bool operator ==(Object other) => other is Goal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Milestone
// ---------------------------------------------------------------------------

/// 里程碑：第一条未达成 = 「下个路标」；达成即生成达成记录（FR-003）。
class Milestone {
  Milestone({
    String? id,
    required this.goalId,
    required this.title,
    this.description,
    required this.position,
    this.isDone = false,
    this.doneAt,
  }) : id = id ?? newId(),
       assert(title.trim().isNotEmpty && title.length <= 40, '里程碑名 1–40 字'),
       assert(
         description == null ||
             (description.trim().isNotEmpty && description.length <= 60),
         '达成描述 1–60 字',
       );

  final String id;
  final String goalId;
  final String title;

  /// 「达成时是什么样」（R1 Figma；可选 ≤60 字）。
  final String? description;
  final int position;
  final bool isDone;

  /// 达成时刻（UTC）；达成时同事务生成 kind=milestoneAchievement 记录。
  final DateTime? doneAt;

  Milestone copyWith({
    String? title,
    Object? description = _sentinel,
    int? position,
    bool? isDone,
    Object? doneAt = _sentinel,
  }) => Milestone(
    id: id,
    goalId: goalId,
    title: title ?? this.title,
    description: description == _sentinel
        ? this.description
        : description as String?,
    position: position ?? this.position,
    isDone: isDone ?? this.isDone,
    doneAt: doneAt == _sentinel ? this.doneAt : doneAt as DateTime?,
  );

  @override
  bool operator ==(Object other) => other is Milestone && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// ProgressRecord
// ---------------------------------------------------------------------------

/// 富进展记录（FR-002）：标题必填 + 正文（唯一心得字段）+ 可选时长/
/// 里程碑关联；day 可选过去（isBackfill=补记）。
class ProgressRecord {
  ProgressRecord({
    String? id,
    required this.goalId,
    required this.title,
    this.body,
    this.durationMinutes,
    required this.day,
    required this.createdAt,
    bool? isBackfill,
    this.kind = RecordKind.normal,
    this.milestoneId,
  }) : id = id ?? newId(),
       isBackfill = isBackfill ?? false,
       assert(title.trim().isNotEmpty && title.length <= 40, '标题 1–40 字'),
       assert(
         body == null || (body.trim().isNotEmpty && body.length <= 500),
         '正文 1–500 字',
       ),
       assert(
         durationMinutes == null || (durationMinutes > 0 && durationMinutes <= 24 * 60),
         '投入时长 1–1440 分钟',
       );

  final String id;
  final String goalId;
  final String title;
  final String? body;
  final int? durationMinutes;
  final LocalDate day;
  final DateTime createdAt;

  /// 补记：day 早于创建当日（仓库写入时自动判定）。
  final bool isBackfill;
  final RecordKind kind;

  /// 关联里程碑（普通记录可选关联；达成记录指向达成的里程碑）。
  final String? milestoneId;

  ProgressRecord copyWith({
    String? title,
    Object? body = _sentinel,
    Object? durationMinutes = _sentinel,
  }) => ProgressRecord(
    id: id,
    goalId: goalId,
    title: title ?? this.title,
    body: body == _sentinel ? this.body : body as String?,
    durationMinutes: durationMinutes == _sentinel
        ? this.durationMinutes
        : durationMinutes as int?,
    day: day,
    createdAt: createdAt,
    isBackfill: isBackfill,
    kind: kind,
    milestoneId: milestoneId,
  );

  @override
  bool operator ==(Object other) => other is ProgressRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Reminder / Settings
// ---------------------------------------------------------------------------

class Reminder {
  Reminder({
    String? id,
    required this.goalId,
    required this.time,
    this.isEnabled = false,
    this.cadence = Cadence.daily,
  }) : id = id ?? newId();

  final String id;
  final String goalId;
  final LocalTime time;
  final bool isEnabled;

  /// 频率档：一天/三天/一周一次（NULL 视为 daily 的旧语义不再存在）。
  final Cadence cadence;

  Reminder copyWith({LocalTime? time, bool? isEnabled, Cadence? cadence}) =>
      Reminder(
        id: id,
        goalId: goalId,
        time: time ?? this.time,
        isEnabled: isEnabled ?? this.isEnabled,
        cadence: cadence ?? this.cadence,
      );

  @override
  bool operator ==(Object other) => other is Reminder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 全局设置（单例行）：资料 + 外观 + 提醒总开关。
class AppSettings {
  const AppSettings({
    this.nickname,
    this.avatarKey,
    this.themeMode,
    this.remindersEnabled = true,
  });

  final String? nickname;
  final String? avatarKey;

  /// system|light|dark；NULL=跟随系统（004 D2 语义）。
  final String? themeMode;
  final bool remindersEnabled;

  AppSettings copyWith({
    Object? nickname = _s,
    Object? avatarKey = _s,
    Object? themeMode = _s,
    bool? remindersEnabled,
  }) => AppSettings(
    nickname: nickname == _s ? this.nickname : nickname as String?,
    avatarKey: avatarKey == _s ? this.avatarKey : avatarKey as String?,
    themeMode: themeMode == _s ? this.themeMode : themeMode as String?,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
  );

  static const _s = Object();
}

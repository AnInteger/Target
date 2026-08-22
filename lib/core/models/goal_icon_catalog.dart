/// GoalIconCatalog · 目标图标库（003 · research D1）。
///
/// 字形源：Flutter 内置 Material Icons 的 rounded 变体（源出
/// Material Symbols Rounded，Apache 2.0）——与原型侧
/// `design/prototypes/goal-icons.js` 同源同形，键名一一对应
/// （[GoalIconCatalogTest] 做两侧对账）。零新增依赖。
///
/// [GoalIconCatalog.key] 即持久化的 iconKey 值域（snake_case，
/// 与 JS 侧字面一致）；旧 v2 值域（`GoalIcon` 12 键，见
/// lib/app/design_tokens.dart）经 [legacyIconKeyMap] 一次性迁移。
library;

import 'package:flutter/material.dart';

/// 图标领域（≥9 类，research D1 策展；中文名与 JS 侧 GOAL_ICON_DOMAINS 一致）。
enum GoalIconDomain {
  fitness('运动'),
  learning('学习'),
  health('健康'),
  create('创作'),
  travel('旅行'),
  finance('理财'),
  life('生活'),
  mind('冥想'),
  social('社交'),
  pets('宠物');

  const GoalIconDomain(this.zhLabel);

  final String zhLabel;
}

/// 目标图标目录（39 枚 / 10 领域）。
enum GoalIconCatalog {
  directionsBike('directions_bike', GoalIconDomain.fitness,
      Icons.directions_bike_rounded),
  directionsRun('directions_run', GoalIconDomain.fitness,
      Icons.directions_run_rounded),
  pool('pool', GoalIconDomain.fitness, Icons.pool_rounded),
  hiking('hiking', GoalIconDomain.fitness, Icons.hiking_rounded),
  fitnessCenter('fitness_center', GoalIconDomain.fitness,
      Icons.fitness_center_rounded),

  menuBook('menu_book', GoalIconDomain.learning, Icons.menu_book_rounded),
  school('school', GoalIconDomain.learning, Icons.school_rounded),
  translate('translate', GoalIconDomain.learning, Icons.translate_rounded),
  autoStories('auto_stories', GoalIconDomain.learning,
      Icons.auto_stories_rounded),

  favorite('favorite', GoalIconDomain.health, Icons.favorite_rounded),
  monitorHeart('monitor_heart', GoalIconDomain.health,
      Icons.monitor_heart_rounded),
  bedtime('bedtime', GoalIconDomain.health, Icons.bedtime_rounded),
  waterDrop('water_drop', GoalIconDomain.health, Icons.water_drop_rounded),

  brush('brush', GoalIconDomain.create, Icons.brush_rounded),
  camera('camera', GoalIconDomain.create, Icons.camera_rounded),
  palette('palette', GoalIconDomain.create, Icons.palette_rounded),
  musicNote('music_note', GoalIconDomain.create, Icons.music_note_rounded),

  flight('flight', GoalIconDomain.travel, Icons.flight_rounded),
  luggage('luggage', GoalIconDomain.travel, Icons.luggage_rounded),
  map('map', GoalIconDomain.travel, Icons.map_rounded),
  cabin('cabin', GoalIconDomain.travel, Icons.cabin_rounded),
  explore('explore', GoalIconDomain.travel, Icons.explore_rounded),

  savings('savings', GoalIconDomain.finance, Icons.savings_rounded),
  trendingUp('trending_up', GoalIconDomain.finance,
      Icons.trending_up_rounded),
  accountBalanceWallet('account_balance_wallet', GoalIconDomain.finance,
      Icons.account_balance_wallet_rounded),
  paid('paid', GoalIconDomain.finance, Icons.paid_rounded),

  home('home', GoalIconDomain.life, Icons.home_rounded),
  restaurant('restaurant', GoalIconDomain.life, Icons.restaurant_rounded),
  cleaningServices('cleaning_services', GoalIconDomain.life,
      Icons.cleaning_services_rounded),
  eco('eco', GoalIconDomain.life, Icons.eco_rounded),

  selfImprovement('self_improvement', GoalIconDomain.mind,
      Icons.self_improvement_rounded),
  spa('spa', GoalIconDomain.mind, Icons.spa_rounded),
  air('air', GoalIconDomain.mind, Icons.air_rounded),
  forest('forest', GoalIconDomain.mind, Icons.forest_rounded),

  groups('groups', GoalIconDomain.social, Icons.groups_rounded),
  volunteerActivism('volunteer_activism', GoalIconDomain.social,
      Icons.volunteer_activism_rounded),
  forum('forum', GoalIconDomain.social, Icons.forum_rounded),

  pets('pets', GoalIconDomain.pets, Icons.pets_rounded);

  const GoalIconCatalog(this.key, this.domain, this.icon);

  /// 持久化键（snake_case，与 design/prototypes/goal-icons.js 字面一致）。
  final String key;

  final GoalIconDomain domain;
  final IconData icon;

  /// 按持久化键取图标；未知键兜底 [explore]（探索 = 自定义目标语义）。
  static GoalIconCatalog byKey(String? key) => GoalIconCatalog.values
      .firstWhere((i) => i.key == key, orElse: () => GoalIconCatalog.explore);

  /// 按领域分组（编辑器九宫格消费）。
  static Map<GoalIconDomain, List<GoalIconCatalog>> get byDomain {
    final map = <GoalIconDomain, List<GoalIconCatalog>>{};
    for (final i in GoalIconCatalog.values) {
      map.putIfAbsent(i.domain, () => []).add(i);
    }
    return map;
  }
}

/// 旧 v2 iconKey（`GoalIcon` 12 键，outlined 变体）→ 新键迁移映射
/// （schema v3 一次性换域，research D3；迁移测试对账用）。
const Map<String, String> legacyIconKeyMap = {
  'meal': 'restaurant',
  'fitness': 'directions_run',
  'sleep': 'bedtime',
  'screenRest': 'air', // 屏幕休息 → 放空（冥想域）
  'project': 'brush', // 个人项目 → 创作
  'travel': 'flight',
  'read': 'menu_book',
  'water': 'water_drop',
  'meditate': 'self_improvement',
  'health': 'favorite',
  'family': 'groups',
  'star': 'explore', // 自定义兜底 → 探索
};

/// 迁移单个旧键：已知映射换域，未知键兜底 explore。
String migrateIconKey(String? legacy) =>
    legacy == null ? GoalIconCatalog.explore.key
        : legacyIconKeyMap[legacy] ?? GoalIconCatalog.explore.key;

/// 003 T013 夹具：FrequencyVersions 停写后，测试用直插还原「存量行」
/// （仿真 v2 旧库迁移形态；仓储写入 API 已删除，App 路径不再产生新行）。
library;

import 'package:target/core/db/app_database.dart' as db;
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';

Future<void> seedVersion(
  db.AppDatabase database,
  String goalId,
  FrequencyPattern pattern,
  WeekStart week, [
  FrequencySource source = FrequencySource.initial,
]) =>
    database.into(database.frequencyVersions).insert(
          db.FrequencyVersionsCompanion.insert(
            id: newId(),
            goalId: goalId,
            effectiveFromWeek: week,
            pattern: pattern,
            source: source,
          ),
        );

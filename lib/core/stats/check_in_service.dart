/// CheckInService（T025，FR-004）：打卡/补签/撤销的统一入口。
///
/// UI 不直接碰仓储——经此服务拿注入时钟的"今天/现在"，
/// 保证 23:59/00:01 归属（R1）与 isBackfill 判定（实体构造不变量）一致。
library;

import '../models/calendar_types.dart';
import '../models/date_provider.dart';
import '../models/entities.dart';
import '../db/repositories.dart';

class CheckInService {
  CheckInService(this._repo, this._clock);

  final CheckInRepository _repo;
  final DateProvider _clock;

  /// 今日打卡 +1（目标未达标时由 UI/小组件侧把关）；note = 选填
  /// 一句话描述（FR-019）。
  Future<CheckIn> checkInToday(String goalId, {String? note}) =>
      _repo.add(goalId, _clock.today, _clock.now(), note: note);

  /// 补签任意过去日期（day < 今天；isBackfill 自动标记）。
  Future<CheckIn> backfill(String goalId, LocalDate day) {
    assert(day.isBefore(_clock.today), '只能补签过去的日期');
    return _repo.add(goalId, day, _clock.now());
  }

  /// 撤销（置 revoked 不物理删除，统计即时回退 R7）。
  Future<void> undo(String checkInId) => _repo.revoke(checkInId);
}

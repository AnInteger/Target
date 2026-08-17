/// 内联撤销 toast（T027，FR-004）：打卡/补签后可一键撤销。
///
/// 撤销 = revoke（不物理删除），统计经 Riverpod 流即时回退（R7）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';

void showCheckInToast(BuildContext context, WidgetRef ref, CheckIn checkIn) {
  final messenger = ScaffoldMessenger.of(context);
  final label = checkIn.isBackfill
      ? Copy.backfillDone(checkIn.day.isoString)
      : Copy.checkInDone;
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(label),
      action: SnackBarAction(
        label: Copy.undoCheckIn,
        onPressed: () async {
          await ref.read(checkInServiceProvider).undo(checkIn.id);
          messenger.showSnackBar(
              const SnackBar(content: Text(Copy.checkInRevoked)));
        },
      ),
    ));
}

/// 记录节点图标（详情时间线 / 动态 feed 共用）。
///
/// 多样化优先级：里程碑达成（实旗）> 关联里程碑（旗）> 有时长（时钟）
/// > 有心得（文档）> 默认（铅笔）。
library;

import 'package:flutter/cupertino.dart';

IconData recordNodeIcon({
  required bool milestone,
  bool linkedMilestone = false,
  bool hasDuration = false,
  bool hasBody = false,
}) {
  if (milestone) return CupertinoIcons.flag_fill;
  if (linkedMilestone) return CupertinoIcons.flag;
  if (hasDuration) return CupertinoIcons.clock;
  if (hasBody) return CupertinoIcons.doc_text;
  return CupertinoIcons.square_pencil;
}

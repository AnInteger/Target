library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_plan.dart';

class GoalReminderField extends StatelessWidget {
  const GoalReminderField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReminderDraft? value;
  final ValueChanged<ReminderDraft?> onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('goalReminderSwitch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('开启提醒'),
          value: enabled,
          onChanged: (next) {
            onChanged(
              next
                  ? const ReminderDraft(
                      enabled: true,
                      time: LocalTime(9, 0),
                      cadence: Cadence.daily,
                    )
                  : null,
            );
          },
        ),
        if (enabled) ...[
          const SizedBox(height: AppSpace.s2),
          SegmentedButton<Cadence>(
            segments: const [
              ButtonSegment(value: Cadence.daily, label: Text('每天')),
              ButtonSegment(value: Cadence.threeDay, label: Text('隔三天')),
              ButtonSegment(value: Cadence.weekly, label: Text('每周')),
            ],
            selected: {value!.cadence},
            onSelectionChanged: (selection) {
              onChanged(
                ReminderDraft(
                  id: value!.id,
                  enabled: true,
                  time: value!.time,
                  cadence: selection.single,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.s2),
          InkWell(
            key: const ValueKey('goalReminderTimeField'),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: value!.time.hour,
                  minute: value!.time.minute,
                ),
              );
              if (picked == null) return;
              onChanged(
                ReminderDraft(
                  id: value!.id,
                  enabled: true,
                  time: LocalTime(picked.hour, picked.minute),
                  cadence: value!.cadence,
                ),
              );
            },
            borderRadius: AppRadius.rMd,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
              decoration: BoxDecoration(
                color: TargetPalette.of(context).surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Text('提醒时间 ${value!.time.isoString}'),
            ),
          ),
        ],
      ],
    );
  }
}

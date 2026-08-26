library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/frequency_pattern.dart';

class GoalFrequencyField extends StatelessWidget {
  const GoalFrequencyField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FrequencyPattern? value;
  final ValueChanged<FrequencyPattern?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return InkWell(
      key: const ValueKey('goalFrequencyField'),
      onTap: () => _pick(context),
      borderRadius: AppRadius.rMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s3,
          vertical: AppSpace.s2,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: AppRadius.rMd,
        ),
        child: Row(
          children: [
            Expanded(child: Text(_labelOf(value))),
            Icon(Icons.expand_more_rounded, color: palette.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<_FrequencyChoice>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FrequencySheet(value: value),
    );
    if (picked != null) {
      onChanged(picked.value);
    }
  }

  static String _labelOf(FrequencyPattern? pattern) => switch (pattern) {
    null => '不设置',
    DailyFrequency(:final targetPerDay) => targetPerDay == 1
        ? '每天'
        : '每天 $targetPerDay 次',
    WeeklyFrequency(:final timesPerWeek) => '每周 $timesPerWeek 次',
    WeekdaysFrequency(:final days) =>
      days.map((day) => '周${day.zhLabel}').join('、'),
  };
}

class _FrequencyChoice {
  const _FrequencyChoice(this.value);

  final FrequencyPattern? value;
}

class _FrequencySheet extends StatefulWidget {
  const _FrequencySheet({required this.value});

  final FrequencyPattern? value;

  @override
  State<_FrequencySheet> createState() => _FrequencySheetState();
}

class _FrequencySheetState extends State<_FrequencySheet> {
  late Set<Weekday> _weekdays = widget.value is WeekdaysFrequency
      ? {...(widget.value as WeekdaysFrequency).days}
      : {Weekday.mon, Weekday.wed, Weekday.fri};

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Material(
      color: palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s5,
        AppSpace.s4,
        AppSpace.s5,
        AppSpace.s5 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OptionTile(
            label: '不设置',
            onTap: () => Navigator.of(context).pop(const _FrequencyChoice(null)),
          ),
          _OptionTile(
            label: '每天',
            onTap: () => Navigator.of(context).pop(
              const _FrequencyChoice(DailyFrequency(1)),
            ),
          ),
          _OptionTile(label: '每周若干次', onTap: () {}),
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              for (var count = 1; count <= 7; count++)
                ActionChip(
                  key: ValueKey('weeklyCount-$count'),
                  label: Text('$count'),
                  onPressed: () => Navigator.of(context).pop(
                    _FrequencyChoice(WeeklyFrequency(count)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Text('指定星期', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpace.s2),
          Wrap(
            spacing: AppSpace.s2,
            children: [
              for (final day in Weekday.values)
                FilterChip(
                  label: Text('周${day.zhLabel}'),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _weekdays.add(day);
                      } else if (_weekdays.length > 1) {
                        _weekdays.remove(day);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _FrequencyChoice(WeekdaysFrequency(_weekdays, 1)),
            ),
            child: const Text('确定'),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 44,
    title: Text(label),
    onTap: onTap,
  );
}

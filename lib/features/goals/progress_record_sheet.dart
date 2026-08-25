library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/models/entities.dart';
import '../../core/models/progress_record.dart';

Future<bool?> showProgressRecordSheet(
  BuildContext context, {
  required Goal goal,
  required MilestoneStep? currentStep,
}) {
  final palette = TargetPalette.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: palette.scrim,
    builder: (_) => _ProgressRecordSheet(goal: goal, currentStep: currentStep),
  );
}

class _ProgressRecordSheet extends ConsumerStatefulWidget {
  const _ProgressRecordSheet({required this.goal, required this.currentStep});

  final Goal goal;
  final MilestoneStep? currentStep;

  @override
  ConsumerState<_ProgressRecordSheet> createState() =>
      _ProgressRecordSheetState();
}

class _ProgressRecordSheetState extends ConsumerState<_ProgressRecordSheet> {
  final _note = TextEditingController();
  final _next = TextEditingController();
  bool _completeCurrent = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final clock = ref.read(dateProviderProvider);
    try {
      await ref
          .read(progressRepoProvider)
          .record(
            ProgressRecordInput(
              goalId: widget.goal.id,
              day: clock.today,
              createdAt: clock.now(),
              note: _note.text,
              completedMilestoneId: _completeCurrent
                  ? widget.currentStep?.id
                  : null,
              nextMilestoneTitle: _showNextStep ? _next.text : null,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '保存失败，已保留你填写的内容，请重试。';
      });
    }
  }

  bool get _showNextStep => widget.currentStep == null || _completeCurrent;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        key: const ValueKey('progressRecordSheet'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: palette.shadowHigh,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('记录进展', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          widget.goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('这次推进了什么？', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('progressNoteField'),
                controller: _note,
                maxLength: 40,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  context,
                  palette,
                  hint: '例如：完成 DSD 体验潜水',
                ),
              ),
              if (widget.currentStep != null) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () =>
                      setState(() => _completeCurrent = !_completeCurrent),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _completeCurrent,
                          onChanged: (value) =>
                              setState(() => _completeCurrent = value ?? false),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '同时完成当前里程碑',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.currentStep!.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_showNextStep) ...[
                const SizedBox(height: 18),
                Text('下一步计划（选填）', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '留空也可以，目标会进入“需要关注”，提醒你之后确认下一步。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('nextMilestoneField'),
                  controller: _next,
                  maxLength: 50,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    context,
                    palette,
                    hint: '例如：完成理论课程',
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.badge,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.accentOn,
                          ),
                        )
                      : const Text('保存进展'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    TargetPalette palette, {
    required String hint,
  }) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: palette.surfaceAlt,
    counterStyle: Theme.of(context).textTheme.bodyS
        .copyWith(color: palette.onSurfaceVariant),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.accent, width: 1.5),
    ),
  );
}

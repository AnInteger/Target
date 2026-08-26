library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/models/goal_plan.dart';

class GoalMilestoneEditor extends StatefulWidget {
  const GoalMilestoneEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final List<MilestoneDraft> value;
  final ValueChanged<List<MilestoneDraft>> onChanged;

  @override
  State<GoalMilestoneEditor> createState() => _GoalMilestoneEditorState();
}

class _GoalMilestoneEditorState extends State<GoalMilestoneEditor> {
  final _draft = TextEditingController();
  final _controllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant GoalMilestoneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  @override
  void dispose() {
    _draft.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    while (_controllers.length < widget.value.length) {
      _controllers.add(TextEditingController());
    }
    while (_controllers.length > widget.value.length) {
      _controllers.removeLast().dispose();
    }
    for (final (index, milestone) in widget.value.indexed) {
      if (_controllers[index].text != milestone.title) {
        _controllers[index].text = milestone.title;
      }
    }
  }

  void _emit(List<MilestoneDraft> value) {
    widget.onChanged(List.unmodifiable(value));
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('milestoneDraftInput'),
                controller: _draft,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: '添加里程碑...',
                  counterText: '',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpace.s3,
                    vertical: AppSpace.s2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s1),
            IconButton.filled(
              key: const ValueKey('milestoneDraftAdd'),
              onPressed: () {
                final title = _draft.text.trim();
                if (title.isEmpty) return;
                _draft.clear();
                _emit([...widget.value, MilestoneDraft(title: title)]);
              },
              icon: const Icon(Icons.add_rounded),
              tooltip: '添加',
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s1),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.value.length,
          onReorder: (oldIndex, newIndex) {
            final next = [...widget.value];
            final item = next.removeAt(oldIndex);
            next.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
            _emit(next);
          },
          itemBuilder: (context, index) {
            final milestone = widget.value[index];
            return Container(
              key: ValueKey('milestoneDraftRow-${milestone.id ?? index}'),
              constraints: const BoxConstraints(minHeight: 44),
              margin: const EdgeInsets.only(bottom: AppSpace.s1),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.rMd,
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: IconButton(
                      key: ValueKey('milestoneDraftHandle-$index'),
                      onPressed: () {},
                      icon: const Icon(Icons.drag_indicator_rounded),
                      tooltip: '排序',
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      key: ValueKey('milestoneTitleField-$index'),
                      controller: _controllers[index],
                      maxLength: 50,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final next = [...widget.value];
                        next[index] = MilestoneDraft(
                          id: milestone.id,
                          title: value,
                          isDone: milestone.isDone,
                          doneAt: milestone.doneAt,
                        );
                        _emit(next);
                      },
                    ),
                  ),
                  IconButton(
                    key: ValueKey('milestoneRemove-$index'),
                    onPressed: () {
                      final next = [...widget.value]..removeAt(index);
                      _emit(next);
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '删除',
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

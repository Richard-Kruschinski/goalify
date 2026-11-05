import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/task_checklist_item.dart';

/// Edits a task's checklist in place: add with Enter (the field stays open for
/// the next step), drag to reorder, swipe or tap x to remove. Checking items
/// off happens on the task card, not here.
///
/// [items] is mutated directly; [onChanged] fires after every change so the
/// caller can save right away.
class ChecklistEditor extends StatefulWidget {
  const ChecklistEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.autofocus = false,
    this.fillColor,
  });

  final List<TaskChecklistItem> items;
  final VoidCallback onChanged;
  final bool autofocus;

  /// Surface behind rows and the input; defaults to the card color.
  final Color? fillColor;

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => widget.items.add(TaskChecklistItem(text: text)));
    _input.clear();
    _focus.requestFocus();
    widget.onChanged();
  }

  void _remove(TaskChecklistItem item) {
    setState(() => widget.items.remove(item));
    widget.onChanged();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = widget.items.removeAt(oldIndex);
      widget.items.insert(newIndex, item);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fill = widget.fillColor ?? AppColors.card(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.items.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.items.length,
              onReorder: _reorder,
              proxyDecorator: (child, _, _) => Material(
                color: AppColors.raised(context),
                elevation: 0,
                child: child,
              ),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Dismissible(
                  key: ObjectKey(item),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(item),
                  background: Container(
                    color: AppColors.chip(context),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: AppColors.muted(context)),
                  ),
                  child: _row(context, item, index),
                );
              },
            ),
          ),
        if (widget.items.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: _input,
          focusNode: _focus,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _add(),
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 15, color: AppColors.ink(context)),
          decoration: InputDecoration(
            hintText: l10n.addChecklistItemHint,
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            prefixIcon: Icon(Icons.add, size: 18, color: AppColors.muted(context)),
            suffixIcon: _input.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.addChecklistItemHint,
                    onPressed: _add,
                    icon: Icon(Icons.keyboard_return,
                        size: 18, color: AppColors.ink(context)),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, TaskChecklistItem item, int index) {
    // Long steps wrap over several lines instead of being cut off.
    return Container(
      key: ObjectKey(item),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.drag_indicator,
                  size: 18, color: AppColors.faint(context)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                item.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.ink(context),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).deleteItem,
            visualDensity: VisualDensity.compact,
            onPressed: () => _remove(item),
            icon: Icon(Icons.close, size: 18, color: AppColors.faint(context)),
          ),
        ],
      ),
    );
  }
}

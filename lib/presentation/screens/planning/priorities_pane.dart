import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/eisen_task_entity.dart';
import '../../providers/planning_provider.dart';

class PrioritiesPane extends ConsumerWidget {
  const PrioritiesPane({super.key});

  Color _qColor(EisenQuadrant q) {
    switch (q) {
      case EisenQuadrant.q1:
        return const Color(0xFFEF4444);
      case EisenQuadrant.q2:
        return const Color(0xFF10B981);
      case EisenQuadrant.q3:
        return const Color(0xFFF59E0B);
      case EisenQuadrant.q4:
        return const Color(0xFF94A3B8);
    }
  }

  String _qHint(EisenQuadrant q) {
    switch (q) {
      case EisenQuadrant.q1:
        return 'الان انجام بده';
      case EisenQuadrant.q2:
        return 'زمان‌بندی کن';
      case EisenQuadrant.q3:
        return 'واگذار کن';
      case EisenQuadrant.q4:
        return 'حذف / کم‌اهمیت';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planningProvider);

    final q1 = state.eisenTasks.where((e) => e.quadrant.name == 'q1' && !e.done).length;
    final q2 = state.eisenTasks.where((e) => e.quadrant.name == 'q2' && !e.done).length;
    final q3 = state.eisenTasks.where((e) => e.quadrant.name == 'q3' && !e.done).length;
    final q4 = state.eisenTasks.where((e) => e.quadrant.name == 'q4' && !e.done).length;
    final doneN = state.eisenTasks.where((e) => e.done).length;
    final total = state.eisenTasks.length;

    final theme = Theme.of(context);
    final open = state.openEisenCount;
    final done = state.eisenTasks.where((t) => t.done).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مانیتورینگ ماتریس',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    total == 0
                        ? 'هنوز کاری ثبت نشده'
                        : 'باز: فوری‌مهم $q1 · مهم $q2 · فوری $q3 · سایر $q4 | انجام‌شده $doneN از $total',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _QuadBar(label: 'Q1 فوری+مهم', value: q1, total: total == 0 ? 1 : total, color: const Color(0xFFEF4444)),
                  _QuadBar(label: 'Q2 مهم', value: q2, total: total == 0 ? 1 : total, color: const Color(0xFF3B82F6)),
                  _QuadBar(label: 'Q3 فوری', value: q3, total: total == 0 ? 1 : total, color: const Color(0xFFF59E0B)),
                  _QuadBar(label: 'Q4 سایر', value: q4, total: total == 0 ? 1 : total, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded,
                    color: AppColors.brand3, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${MoneyFormat.toPersianDigits('$open')} باز · ${MoneyFormat.toPersianDigits('$done')} انجام‌شده',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuadrantBox(
                          quadrant: EisenQuadrant.q1,
                          color: _qColor(EisenQuadrant.q1),
                          hint: _qHint(EisenQuadrant.q1),
                          tasks: state.eisenTasks
                              .where((t) => t.quadrant == EisenQuadrant.q1)
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _QuadrantBox(
                          quadrant: EisenQuadrant.q2,
                          color: _qColor(EisenQuadrant.q2),
                          hint: _qHint(EisenQuadrant.q2),
                          tasks: state.eisenTasks
                              .where((t) => t.quadrant == EisenQuadrant.q2)
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuadrantBox(
                          quadrant: EisenQuadrant.q3,
                          color: _qColor(EisenQuadrant.q3),
                          hint: _qHint(EisenQuadrant.q3),
                          tasks: state.eisenTasks
                              .where((t) => t.quadrant == EisenQuadrant.q3)
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _QuadrantBox(
                          quadrant: EisenQuadrant.q4,
                          color: _qColor(EisenQuadrant.q4),
                          hint: _qHint(EisenQuadrant.q4),
                          tasks: state.eisenTasks
                              .where((t) => t.quadrant == EisenQuadrant.q4)
                              .toList(),
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
    );
  }
}

class _QuadrantBox extends ConsumerWidget {
  final EisenQuadrant quadrant;
  final Color color;
  final String hint;
  final List<EisenTaskEntity> tasks;

  const _QuadrantBox({
    required this.quadrant,
    required this.color,
    required this.hint,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sorted = List<EisenTaskEntity>.from(tasks)
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quadrant.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        hint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _addTask(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_rounded, size: 16, color: color),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Text(
                      'خالی',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final t = sorted[i];
                      return _TaskTile(
                        task: t,
                        color: color,
                        onToggle: () => ref
                            .read(planningProvider.notifier)
                            .toggleEisenDone(t),
                        onMove: (q) => ref
                            .read(planningProvider.notifier)
                            .updateEisenTask(t.copyWith(quadrant: q)),
                        onDelete: () => ref
                            .read(planningProvider.notifier)
                            .deleteEisenTask(t.id),
                        onEdit: () => _editTask(context, ref, t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('کار جدید — ${quadrant.label}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            hintText: 'چه کاری؟ (مثلاً پرداخت قبض، تماس با بانک)',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      await ref
          .read(planningProvider.notifier)
          .addEisenTask(text.trim(), quadrant);
    }
  }

  Future<void> _editTask(
      BuildContext context, WidgetRef ref, EisenTaskEntity task) async {
    final ctrl = TextEditingController(text: task.text);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش کار'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      await ref
          .read(planningProvider.notifier)
          .updateEisenTask(task.copyWith(text: text.trim()));
    }
  }
}

class _TaskTile extends StatelessWidget {
  final EisenTaskEntity task;
  final Color color;
  final VoidCallback onToggle;
  final void Function(EisenQuadrant q) onMove;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskTile({
    required this.task,
    required this.color,
    required this.onToggle,
    required this.onMove,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onToggle,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Icon(
                  task.done
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 14,
                  color: task.done
                      ? color
                      : theme.colorScheme.onSurface.withOpacity(0.35),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.done ? TextDecoration.lineThrough : null,
                      color: task.done
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : null,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  icon: Icon(Icons.more_vert,
                      size: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                    if (v.startsWith('move:')) {
                      final q = EisenQuadrant.values
                          .firstWhere((e) => e.name == v.substring(5));
                      onMove(q);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                    ...EisenQuadrant.values
                        .where((q) => q != task.quadrant)
                        .map((q) => PopupMenuItem(
                              value: 'move:${q.name}',
                              child: Text('به ${q.label}'),
                            )),
                    const PopupMenuItem(
                        value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _QuadBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _QuadBar({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final r = total <= 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: r.clamp(0.0, 1.0), minHeight: 8, color: color, backgroundColor: color.withOpacity(0.15)),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

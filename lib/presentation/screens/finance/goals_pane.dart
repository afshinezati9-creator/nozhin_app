import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/fin_goal_entity.dart';
import '../../providers/finance_provider.dart';

class GoalsPane extends ConsumerWidget {
  const GoalsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final list = List<FinGoalEntity>.from(state.goals)
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });

    final totalTarget =
        list.fold<double>(0, (s, g) => s + g.targetAmount);
    final totalCurrent =
        list.fold<double>(0, (s, g) => s + g.currentAmount);
    final openCount = list.where((g) => !g.isDone).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${MoneyFormat.toPersianDigits('$openCount')} هدف باز',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormat.toman(totalCurrent, withUnit: false)} / ${MoneyFormat.toman(totalTarget)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.brand3,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openForm(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const AppEmptyState(
                  icon: Icons.flag_rounded,
                  message:
                      'هنوز هدف مالی نداری\nبا + هدف پس‌انداز تعریف کن',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final g = list[i];
                    return _GoalCard(
                      goal: g,
                      onTap: () => _openForm(context, ref, existing: g),
                      onAdd: g.isDone
                          ? null
                          : () => _addAmount(context, ref, g),
                      onDelete: () => _confirmDelete(context, ref, g),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FinGoalEntity g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف هدف'),
        content: Text('«${g.title}» حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(financeProvider.notifier).deleteGoal(g.id);
    }
  }

  Future<void> _addAmount(
      BuildContext context, WidgetRef ref, FinGoalEntity g) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن به هدف'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'مبلغ',
            suffixText: 'تومان',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لغو')),
          TextButton(
            onPressed: () {
              final v = MoneyFormat.parseAmount(ctrl.text);
              Navigator.pop(ctx, v);
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await ref.read(financeProvider.notifier).updateGoal(
            g.copyWith(currentAmount: g.currentAmount + amount),
          );
    }
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {FinGoalEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GoalFormSheet(existing: existing),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FinGoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        goal.isDone ? const Color(0xFF10B981) : const Color(0xFF8B5CF6);
    final pct = (goal.progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        goal.isDone
                            ? Icons.check_circle_rounded
                            : Icons.flag_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.title,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if (goal.deadline != null &&
                              goal.deadline!.isNotEmpty)
                            Text(
                              'مهلت: ${goal.deadline}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${MoneyFormat.toPersianDigits('$pct')}٪',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 18,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.35)),
                      onSelected: (v) {
                        if (v == 'edit') onTap();
                        if (v == 'add' && onAdd != null) onAdd!();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('ویرایش')),
                        if (!goal.isDone)
                          const PopupMenuItem(
                              value: 'add', child: Text('افزودن مبلغ')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outline.withOpacity(0.25),
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${MoneyFormat.toman(goal.currentAmount, withUnit: false)} / ${MoneyFormat.toman(goal.targetAmount)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (onAdd != null)
                      TextButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('واریز'),
                        style: TextButton.styleFrom(
                          foregroundColor: color,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
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

class _GoalFormSheet extends ConsumerStatefulWidget {
  final FinGoalEntity? existing;
  const _GoalFormSheet({this.existing});

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late final TextEditingController _deadlineCtrl;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _targetCtrl = TextEditingController(
        text: e != null ? e.targetAmount.toStringAsFixed(0) : '');
    _currentCtrl = TextEditingController(
        text: e != null && e.currentAmount > 0
            ? e.currentAmount.toStringAsFixed(0)
            : '0');
    _deadlineCtrl = TextEditingController(text: e?.deadline ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _deadlineCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final target = MoneyFormat.parseAmount(_targetCtrl.text);
    final current = MoneyFormat.parseAmount(_currentCtrl.text) ?? 0;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عنوان هدف را وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('مبلغ هدف معتبر وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final goal = FinGoalEntity(
        id: widget.existing?.id ?? '',
        title: title,
        targetAmount: target,
        currentAmount: current,
        deadline: _deadlineCtrl.text.trim().isEmpty
            ? null
            : _deadlineCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (isEdit) {
        await ref.read(financeProvider.notifier).updateGoal(goal);
      } else {
        await ref.read(financeProvider.notifier).addGoal(goal);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(isEdit ? 'ویرایش هدف' : 'هدف مالی جدید',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان',
                hintText: 'مثلاً خرید لپ‌تاپ، سفر شمال',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'مبلغ هدف',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'پس‌انداز فعلی',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deadlineCtrl,
              decoration: const InputDecoration(
                labelText: 'مهلت (اختیاری)',
                hintText: 'مثلاً اسفند ۱۴۰۴',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'یادداشت'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'ذخیره' : 'ثبت هدف',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

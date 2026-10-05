import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/emergency_fund_entity.dart';
import '../../providers/finance_provider.dart';

class BudgetPane extends ConsumerWidget {
  const BudgetPane({super.key});

  static const _monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  void _shiftMonth(WidgetRef ref, FinanceState state, int delta) {
    var y = state.viewYear;
    var m = state.viewMonth + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    ref.read(financeProvider.notifier).setViewMonth(y, m);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final budgets = state.monthBudgets;
    final spentMap = state.expenseByCategory;
    final monthLabel =
        '${_monthNames[state.viewMonth - 1]} ${MoneyFormat.toPersianDigits('${state.viewYear}')}';

    double totalLimit = 0;
    double totalSpent = 0;
    for (final b in budgets) {
      totalLimit += b.limit;
      totalSpent += spentMap[b.category] ?? 0;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        // ماه
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _shiftMonth(ref, state, -1),
              ),
              Expanded(
                child: Text(
                  'بودجه $monthLabel',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shiftMonth(ref, state, 1),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.brand3),
                tooltip: 'بودجه جدید',
                onPressed: () => _openBudgetForm(context, ref, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // خلاصه بودجه ماه
        if (budgets.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جمع بودجه ماه',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${MoneyFormat.toman(totalSpent, withUnit: false)} / ${MoneyFormat.toman(totalLimit)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalLimit <= 0
                        ? 0
                        : (totalSpent / totalLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // صندوق اضطراری
        _EmergencyCard(
          fund: state.emergency,
          onEdit: () => _openEmergencyForm(context, ref, state.emergency),
        ),
        const SizedBox(height: 14),

        Text(
          'بودجه دسته‌ها',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),

        if (budgets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              message:
                  'بودجه‌ای برای این ماه نیست\nبا + سقف هزینه هر دسته را مشخص کن',
            ),
          )
        else
          ...budgets.map((b) {
            final spent = spentMap[b.category] ?? 0;
            final ratio = b.limit <= 0 ? 0.0 : spent / b.limit;
            final status = ratio > 1
                ? _BudgetStatus.over
                : ratio >= 0.7
                    ? _BudgetStatus.warn
                    : _BudgetStatus.ok;
            return _BudgetItem(
              budget: b,
              spent: spent,
              status: status,
              onEdit: () =>
                  _openBudgetForm(context, ref, state, existing: b),
              onDelete: () => _confirmDelete(context, ref, b),
            );
          }),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, BudgetEntity b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف بودجه'),
        content: Text('بودجه «${b.category}» حذف شود؟'),
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
      await ref.read(financeProvider.notifier).deleteBudget(b.id);
    }
  }

  Future<void> _openBudgetForm(
    BuildContext context,
    WidgetRef ref,
    FinanceState state, {
    BudgetEntity? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BudgetFormSheet(
        year: state.viewYear,
        month: state.viewMonth,
        existing: existing,
        usedCategories: state.monthBudgets.map((b) => b.category).toSet(),
      ),
    );
  }

  Future<void> _openEmergencyForm(
    BuildContext context,
    WidgetRef ref,
    EmergencyFundEntity fund,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EmergencyFormSheet(fund: fund),
    );
  }
}

enum _BudgetStatus { ok, warn, over }

class _BudgetItem extends StatelessWidget {
  final BudgetEntity budget;
  final double spent;
  final _BudgetStatus status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetItem({
    required this.budget,
    required this.spent,
    required this.status,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _barColor {
    switch (status) {
      case _BudgetStatus.ok:
        return const Color(0xFF10B981);
      case _BudgetStatus.warn:
        return const Color(0xFFF59E0B);
      case _BudgetStatus.over:
        return const Color(0xFFEF4444);
    }
  }

  String get _statusLabel {
    switch (status) {
      case _BudgetStatus.ok:
        return 'در محدوده';
      case _BudgetStatus.warn:
        return 'نزدیک سقف';
      case _BudgetStatus.over:
        return 'تجاوز از بودجه';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio =
        budget.limit <= 0 ? 0.0 : (spent / budget.limit).clamp(0.0, 1.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onEdit,
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
                    Expanded(
                      child: Text(
                        budget.category,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _barColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _barColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 18,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.35)),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${MoneyFormat.toman(spent, withUnit: false)} از ${MoneyFormat.toman(budget.limit)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outline.withOpacity(0.25),
                    color: _barColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EmergencyFundEntity fund;
  final VoidCallback onEdit;

  const _EmergencyCard({required this.fund, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = fund.target > 0 || fund.current > 0;

    return Material(
      color: const Color(0xFF0EA5E9).withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: Color(0xFF0EA5E9), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'صندوق اضطراری',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    child: Text(has ? 'ویرایش' : 'تنظیم'),
                  ),
                ],
              ),
              if (!has)
                Text(
                  'هدف و مبلغ فعلی را تنظیم کن تا پیشرفت را ببینی',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                )
              else ...[
                const SizedBox(height: 6),
                Text(
                  '${MoneyFormat.toman(fund.current, withUnit: false)} / ${MoneyFormat.toman(fund.target)}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fund.progress,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outline.withOpacity(0.25),
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${MoneyFormat.toPersianDigits((fund.progress * 100).round().toString())}٪ تکمیل',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final int year;
  final int month;
  final BudgetEntity? existing;
  final Set<String> usedCategories;

  const _BudgetFormSheet({
    required this.year,
    required this.month,
    this.existing,
    required this.usedCategories,
  });

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  late String _category;
  late final TextEditingController _limitCtrl;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  List<String> get _available {
    final all = [...defaultExpenseCategories];
    if (isEdit && !all.contains(widget.existing!.category)) {
      all.insert(0, widget.existing!.category);
    }
    if (isEdit) return all;
    return all.where((c) => !widget.usedCategories.contains(c)).toList();
  }

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ??
        (_available.isNotEmpty ? _available.first : defaultExpenseCategories.first);
    _limitCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.limit.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = MoneyFormat.parseAmount(_limitCtrl.text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('سقف بودجه معتبر وارد کن'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(financeProvider.notifier).upsertBudget(
            BudgetEntity(
              id: widget.existing?.id ?? '',
              category: _category,
              limit: limit,
              year: widget.year,
              month: widget.month,
            ),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cats = _available;

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
            Text(
              isEdit ? 'ویرایش بودجه' : 'بودجه جدید',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (cats.isEmpty)
              const Text('همه دسته‌ها برای این ماه بودجه دارند')
            else
              DropdownButtonFormField<String>(
                value: cats.contains(_category) ? _category : cats.first,
                decoration: const InputDecoration(labelText: 'دسته'),
                items: cats
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: isEdit
                    ? null
                    : (v) {
                        if (v != null) setState(() => _category = v);
                      },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'سقف بودجه',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving || cats.isEmpty ? null : _save,
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
                  : Text(
                      isEdit ? 'ذخیره' : 'ثبت بودجه',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyFormSheet extends ConsumerStatefulWidget {
  final EmergencyFundEntity fund;
  const _EmergencyFormSheet({required this.fund});

  @override
  ConsumerState<_EmergencyFormSheet> createState() =>
      _EmergencyFormSheetState();
}

class _EmergencyFormSheetState extends ConsumerState<_EmergencyFormSheet> {
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _targetCtrl = TextEditingController(
      text: widget.fund.target > 0
          ? widget.fund.target.toStringAsFixed(0)
          : '',
    );
    _currentCtrl = TextEditingController(
      text: widget.fund.current > 0
          ? widget.fund.current.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = MoneyFormat.parseAmount(_targetCtrl.text) ?? 0;
    final current = MoneyFormat.parseAmount(_currentCtrl.text) ?? 0;
    if (target < 0 || current < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('مبلغ نامعتبر'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(financeProvider.notifier).saveEmergency(
            EmergencyFundEntity(target: target, current: current),
          );
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
            Text(
              'صندوق اضطراری',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'هدف',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'موجودی فعلی',
                suffixText: 'تومان',
              ),
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
                  : const Text('ذخیره',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

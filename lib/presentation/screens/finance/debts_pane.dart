import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/debt_entity.dart';
import '../../providers/finance_provider.dart';

class DebtsPane extends ConsumerStatefulWidget {
  const DebtsPane({super.key});

  @override
  ConsumerState<DebtsPane> createState() => _DebtsPaneState();
}

class _DebtsPaneState extends ConsumerState<DebtsPane> {
  DebtType? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    var list = List<DebtEntity>.from(state.debts);
    if (_filter != null) {
      list = list.where((d) => d.type == _filter).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniSum(
                      label: 'بدهی من',
                      value: state.totalDebtOwe,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniSum(
                      label: 'طلب من',
                      value: state.totalDebtOwed,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.brand3,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _openForm(context),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.add_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppChip(
                      label: 'همه',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'بدهکارم',
                      selected: _filter == DebtType.owe,
                      onTap: () => setState(() {
                        _filter =
                            _filter == DebtType.owe ? null : DebtType.owe;
                      }),
                    ),
                    const SizedBox(width: 6),
                    AppChip(
                      label: 'طلبکارم',
                      selected: _filter == DebtType.owed,
                      onTap: () => setState(() {
                        _filter =
                            _filter == DebtType.owed ? null : DebtType.owed;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const AppEmptyState(
                  icon: Icons.money_off_csred_rounded,
                  message: 'بدهی یا طلبی ثبت نشده\nبا + اضافه کن',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final d = list[i];
                    return _DebtCard(
                      debt: d,
                      onTap: () => _openForm(context, existing: d),
                      onDelete: () => _confirmDelete(d),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(DebtEntity d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف'),
        content: Text('«${d.name}» حذف شود؟'),
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
      await ref.read(financeProvider.notifier).deleteDebt(d.id);
    }
  }

  Future<void> _openForm(BuildContext context, {DebtEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DebtFormSheet(existing: existing),
    );
  }
}

class _MiniSum extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniSum(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(MoneyFormat.toman(value, withUnit: false),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DebtCard(
      {required this.debt, required this.onTap, required this.onDelete});

  bool get isOwe => debt.type == DebtType.owe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOwe ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isOwe
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          isOwe ? 'بدهکارم' : 'طلبکارم',
                          if (debt.dueDate != null && debt.dueDate!.isNotEmpty)
                            'سررسید: ${debt.dueDate}',
                        ].join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  MoneyFormat.toman(debt.amount, withUnit: false),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.35)),
                  onSelected: (v) {
                    if (v == 'edit') onTap();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
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

class _DebtFormSheet extends ConsumerStatefulWidget {
  final DebtEntity? existing;
  const _DebtFormSheet({this.existing});

  @override
  ConsumerState<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<_DebtFormSheet> {
  late DebtType _type;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dueCtrl;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? DebtType.owe;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(0) : '');
    _dueCtrl = TextEditingController(text: e?.dueDate ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final amount = MoneyFormat.parseAmount(_amountCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('نام را وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('مبلغ معتبر وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final debt = DebtEntity(
        id: widget.existing?.id ?? '',
        type: _type,
        name: name,
        amount: amount,
        dueDate: _dueCtrl.text.trim().isEmpty ? null : _dueCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (isEdit) {
        await ref.read(financeProvider.notifier).updateDebt(debt);
      } else {
        await ref.read(financeProvider.notifier).addDebt(debt);
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
            Text(isEdit ? 'ویرایش' : 'بدهی / طلب جدید',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('من بدهکارم'),
                    selected: _type == DebtType.owe,
                    onSelected: (_) => setState(() => _type = DebtType.owe),
                    selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('من طلبکارم'),
                    selected: _type == DebtType.owed,
                    onSelected: (_) => setState(() => _type = DebtType.owed),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'نام شخص / عنوان',
                hintText: 'مثلاً علی، وام بانک',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'مبلغ',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dueCtrl,
              decoration: const InputDecoration(
                labelText: 'سررسید (اختیاری)',
                hintText: 'مثلاً ۱۵ مهر ۱۴۰۴',
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
                  : Text(isEdit ? 'ذخیره' : 'ثبت',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

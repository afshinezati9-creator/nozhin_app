import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/installment_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/finance_provider.dart';

class InstallmentsPane extends ConsumerWidget {
  const InstallmentsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final list = List<InstallmentEntity>.from(state.installments)
      ..sort((a, b) => a.isDone == b.isDone
          ? b.createdAt.compareTo(a.createdAt)
          : (a.isDone ? 1 : -1));

    final remaining = list
        .where((i) => !i.isDone)
        .fold<double>(0, (s, i) => s + i.remainingAmount);

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
                    color: AppColors.brand3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.brand3.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مانده اقساط',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.brand3,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        MoneyFormat.toman(remaining),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
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
                  icon: Icons.calendar_view_month_rounded,
                  message: 'قسطی ثبت نشده\nبا + قسط جدید اضافه کن',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final item = list[i];
                    return _InstCard(
                      item: item,
                      accountName: _accountName(state, item.accountId),
                      onTap: () => _openForm(context, ref, existing: item),
                      onPay: item.isDone
                          ? null
                          : () => _payOne(context, ref, item),
                      onDelete: () => _confirmDelete(context, ref, item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _accountName(FinanceState state, String? id) {
    if (id == null || id.isEmpty) return '';
    try {
      return state.accounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return '';
    }
  }

  Future<void> _payOne(
      BuildContext context, WidgetRef ref, InstallmentEntity item) async {
    final accounts = ref.read(financeProvider).accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اول یک حساب بساز تا پرداخت ثبت شود'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final accountId = item.accountId ?? accounts.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پرداخت قسط'),
        content: Text(
          'یک قسط از «${item.title}» به مبلغ ${MoneyFormat.toman(item.installmentAmount)} پرداخت شود؟\nاز حساب کم می‌شود و تراکنش هزینه ثبت می‌گردد.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('پرداخت')),
        ],
      ),
    );
    if (ok != true) return;

    final notifier = ref.read(financeProvider.notifier);
    // تراکنش هزینه
    await notifier.addTransaction(TransactionEntity(
      id: '',
      type: TransactionType.expense,
      title: 'قسط: ${item.title}',
      amount: item.installmentAmount,
      category: 'اقساط',
      description: 'پرداخت قسط ${item.paidCount + 1} از ${item.totalCount}',
      accountId: accountId,
      date: DateTime.now(),
    ));
    // به‌روزرسانی قسط
    await notifier.updateInstallment(
      item.copyWith(paidCount: item.paidCount + 1),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, InstallmentEntity item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف قسط'),
        content: Text('«${item.title}» حذف شود؟'),
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
      await ref.read(financeProvider.notifier).deleteInstallment(item.id);
    }
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {InstallmentEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InstFormSheet(existing: existing),
    );
  }
}

class _InstCard extends StatelessWidget {
  final InstallmentEntity item;
  final String accountName;
  final VoidCallback onTap;
  final VoidCallback? onPay;
  final VoidCallback onDelete;

  const _InstCard({
    required this.item,
    required this.accountName,
    required this.onTap,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        item.isDone ? const Color(0xFF10B981) : AppColors.brand3;

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
                    Expanded(
                      child: Text(item.title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    if (item.isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('تسویه',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 18,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.35)),
                      onSelected: (v) {
                        if (v == 'edit') onTap();
                        if (v == 'delete') onDelete();
                        if (v == 'pay' && onPay != null) onPay!();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('ویرایش')),
                        if (!item.isDone)
                          const PopupMenuItem(
                              value: 'pay', child: Text('پرداخت یک قسط')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${MoneyFormat.toPersianDigits('${item.paidCount}')}/${MoneyFormat.toPersianDigits('${item.totalCount}')} قسط',
                    MoneyFormat.toman(item.installmentAmount),
                    if (item.dueDay != null && item.dueDay!.isNotEmpty)
                      'روز ${item.dueDay}',
                    if (accountName.isNotEmpty) accountName,
                  ].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.progress,
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
                      'مانده: ${MoneyFormat.toman(item.remainingAmount)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (onPay != null)
                      TextButton.icon(
                        onPressed: onPay,
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: const Text('پرداخت'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand3,
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

class _InstFormSheet extends ConsumerStatefulWidget {
  final InstallmentEntity? existing;
  const _InstFormSheet({this.existing});

  @override
  ConsumerState<_InstFormSheet> createState() => _InstFormSheetState();
}

class _InstFormSheetState extends ConsumerState<_InstFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _countCtrl;
  late final TextEditingController _eachCtrl;
  late final TextEditingController _dueCtrl;
  late final TextEditingController _noteCtrl;
  String? _accountId;
  bool _saving = false;
  bool _autoEach = true;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _totalCtrl = TextEditingController(
        text: e != null ? e.totalAmount.toStringAsFixed(0) : '');
    _countCtrl = TextEditingController(
        text: e != null ? e.totalCount.toString() : '12');
    _eachCtrl = TextEditingController(
        text: e != null ? e.installmentAmount.toStringAsFixed(0) : '');
    _dueCtrl = TextEditingController(text: e?.dueDay ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _accountId = e?.accountId;
    _totalCtrl.addListener(_recalcEach);
    _countCtrl.addListener(_recalcEach);
  }

  void _recalcEach() {
    if (!_autoEach || isEdit) return;
    final total = MoneyFormat.parseAmount(_totalCtrl.text);
    final count = int.tryParse(MoneyFormat.fromPersianDigits(_countCtrl.text));
    if (total != null && count != null && count > 0) {
      final each = (total / count).round();
      _eachCtrl.text = each.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalCtrl.dispose();
    _countCtrl.dispose();
    _eachCtrl.dispose();
    _dueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final total = MoneyFormat.parseAmount(_totalCtrl.text);
    final count =
        int.tryParse(MoneyFormat.fromPersianDigits(_countCtrl.text.trim()));
    final each = MoneyFormat.parseAmount(_eachCtrl.text);
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عنوان را وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (total == null ||
        total <= 0 ||
        count == null ||
        count <= 0 ||
        each == null ||
        each <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('مبالغ و تعداد را درست وارد کن'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final inst = InstallmentEntity(
        id: widget.existing?.id ?? '',
        title: title,
        totalAmount: total,
        totalCount: count,
        paidCount: widget.existing?.paidCount ?? 0,
        installmentAmount: each,
        dueDay: _dueCtrl.text.trim().isEmpty ? null : _dueCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        accountId: _accountId,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (isEdit) {
        await ref.read(financeProvider.notifier).updateInstallment(inst);
      } else {
        await ref.read(financeProvider.notifier).addInstallment(inst);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(financeProvider).accounts;
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
            Text(isEdit ? 'ویرایش قسط' : 'قسط جدید',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان',
                hintText: 'مثلاً وام خودرو',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'مبلغ کل',
                suffixText: 'تومان',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'تعداد اقساط'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _eachCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _autoEach = false,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ هر قسط',
                      suffixText: 'تومان',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dueCtrl,
              decoration: const InputDecoration(
                labelText: 'روز سررسید در ماه (اختیاری)',
                hintText: 'مثلاً ۱۵',
              ),
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accounts.any((a) => a.id == _accountId)
                    ? _accountId
                    : null,
                decoration:
                    const InputDecoration(labelText: 'حساب پرداخت (اختیاری)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...accounts.map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      )),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
            ],
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
                  : Text(isEdit ? 'ذخیره' : 'ثبت قسط',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

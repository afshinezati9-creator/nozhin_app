import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/utils/persian_amount_words.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/finance_provider.dart';


Future<void> showTransactionSheet(BuildContext context, {TransactionEntity? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => TxFormSheet(existing: existing),
  );
}

class TransactionsPane extends ConsumerStatefulWidget {
  const TransactionsPane({super.key});

  @override
  ConsumerState<TransactionsPane> createState() => _TransactionsPaneState();
}

class _TransactionsPaneState extends ConsumerState<TransactionsPane> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  TransactionType? _typeFilter;
  String? _accountFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TransactionEntity> _filtered(FinanceState state) {
    var list = List<TransactionEntity>.from(state.transactions);
    if (_typeFilter != null) {
      list = list.where((t) => t.type == _typeFilter).toList();
    }
    if (_accountFilter != null) {
      list = list
          .where((t) =>
              t.accountId == _accountFilter ||
              t.toAccountId == _accountFilter)
          .toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q) ||
              (t.description ?? '').toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String _accountName(FinanceState state, String? id) {
    if (id == null || id.isEmpty) return '—';
    try {
      return state.accounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return 'حساب حذف‌شده';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final list = _filtered(state);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchCtrl,
                      hint: 'جستجو در تراکنش‌ها...',
                      onChanged: (v) => setState(() => _query = v),
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
                  physics: const BouncingScrollPhysics(),
                  children: [
                    AppChip(
                      label: 'همه',
                      selected: _typeFilter == null,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 6),
                    ...TransactionType.values.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: AppChip(
                          label: t == TransactionType.income
                              ? 'درآمد'
                              : t == TransactionType.expense
                                  ? 'هزینه'
                                  : t == TransactionType.saving
                                      ? 'پس‌انداز'
                                      : 'انتقال',
                          selected: _typeFilter == t,
                          onTap: () => setState(() {
                            _typeFilter = _typeFilter == t ? null : t;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (state.accounts.isNotEmpty) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      AppChip(
                        label: 'همه حساب‌ها',
                        selected: _accountFilter == null,
                        onTap: () => setState(() => _accountFilter = null),
                      ),
                      ...state.accounts.map((a) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: AppChip(
                            label: a.name,
                            selected: _accountFilter == a.id,
                            onTap: () => setState(() {
                              _accountFilter =
                                  _accountFilter == a.id ? null : a.id;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${MoneyFormat.toPersianDigits('${list.length}')} تراکنش',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? AppEmptyState(
                  icon: Icons.swap_horiz_rounded,
                  message: state.transactions.isEmpty
                      ? 'هنوز تراکنشی ثبت نشده\nبا + درآمد یا هزینه اضافه کن'
                      : 'نتیجه‌ای با این فیلتر پیدا نشد',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(financeProvider.notifier).load(),
                  color: AppColors.brand3,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final tx = list[i];
                      return _TxCard(
                        tx: tx,
                        accountLabel: tx.type == TransactionType.transfer
                            ? '${_accountName(state, tx.accountId)} ← ${_accountName(state, tx.toAccountId)}'
                            : _accountName(state, tx.accountId),
                        onTap: () => _openForm(context, existing: tx),
                        onDelete: () => _confirmDelete(tx),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(TransactionEntity tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف تراکنش'),
        content: Text('«${tx.title}» حذف شود؟\nموجودی حساب‌ها برمی‌گردد.'),
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
      await ref.read(financeProvider.notifier).deleteTransaction(tx.id);
    }
  }

  Future<void> _openForm(BuildContext context,
      {TransactionEntity? existing}) async {
    await showTransactionSheet(context, existing: existing);
  }
}

class _TxCard extends StatelessWidget {
  final TransactionEntity tx;
  final String accountLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TxCard({
    required this.tx,
    required this.accountLabel,
    required this.onTap,
    required this.onDelete,
  });

  Color get _color {
    switch (tx.type) {
      case TransactionType.income:
        return const Color(0xFF10B981);
      case TransactionType.expense:
        return const Color(0xFFEF4444);
      case TransactionType.saving:
        return const Color(0xFF3B82F6);
      case TransactionType.transfer:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData get _icon {
    switch (tx.type) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.saving:
        return Icons.savings_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  String get _sign {
    switch (tx.type) {
      case TransactionType.income:
      case TransactionType.saving:
        return '+';
      case TransactionType.expense:
        return '−';
      case TransactionType.transfer:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final j = Jalali.fromDateTime(tx.date);
    final dateStr =
        '${MoneyFormat.toPersianDigits('${j.day}')} ${j.monthName}';

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
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title.isEmpty ? '(بدون عنوان)' : tx.title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${tx.category} · $accountLabel · $dateStr',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_sign${MoneyFormat.toman(tx.amount, withUnit: false)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _color,
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


class TxFormSheet extends ConsumerStatefulWidget {
  final TransactionEntity? existing;
  const TxFormSheet({super.key, this.existing});

  @override
  ConsumerState<TxFormSheet> createState() => TxFormSheetState();
}

class TxFormSheetState extends ConsumerState<TxFormSheet> {
  late TransactionType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  String? _accountId;
  String? _toAccountId;
  String _category = defaultExpenseCategories.first;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  bool get isEdit => widget.existing != null;

  List<String> get _categories {
    switch (_type) {
      case TransactionType.income:
        return defaultIncomeCategories;
      case TransactionType.expense:
        return defaultExpenseCategories;
      case TransactionType.saving:
        return defaultSavingCategories;
      case TransactionType.transfer:
        return const ['انتقال بین حساب‌ها'];
    }
  }

  double? get _parsedAmount => MoneyFormat.parseAmount(_amountCtrl.text);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? TransactionType.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(0) : '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _accountId = e?.accountId;
    _toAccountId = e?.toAccountId;
    _category = e?.category ?? _categories.first;
    _date = e?.date ?? DateTime.now();
    _amountCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(financeProvider).accounts;
      if (!mounted) return;
      setState(() {
        if (_accountId == null ||
            !accounts.any((a) => a.id == _accountId)) {
          _accountId = accounts.isNotEmpty ? accounts.first.id : null;
        }
        if (_type == TransactionType.transfer) {
          if (_toAccountId == null ||
              !accounts.any((a) => a.id == _toAccountId) ||
              _toAccountId == _accountId) {
            _toAccountId = accounts
                .where((a) => a.id != _accountId)
                .map((a) => a.id)
                .cast<String?>()
                .firstWhere((_) => true, orElse: () => null);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final accounts = ref.read(financeProvider).accounts;
    if (accounts.isEmpty) {
      return 'ابتدا از راه‌اندازی یا تب حساب‌ها، حداقل یک حساب بساز';
    }
    final amount = _parsedAmount;
    if (_amountCtrl.text.trim().isEmpty) {
      return 'مبلغ را وارد کن';
    }
    if (amount == null) {
      return 'مبلغ نامعتبر است — فقط عدد وارد کن (مثال: 150000)';
    }
    if (amount <= 0) {
      return 'مبلغ باید بزرگ‌تر از صفر باشد';
    }
    if (amount > 999999999999) {
      return 'مبلغ خیلی بزرگ است';
    }
    if (_accountId == null || _accountId!.isEmpty) {
      return 'حساب را انتخاب کن';
    }
    if (!accounts.any((a) => a.id == _accountId)) {
      return 'حساب انتخاب‌شده وجود ندارد';
    }
    if (_type == TransactionType.transfer) {
      if (_toAccountId == null || _toAccountId!.isEmpty) {
        return 'حساب مقصد را انتخاب کن';
      }
      if (_toAccountId == _accountId) {
        return 'حساب مبدأ و مقصد نباید یکی باشند';
      }
      if (!accounts.any((a) => a.id == _toAccountId)) {
        return 'حساب مقصد نامعتبر است';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final amount = _parsedAmount!;
    final title = _titleCtrl.text.trim().isEmpty
        ? _typeLabel(_type)
        : _titleCtrl.text.trim();

    final tx = TransactionEntity(
      id: widget.existing?.id ?? '',
      type: _type,
      title: title,
      amount: amount,
      category: _type == TransactionType.transfer ? 'انتقال' : _category,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      accountId: _accountId!,
      toAccountId:
          _type == TransactionType.transfer ? _toAccountId : null,
      date: _date,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (isEdit) {
        await ref
            .read(financeProvider.notifier)
            .updateTransaction(widget.existing!, tx);
      } else {
        await ref.read(financeProvider.notifier).addTransaction(tx);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'خطا: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطا: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.income:
        return 'درآمد';
      case TransactionType.expense:
        return 'هزینه';
      case TransactionType.saving:
        return 'پس‌انداز';
      case TransactionType.transfer:
        return 'انتقال';
    }
  }

  Color _typeColor(TransactionType t) {
    switch (t) {
      case TransactionType.income:
        return const Color(0xFF10B981);
      case TransactionType.expense:
        return const Color(0xFFEF4444);
      case TransactionType.saving:
        return const Color(0xFF3B82F6);
      case TransactionType.transfer:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(financeProvider).accounts;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final j = Jalali.fromDateTime(_date);
    final amount = _parsedAmount;

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
              isEdit ? 'ویرایش تراکنش' : 'تراکنش جدید',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'نوع تراکنش را انتخاب کن',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),

            // نوع — چهار دکمه واضح
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionType.values.map((t) {
                final sel = t == _type;
                final c = _typeColor(t);
                return Material(
                  color: sel ? c.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => setState(() {
                      _type = t;
                      _category = _categories.first;
                      _error = null;
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 52) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? c : theme.colorScheme.outline,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            t == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : t == TransactionType.expense
                                    ? Icons.arrow_upward_rounded
                                    : t == TransactionType.saving
                                        ? Icons.savings_rounded
                                        : Icons.swap_horiz_rounded,
                            size: 18,
                            color: c,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _typeLabel(t),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: sel ? c : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (accounts.isEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'هنوز حسابی نداری. از راه‌اندازی اولیه یا تب حساب‌ها یک حساب بساز، بعد تراکنش ثبت کن.',
                ),
              ),
            ],

            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'عنوان',
                hintText: 'مثلاً خرید مواد غذایی',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'مبلغ',
                suffixText: 'تومان',
                errorText: _amountCtrl.text.isNotEmpty && amount == null
                    ? 'فقط عدد معتبر'
                    : (_amountCtrl.text.isNotEmpty &&
                            amount != null &&
                            amount <= 0
                        ? 'باید بیشتر از صفر باشد'
                        : null),
                helperText: amount != null && amount > 0
                    ? PersianAmountWords.toman(amount)
                    : 'عدد را وارد کن — به حروف هم نمایش داده می‌شود',
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: amount != null && amount > 0
                      ? AppColors.brand3
                      : null,
                  fontWeight: amount != null && amount > 0
                      ? FontWeight.w600
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // حساب
            if (accounts.isNotEmpty)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: _type == TransactionType.transfer
                      ? 'از حساب'
                      : 'حساب',
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: accounts.any((a) => a.id == _accountId)
                        ? _accountId
                        : null,
                    hint: const Text('انتخاب حساب'),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} (${MoneyFormat.toman(a.balance, withUnit: false)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _accountId = v;
                      if (_toAccountId == _accountId) {
                        _toAccountId = null;
                      }
                    }),
                  ),
                ),
              ),

            if (_type == TransactionType.transfer && accounts.length > 1) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'به حساب',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: accounts.any((a) =>
                            a.id == _toAccountId && a.id != _accountId)
                        ? _toAccountId
                        : null,
                    hint: const Text('حساب مقصد'),
                    items: accounts
                        .where((a) => a.id != _accountId)
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _toAccountId = v),
                  ),
                ),
              ),
            ],

            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'دسته',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _categories.contains(_category)
                        ? _category
                        : _categories.first,
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'توضیح (اختیاری)',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تاریخ'),
              subtitle: Text(
                '${MoneyFormat.toPersianDigits('${j.day}')} ${j.monthName} ${MoneyFormat.toPersianDigits('${j.year}')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: const Icon(Icons.calendar_today_rounded, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],

            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving || accounts.isEmpty ? null : _save,
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
                      isEdit ? 'ذخیره تغییرات' : 'ثبت تراکنش',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

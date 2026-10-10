import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/utils/persian_amount_words.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/account_entity.dart';
import '../../providers/finance_provider.dart';

class AccountsPane extends ConsumerWidget {
  const AccountsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final accounts = state.accounts;

    return Column(
      children: [
        // هدر موجودی کل + افزودن
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand3.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موجودی کل همه حساب‌ها',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        MoneyFormat.toman(state.totalBalance),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormat.toPersianDigits('${accounts.length}')} حساب',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openForm(context, ref),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: AppColors.brand3, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),

        // لیست
        Expanded(
          child: accounts.isEmpty
              ? AppEmptyState(
                  icon: Icons.account_balance_outlined,
                  message: 'هنوز حسابی نداری\nبا دکمه + اولین حساب را بساز',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(financeProvider.notifier).load(),
                  color: AppColors.brand3,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: accounts.length,
                    itemBuilder: (_, i) {
                      final a = accounts[i];
                      return _AccountCard(
                        account: a,
                        onTap: () => _openForm(context, ref, existing: a),
                        onDelete: () => _confirmDelete(context, ref, a),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AccountEntity a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف حساب'),
        content: Text('حساب «${a.name}» حذف شود؟\nموجودی و ارتباط تراکنش‌ها ممکن است تحت تأثیر قرار گیرد.'),
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
      await ref.read(financeProvider.notifier).deleteAccount(a.id);
    }
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    AccountEntity? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AccountFormSheet(existing: existing),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  IconData get _icon {
    switch (account.type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.wallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
    }
  }

  Color get _color {
    switch (account.type) {
      case AccountType.bank:
        return const Color(0xFF3B82F6);
      case AccountType.cash:
        return const Color(0xFF10B981);
      case AccountType.wallet:
        return const Color(0xFF8B5CF6);
      case AccountType.savings:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = account.balance >= 0;

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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.typeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MoneyFormat.toman(account.balance, withUnit: false),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: positive
                            ? theme.colorScheme.onSurface
                            : AppColors.danger,
                      ),
                    ),
                    Text(
                      'تومان',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
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

class _AccountFormSheet extends ConsumerStatefulWidget {
  final AccountEntity? existing;
  const _AccountFormSheet({this.existing});

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late AccountType _type;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: e != null ? e.balance.toStringAsFixed(0) : '0',
    );
    _type = e?.type ?? AccountType.bank;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام حساب را وارد کن'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final raw = _balanceCtrl.text.trim();
    final balance = raw.isEmpty ? 0.0 : MoneyFormat.parseAmount(raw);
    if (balance == null || balance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('موجودی باید عدد معتبر و صفر یا مثبت باشد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (isEdit) {
        final updated = widget.existing!.copyWith(
          name: name,
          type: _type,
          balance: balance,
          icon: _type.name,
        );
        await ref.read(financeProvider.notifier).updateAccount(updated);
      } else {
        await ref.read(financeProvider.notifier).addAccount(
              name: name,
              type: _type,
              balance: balance,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
            const SizedBox(height: 14),
            Text(
              isEdit ? 'ویرایش حساب' : 'حساب جدید',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'نام حساب',
                hintText: 'مثلاً بانک ملی، جیب، ...',
              ),
            ),
            const SizedBox(height: 14),
            Text('نوع حساب', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((t) {
                final sel = t == _type;
                final label = switch (t) {
                  AccountType.bank => 'بانک',
                  AccountType.cash => 'نقد',
                  AccountType.wallet => 'کیف پول',
                  AccountType.savings => 'پس‌انداز',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: sel,
                  onSelected: (_) => setState(() => _type = t),
                  selectedColor: AppColors.brand3.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: sel ? AppColors.brand3 : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: isEdit ? 'موجودی فعلی' : 'موجودی اولیه',
                hintText: '۰',
                suffixText: 'تومان',
                helperText: () {
                  final v = MoneyFormat.parseAmount(_balanceCtrl.text);
                  if (v == null) {
                    return _balanceCtrl.text.trim().isEmpty
                        ? 'عدد مثبت یا صفر'
                        : 'مبلغ نامعتبر';
                  }
                  if (v < 0) return 'نباید منفی باشد';
                  if (v == 0) return 'صفر تومان';
                  return PersianAmountWords.toman(v);
                }(),
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: MoneyFormat.parseAmount(_balanceCtrl.text) != null &&
                          (MoneyFormat.parseAmount(_balanceCtrl.text) ?? -1) >= 0
                      ? AppColors.brand3
                      : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isEdit) ...[
              const SizedBox(height: 8),
              Text(
                'توجه: تغییر دستی موجودی با تراکنش‌ها همگام نمی‌شود. برای ثبت جریان پول از بخش تراکنش‌ها استفاده کن.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
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
                  : Text(
                      isEdit ? 'ذخیره تغییرات' : 'ایجاد حساب',
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

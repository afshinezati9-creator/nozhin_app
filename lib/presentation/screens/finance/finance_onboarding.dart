import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/utils/persian_amount_words.dart';
import '../../../domain/entities/account_entity.dart';
import '../../providers/finance_provider.dart';

/// راه‌اندازی اولیه بخش مالی وقتی هنوز حسابی نیست
class FinanceOnboarding extends ConsumerStatefulWidget {
  const FinanceOnboarding({super.key});

  @override
  ConsumerState<FinanceOnboarding> createState() => _FinanceOnboardingState();
}

class _FinanceOnboardingState extends ConsumerState<FinanceOnboarding> {
  int _step = 0;
  final _accounts = <_DraftAccount>[
    _DraftAccount(name: 'نقد / جیب', type: AccountType.cash),
    _DraftAccount(name: 'حساب بانکی', type: AccountType.bank),
  ];
  bool _saving = false;
  String? _error;

  Future<void> _finish() async {
    // اعتبارسنجی
    final valid = _accounts.where((a) => a.name.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      setState(() => _error = 'حداقل یک حساب با نام معتبر لازم است');
      return;
    }
    for (final a in valid) {
      if (a.balanceText.trim().isNotEmpty) {
        final v = MoneyFormat.parseAmount(a.balanceText);
        if (v == null || v < 0) {
          setState(() => _error = 'موجودی «${a.name}» نامعتبر است');
          return;
        }
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notifier = ref.read(financeProvider.notifier);
      for (final a in valid) {
        final bal = MoneyFormat.parseAmount(a.balanceText) ?? 0;
        await notifier.addAccount(
          name: a.name.trim(),
          type: a.type,
          balance: bal,
        );
      }
    } catch (e) {
      setState(() => _error = 'خطا در ذخیره: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'راه‌اندازی مالی',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'قبل از ثبت تراکنش، حساب‌هایت را بساز تا موجودی‌ها درست بمانند.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // مراحل
        Row(
          children: [
            _StepDot(active: _step >= 0, label: '۱'),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            _StepDot(active: _step >= 1, label: '۲'),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            _StepDot(active: _step >= 2, label: '۳'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _step == 0
              ? 'آشنایی'
              : _step == 1
                  ? 'حساب‌ها و موجودی'
                  : 'تأیید و شروع',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        if (_step == 0) ...[
          _InfoCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'حساب‌ها',
            body:
                'نقد، بانک، کیف‌پول یا پس‌انداز — هر منبع پول یک حساب است.',
          ),
          _InfoCard(
            icon: Icons.swap_horiz_rounded,
            title: 'تراکنش‌ها',
            body:
                'درآمد، هزینه، پس‌انداز و انتقال بین حساب‌ها را ثبت می‌کنی.',
          ),
          _InfoCard(
            icon: Icons.pie_chart_rounded,
            title: 'بودجه و اهداف',
            body: 'سقف ماهانه، اقساط، بدهی و اهداف پس‌انداز را مدیریت کن.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() => _step = 1),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand3,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('ادامه — تعریف حساب‌ها',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],

        if (_step == 1) ...[
          Text(
            'حساب‌های شروع (می‌توانی بعداً بیشتر اضافه کنی)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...List.generate(_accounts.length, (i) {
            final a = _accounts[i];
            final bal = MoneyFormat.parseAmount(a.balanceText);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: a.nameCtrl,
                            onChanged: (v) => a.name = v,
                            decoration: const InputDecoration(
                              labelText: 'نام حساب',
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_accounts.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () =>
                                setState(() => _accounts.removeAt(i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: AccountType.values.map((t) {
                        final sel = a.type == t;
                        final label = switch (t) {
                          AccountType.bank => 'بانک',
                          AccountType.cash => 'نقد',
                          AccountType.wallet => 'کیف پول',
                          AccountType.savings => 'پس‌انداز',
                        };
                        return ChoiceChip(
                          label: Text(label, style: const TextStyle(fontSize: 11)),
                          selected: sel,
                          onSelected: (_) => setState(() => a.type = t),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: a.balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (v) {
                        a.balanceText = v;
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'موجودی اولیه',
                        suffixText: 'تومان',
                        isDense: true,
                        helperText: 'فقط عدد مثبت؛ خالی = صفر',
                      ),
                    ),
                    if (bal != null && bal > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          PersianAmountWords.toman(bal),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.brand3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _accounts.add(_DraftAccount(
                  name: '',
                  type: AccountType.bank,
                ));
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('حساب دیگر'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger)),
            ),
          Row(
            children: [
              TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('قبلی')),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _step = 2;
                  });
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
                child: const Text('ادامه'),
              ),
            ],
          ),
        ],

        if (_step == 2) ...[
          Text('خلاصه راه‌اندازی',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._accounts.where((a) => a.name.trim().isNotEmpty).map((a) {
            final bal = MoneyFormat.parseAmount(a.balanceText) ?? 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a.type == AccountType.cash
                    ? Icons.payments_rounded
                    : a.type == AccountType.wallet
                        ? Icons.account_balance_wallet_rounded
                        : a.type == AccountType.savings
                            ? Icons.savings_rounded
                            : Icons.account_balance_rounded,
                color: AppColors.brand3,
              ),
              title: Text(a.name.trim()),
              subtitle: Text(a.type.typeLabel),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(MoneyFormat.toman(bal),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (bal > 0)
                    Text(PersianAmountWords.fromNumber(bal),
                        style: theme.textTheme.labelSmall),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'بعد از شروع می‌توانی تراکنش، بودجه، قسط و هدف اضافه کنی.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger)),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                  onPressed: _saving ? null : () => setState(() => _step = 1),
                  child: const Text('قبلی')),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('شروع بخش مالی',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DraftAccount {
  String name;
  AccountType type;
  String balanceText;
  final TextEditingController nameCtrl;
  final TextEditingController balanceCtrl;

  _DraftAccount({
    required this.name,
    required this.type,
    this.balanceText = '',
  })  : nameCtrl = TextEditingController(text: name),
        balanceCtrl = TextEditingController(text: balanceText);
}

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          active ? AppColors.brand3 : Theme.of(context).colorScheme.outline,
      child: Text(label,
          style: TextStyle(
            color: active
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          )),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brand3),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on AccountType {
  String get typeLabel {
    switch (this) {
      case AccountType.bank:
        return 'بانک';
      case AccountType.cash:
        return 'نقد';
      case AccountType.wallet:
        return 'کیف پول';
      case AccountType.savings:
        return 'پس‌انداز';
    }
  }
}

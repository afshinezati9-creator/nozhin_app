import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../providers/finance_provider.dart';

class OverviewPane extends ConsumerWidget {
  const OverviewPane({super.key});

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
    const monthNames = [
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
    final monthLabel =
        '${monthNames[state.viewMonth - 1]} ${MoneyFormat.toPersianDigits('${state.viewYear}')}';
    final trend = state.last6Months;
    final maxExp = trend.fold<double>(0, (s, e) => e.expense > s ? e.expense : s);
    final cats = state.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCat =
        cats.isEmpty ? 1.0 : cats.first.value.clamp(1, double.infinity);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      children: [
        // انتخاب ماه شمسی
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'ماه قبل',
                onPressed: () => _shiftMonth(ref, state, -1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'خلاصه مالی ماه',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'ماه بعد',
                onPressed: () => _shiftMonth(ref, state, 1),
              ),
              TextButton(
                onPressed: () {
                  final ym = MoneyFormat.currentJalaliYm();
                  ref
                      .read(financeProvider.notifier)
                      .setViewMonth(ym.$1, ym.$2);
                },
                child: const Text('امروز'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // کارت‌های خلاصه
        Row(
          children: [
            Expanded(
              child: _SumCard(
                label: 'درآمد',
                value: state.monthIncome,
                color: const Color(0xFF10B981),
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SumCard(
                label: 'هزینه',
                value: state.monthExpense,
                color: const Color(0xFFEF4444),
                icon: Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SumCard(
                label: 'مانده ماه',
                value: state.monthBalance,
                color: state.monthBalance >= 0
                    ? AppColors.brand3
                    : const Color(0xFFEF4444),
                icon: Icons.balance_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SumCard(
                label: 'موجودی کل',
                value: state.totalBalance,
                color: const Color(0xFF8B5CF6),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SumCard(
          label: 'بدهی‌های باز',
          value: state.totalDebtOwe,
          color: const Color(0xFFF59E0B),
          icon: Icons.money_off_rounded,
          wide: true,
        ),

        const SizedBox(height: 18),

        // نمودار ۶ ماه
        _SectionCard(
          title: 'روند ۶ ماه اخیر',
          subtitle: 'هزینه ماهانه',
          child: SizedBox(
            height: 160,
            child: maxExp <= 0
                ? Center(
                    child: Text(
                      'هنوز هزینه‌ای در این بازه نیست',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.map((e) {
                      final h = maxExp == 0 ? 0.0 : (e.expense / maxExp);
                      final isCurrent = e.year == state.viewYear &&
                          e.month == state.viewMonth;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                e.expense > 0
                                    ? MoneyFormat.formatNumber(
                                        e.expense / 1000000,
                                        persian: true)
                                    : '',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: h.clamp(0.04, 1.0),
                                  widthFactor: 1,
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isCurrent
                                          ? AppColors.primaryGradient
                                          : LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                AppColors.brand3
                                                    .withOpacity(0.35),
                                                AppColors.brand3
                                                    .withOpacity(0.7),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                e.label.length > 3
                                    ? e.label.substring(0, 3)
                                    : e.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: isCurrent
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isCurrent ? AppColors.brand3 : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // هزینه بر اساس دسته
        _SectionCard(
          title: 'هزینه بر اساس دسته',
          subtitle: 'همین ماه انتخاب‌شده',
          child: cats.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'هزینه‌ای در این ماه ثبت نشده',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: cats.take(8).map((e) {
                    final pct = (e.value / maxCat).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                MoneyFormat.toman(e.value),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.outline.withOpacity(0.25),
                              color: AppColors.brand3,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 12),

        // آمار سریع
        _SectionCard(
          title: 'آمار سریع',
          subtitle: null,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStat(
                label: 'تعداد تراکنش ماه',
                value: MoneyFormat.toPersianDigits(
                    '${state.monthTransactions.length}'),
              ),
              _MiniStat(
                label: 'تعداد حساب‌ها',
                value: MoneyFormat.toPersianDigits('${state.accounts.length}'),
              ),
              _MiniStat(
                label: 'طلب از دیگران',
                value: MoneyFormat.toman(state.totalDebtOwed, withUnit: false),
              ),
              _MiniStat(
                label: 'اهداف مالی',
                value: MoneyFormat.toPersianDigits('${state.goals.length}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool wide;

  const _SumCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            MoneyFormat.toman(value, withUnit: false),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('تومان',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              )),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                )),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              )),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

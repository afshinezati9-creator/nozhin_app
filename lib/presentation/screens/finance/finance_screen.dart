import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/finance_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../providers/finance_provider.dart';
import 'accounts_pane.dart';
import 'overview_pane.dart';
import 'budget_pane.dart';
import 'debts_pane.dart';
import 'installments_pane.dart';
import 'goals_pane.dart';
import 'finance_onboarding.dart';
import 'transactions_pane.dart';
import 'purchase_intent_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final _subScroll = ScrollController();

  @override
  void dispose() {
    _subScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);

    if (state.isLoading && state.accounts.isEmpty) {
      return const AppLoading();
    }

    return Column(
      children: [
        // ساب‌تب‌های افقی
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          child: Column(
            children: [
              // فیکس: قصد خرید + داشبورد | بقیه تب‌ها اسکرول
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    // قصد خرید — ثابت
                    Material(
                      color: AppColors.brand3.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PurchaseIntentScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag_rounded,
                                  size: 18, color: AppColors.brand3),
                              const SizedBox(width: 6),
                              Text(
                                'قصد خرید',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.brand3,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // داشبورد — ثابت
                    _FixedTabChip(
                      selected: state.subTab == FinanceSubTab.overview,
                      icon: Icons.dashboard_rounded,
                      label: 'داشبورد',
                      onTap: () => ref
                          .read(financeProvider.notifier)
                          .setSubTab(FinanceSubTab.overview),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 24,
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    // بقیه تب‌ها — متحرک
                    Expanded(
                      child: ListView(
                        controller: _subScroll,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        children: [
                          for (final tab in FinanceSubTab.values
                              .where((t) => t != FinanceSubTab.overview))
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _FixedTabChip(
                                selected: state.subTab == tab,
                                label: tab.label,
                                onTap: () => ref
                                    .read(financeProvider.notifier)
                                    .setSubTab(tab),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // محتوا — اگر حسابی نیست، راه‌اندازی اولیه
        Expanded(
          child: state.accounts.isEmpty
              ? const FinanceOnboarding()
              : _buildBody(state, theme),
        ),
      ],
    );
  }

  Widget _buildBody(FinanceState state, ThemeData theme) {
    switch (state.subTab) {
      case FinanceSubTab.overview:
        return const OverviewPane();
      case FinanceSubTab.accounts:
        return const AccountsPane();
      case FinanceSubTab.transactions:
        return const TransactionsPane();
      case FinanceSubTab.budget:
        return const BudgetPane();
      case FinanceSubTab.debts:
        return const DebtsPane();
      case FinanceSubTab.installments:
        return const InstallmentsPane();
      case FinanceSubTab.goals:
        return const GoalsPane();
    }
  }
}

/// خلاصه — اسکلت فاز F0 (اعداد واقعی از state)

class _FixedTabChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _FixedTabChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 10 : 14,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: AppColors.brand3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PurchaseIntentScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 22,
                              color: AppColors.brand3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 40),
                      onPressed: () {
                        if (!_subScroll.hasClients) return;
                        _subScroll.animateTo(
                          (_subScroll.offset + 100)
                              .clamp(0.0, _subScroll.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _subScroll,
                        thumbVisibility: true,
                        thickness: 3,
                        radius: const Radius.circular(4),
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        child: ListView.separated(
                          controller: _subScroll,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          itemCount: FinanceSubTab.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            final tab = FinanceSubTab.values[i];
                            final sel = tab == state.subTab;
                            return GestureDetector(
                              onTap: () => ref
                                  .read(financeProvider.notifier)
                                  .setSubTab(tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient:
                                      sel ? AppColors.primaryGradient : null,
                                  color: sel
                                      ? null
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: sel
                                      ? null
                                      : Border.all(
                                          color: theme.colorScheme.outline),
                                ),
                                child: Text(
                                  tab.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: sel ? Colors.white : null,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 40),
                      onPressed: () {
                        if (!_subScroll.hasClients) return;
                        _subScroll.animateTo(
                          (_subScroll.offset - 100)
                              .clamp(0.0, _subScroll.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
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

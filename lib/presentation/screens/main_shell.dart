import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_header.dart';
import '../providers/theme_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/stickers_provider.dart';
import '../../core/constants/finance_constants.dart';
import 'notes/notes_screen.dart';
import 'notes/note_editor_screen.dart';
import 'finance/finance_screen.dart';
import 'finance/transactions_pane.dart';
import 'growth/growth_home_screen.dart';
import 'growth/create_journey_sheet.dart';
import '../providers/growth_provider.dart';
import 'info/info_screen.dart';
import 'stickers/stickers_screen.dart';
import 'info/info_form_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    NotesScreen(),
    FinanceScreen(),
    GrowthHomeScreen(),
    InfoScreen(),
    StickersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // پیش‌گرم داده توسعه فردی (آفلاین) هنگام ورود به شل
    Future.microtask(() {
      if (mounted) ref.read(growthProvider.notifier).load();
    });
  }

  Future<void> _onFabPressed() async {
    if (_currentIndex == 0) {
      final note = await ref.read(notesProvider.notifier).createNote();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => NoteEditorScreen(note: note, isNew: true)),
      );
      return;
    }

    if (_currentIndex == 1) {
      final accounts = ref.read(financeProvider).accounts;
      ref.read(financeProvider.notifier).setSubTab(
            accounts.isEmpty
                ? FinanceSubTab.overview
                : FinanceSubTab.transactions,
          );
      if (accounts.isEmpty) {
        // ویزارد راه‌اندازی همان صفحه مالی
        return;
      }
      // باز کردن مستقیم فرم تراکنش (بدون SnackBar که با FAB تداخل دارد)
      await showTransactionSheet(context);
      return;
    }

    if (_currentIndex == 2) {
      await showCreateJourneySheet(context);
      return;
    }

    if (_currentIndex == 3) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InfoFormScreen()),
      );
      return;
    }

    if (_currentIndex == 4) {
      ref.read(stickerFabTickProvider.notifier).state++;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppHeader(
        isDark: isDark,
        onThemeToggle: () {
          ref.read(themeProvider.notifier).toggleDarkLight();
        },
        onSettingsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // تب‌های اصلی بالای صفحه
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TopTab(
                    icon: Icons.note_alt_outlined,
                    activeIcon: Icons.note_alt_rounded,
                    label: AppStrings.tabNotes,
                    selected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: AppStrings.tabFinance,
                    selected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.spa_outlined,
                    activeIcon: Icons.spa_rounded,
                    label: AppStrings.tabPlanning,
                    selected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.info_outline_rounded,
                    activeIcon: Icons.info_rounded,
                    label: AppStrings.tabInfo,
                    selected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.sticky_note_2_outlined,
                    activeIcon: Icons.sticky_note_2_rounded,
                    label: AppStrings.tabStickers,
                    selected: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand3.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _TopTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.brand3
        : theme.colorScheme.onSurface.withOpacity(0.45);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brand3 : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, size: 20, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

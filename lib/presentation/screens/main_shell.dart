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
import 'info/info_screen.dart';
import 'stickers/stickers_screen.dart';
import 'info/info_form_screen.dart';
import 'settings/settings_screen.dart';

/// شل اصلی هاوژین — بدون تب توسعه فردی
/// ترتیب RTL (از راست): دم‌دستی | مالی | دفترچه★ | برچسب
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// پیش‌فرض: دفترچه (مرکز)
  int _currentIndex = 2;

  static const _kHandy = 0;
  static const _kFinance = 1;
  static const _kNotes = 2;
  static const _kStickers = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // فقط تب فعال ساخته می‌شود → استارت سبک‌تر از IndexedStack
    final body = switch (_currentIndex) {
      _kHandy => const InfoScreen(),
      _kFinance => const FinanceScreen(),
      _kNotes => const NotesScreen(),
      _kStickers => const StickersScreen(),
      _ => const NotesScreen(),
    };

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
                    icon: Icons.widgets_outlined,
                    activeIcon: Icons.widgets_rounded,
                    label: AppStrings.tabHandy,
                    selected: _currentIndex == _kHandy,
                    onTap: () => setState(() => _currentIndex = _kHandy),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: AppStrings.tabFinance,
                    selected: _currentIndex == _kFinance,
                    onTap: () => setState(() => _currentIndex = _kFinance),
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.note_alt_outlined,
                    activeIcon: Icons.note_alt_rounded,
                    label: AppStrings.tabNotes,
                    selected: _currentIndex == _kNotes,
                    onTap: () => setState(() => _currentIndex = _kNotes),
                    emphasize: true,
                  ),
                ),
                Expanded(
                  child: _TopTab(
                    icon: Icons.sticky_note_2_outlined,
                    activeIcon: Icons.sticky_note_2_rounded,
                    label: AppStrings.tabStickers,
                    selected: _currentIndex == _kStickers,
                    onTap: () => setState(() => _currentIndex = _kStickers),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
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

  Future<void> _onFabPressed() async {
    if (_currentIndex == _kNotes) {
      final note = await ref.read(notesProvider.notifier).createNote();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(note: note, isNew: true),
        ),
      );
      return;
    }

    if (_currentIndex == _kFinance) {
      final accounts = ref.read(financeProvider).accounts;
      ref.read(financeProvider.notifier).setSubTab(
            accounts.isEmpty
                ? FinanceSubTab.overview
                : FinanceSubTab.transactions,
          );
      if (accounts.isEmpty) return;
      await showTransactionSheet(context);
      return;
    }

    if (_currentIndex == _kHandy) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InfoFormScreen()),
      );
      return;
    }

    if (_currentIndex == _kStickers) {
      ref.read(stickerFabTickProvider.notifier).state++;
      return;
    }
  }
}

class _TopTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool emphasize;

  const _TopTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = emphasize && selected
        ? AppColors.brand3
        : selected
            ? AppColors.brand3
            : theme.colorScheme.onSurface.withOpacity(0.45);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: emphasize
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
            : EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          vertical: emphasize ? 8 : 10,
          horizontal: emphasize ? 4 : 0,
        ),
        decoration: BoxDecoration(
          color: emphasize && selected
              ? AppColors.brand3.withOpacity(0.12)
              : emphasize
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.35)
                  : null,
          borderRadius: emphasize ? BorderRadius.circular(14) : null,
          border: Border(
            bottom: BorderSide(
              color: selected && !emphasize
                  ? AppColors.brand3
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: emphasize ? 22 : 20,
              color: base,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: base,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: emphasize ? 12 : 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

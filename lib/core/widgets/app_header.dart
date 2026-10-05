import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';
import '../../presentation/widgets/nozhin_logo.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onThemeToggle;
  final VoidCallback? onSettingsTap;
  final bool isDark;

  const AppHeader({
    super.key,
    this.onThemeToggle,
    this.onSettingsTap,
    this.isDark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 14,
        right: 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand
          Row(
            children: [
              const NozhinLogo(size: 34),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  AppConstants.appName,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Theme toggle
          _HeaderIconButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: onThemeToggle,
          ),
          const SizedBox(width: 6),
          // Settings
          _HeaderIconButton(
            icon: Icons.settings_rounded,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}

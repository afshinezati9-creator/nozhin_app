import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// برند نوژین — NoteSprout (دفتر+برگ) و LifeRoots (ریشه+ابزار)
/// رنگ‌بندی بر اساس تم صفحه تا تداخل نداشته باشد.
enum NozhinLogoVariant { noteSprout, lifeRoots }

class NozhinLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool roundedAppIcon;
  final NozhinLogoVariant variant;
  /// اگر null باشد از رنگ primary تم استفاده می‌شود
  final Color? color;
  final bool useThemeTint;

  const NozhinLogo({
    super.key,
    this.size = 120,
    this.showWordmark = false,
    this.roundedAppIcon = false,
    this.variant = NozhinLogoVariant.noteSprout,
    this.color,
    this.useThemeTint = true,
  });

  String get _svg => variant == NozhinLogoVariant.lifeRoots
      ? 'assets/images/liferoots.svg'
      : 'assets/images/notesprout.svg';

  String get _png => variant == NozhinLogoVariant.lifeRoots
      ? 'assets/images/liferoots.png'
      : 'assets/images/notesprout.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = color ??
        (useThemeTint
            ? (isDark
                ? theme.colorScheme.primary.withOpacity(0.95)
                : theme.colorScheme.primary)
            : null);

    Widget mark = SvgPicture.asset(
      _svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: tint != null
          ? ColorFilter.mode(tint, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => Image.asset(
        _png,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: tint,
        colorBlendMode: tint != null ? BlendMode.srcIn : null,
        errorBuilder: (_, __, ___) => Icon(
          Icons.eco_rounded,
          size: size * 0.7,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    if (roundedAppIcon) {
      final bg = isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.primary.withOpacity(0.08);
      mark = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.15),
          ),
        ),
        padding: EdgeInsets.all(size * 0.12),
        child: mark,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: mark,
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.08),
          Text(
            'نوژین',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            'یادداشت‌هایی که رشد می‌کنند',
            style: TextStyle(
              fontSize: size * 0.08,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// برند هاوژین
/// - petals: لانچر / اسپلش
/// - bookLeaf: هدر (آیکون کتاب و برگ)
/// - ring: اختیاری
enum HawzhinLogoVariant { bookLeaf, petals, ring }

typedef NozhinLogoVariant = HawzhinLogoVariant;
typedef NozhinLogo = HawzhinLogo;

class HawzhinLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool roundedAppIcon;
  final HawzhinLogoVariant variant;

  const HawzhinLogo({
    super.key,
    this.size = 120,
    this.showWordmark = false,
    this.roundedAppIcon = false,
    this.variant = HawzhinLogoVariant.bookLeaf,
    // ignore: unused_element_parameter
    Color? color,
    // ignore: unused_element_parameter
    bool useThemeTint = false,
  });

  String get _asset {
    switch (variant) {
      case HawzhinLogoVariant.bookLeaf:
        return 'assets/icons/hawzhin/icon_book_leaf.png';
      case HawzhinLogoVariant.ring:
        return 'assets/icons/hawzhin/icon_book_leaf.png';
      case HawzhinLogoVariant.petals:
        return 'assets/icons/hawzhin/icon_petals.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget mark = Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco_rounded,
        size: size * 0.7,
        color: theme.colorScheme.primary,
      ),
    );

    if (roundedAppIcon) {
      final bg = isDark
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.primary.withOpacity(0.06);
      mark = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        padding: EdgeInsets.all(size * 0.06),
        child: mark,
      );
    }

    // هرگز Column در هدر — فقط باکس ثابت
    if (!showWordmark) {
      return SizedBox(
        width: size,
        height: size,
        child: mark,
      );
    }

    return SizedBox(
      width: size * 1.2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: size, height: size, child: mark),
          SizedBox(height: size * 0.06),
          Text(
            'هاوژین',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (size * 0.16).clamp(12, 28),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: theme.colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          Text(
            'دفترچه، مالی و دم‌دستی',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (size * 0.07).clamp(9, 14),
              color: theme.colorScheme.onSurface.withOpacity(0.55),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

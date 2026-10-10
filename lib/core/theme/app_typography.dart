import 'package:flutter/material.dart';

/// تایپوگرافی بر پایه فونت وزیرمتن
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Vazirmatn';

  // Display / Hero
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.4,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Caption / Label
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Mono (برای اعداد و مبالغ)
  static const TextStyle mono = TextStyle(
    fontFamily: 'JetBrains Mono', // بعداً محلی می‌شود
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle monoLarge = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

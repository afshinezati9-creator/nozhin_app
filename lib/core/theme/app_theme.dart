import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({
    double fontSizeFactor = 1.0,
    String fontFamily = 'Vazirmatn',
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      surface: AppColors.lightSurface,
      surface2: AppColors.lightSurface2,
      text: AppColors.lightText,
      text2: AppColors.lightText2,
      text3: AppColors.lightText3,
      border: AppColors.lightBorder,
      successSoft: AppColors.successSoft,
      dangerSoft: AppColors.dangerSoft,
      infoSoft: AppColors.infoSoft,
      purpleSoft: AppColors.purpleSoft,
      warnSoft: AppColors.warnSoft,
      fontSizeFactor: fontSizeFactor,
      fontFamily: fontFamily,
    );
  }

  static ThemeData dark({
    double fontSizeFactor = 1.0,
    String fontFamily = 'Vazirmatn',
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      surface2: AppColors.darkSurface2,
      text: AppColors.darkText,
      text2: AppColors.darkText2,
      text3: AppColors.darkText3,
      border: AppColors.darkBorder,
      successSoft: AppColors.successSoftDark,
      dangerSoft: AppColors.dangerSoftDark,
      infoSoft: AppColors.infoSoftDark,
      purpleSoft: AppColors.purpleSoftDark,
      warnSoft: AppColors.warnSoftDark,
      fontSizeFactor: fontSizeFactor,
      fontFamily: fontFamily,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color text,
    required Color text2,
    required Color text3,
    required Color border,
    required Color successSoft,
    required Color dangerSoft,
    required Color infoSoft,
    required Color purpleSoft,
    required Color warnSoft,
    required double fontSizeFactor,
    required String fontFamily,
  }) {
    final isDark = brightness == Brightness.dark;

    final baseTextTheme = TextTheme(

      displayLarge: AppTypography.displayLarge.copyWith(color: text, fontSize: 28 * fontSizeFactor),
      displayMedium: AppTypography.displayMedium.copyWith(color: text, fontSize: 22 * fontSizeFactor),
      headlineLarge: AppTypography.h1.copyWith(color: text, fontSize: 20 * fontSizeFactor),
      headlineMedium: AppTypography.h2.copyWith(color: text, fontSize: 17 * fontSizeFactor),
      headlineSmall: AppTypography.h3.copyWith(color: text, fontSize: 15 * fontSizeFactor),
      titleLarge: AppTypography.h4.copyWith(color: text, fontSize: 14 * fontSizeFactor),
      titleMedium: AppTypography.bodyLarge.copyWith(color: text, fontSize: 15 * fontSizeFactor),
      titleSmall: AppTypography.bodyMedium.copyWith(color: text2, fontSize: 14 * fontSizeFactor),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: text, fontSize: 15 * fontSizeFactor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: text2, fontSize: 14 * fontSizeFactor),
      bodySmall: AppTypography.bodySmall.copyWith(color: text3, fontSize: 13 * fontSizeFactor),
      labelLarge: AppTypography.button.copyWith(color: text, fontSize: 14 * fontSizeFactor),
      labelMedium: AppTypography.buttonSmall.copyWith(color: text2, fontSize: 12 * fontSizeFactor),
      labelSmall: AppTypography.overline.copyWith(color: text3, fontSize: 11 * fontSizeFactor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.brand3,
        onPrimary: Colors.white,
        secondary: AppColors.brand4,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        surfaceContainerHighest: surface2,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: text, fontSize: 15 * fontSizeFactor),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand3,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 14 * fontSizeFactor),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text2,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 13 * fontSizeFactor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand3,
          textStyle: AppTypography.button.copyWith(fontSize: 13 * fontSizeFactor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand3, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: text3, fontSize: 14 * fontSizeFactor),
        labelStyle: AppTypography.caption.copyWith(color: text2, fontSize: 12 * fontSizeFactor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.brand3,
        labelStyle: AppTypography.caption.copyWith(fontSize: 12 * fontSizeFactor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand3,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: text, fontSize: 17 * fontSizeFactor),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: text2, fontSize: 14 * fontSizeFactor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.brand3,
        unselectedItemColor: text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

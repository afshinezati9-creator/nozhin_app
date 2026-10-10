import 'package:flutter/material.dart';

/// رنگ‌های اصلی دقیقاً استخراج‌شده از دمو هاوژین v5.1
class AppColors {
  AppColors._();

  // ========== Brand / Gradient ==========
  static const Color brand1 = Color(0xFF38BDF8); // sky
  static const Color brand2 = Color(0xFF3B82F6); // blue
  static const Color brand3 = Color(0xFF6366F1); // indigo
  static const Color brand4 = Color(0xFF8B5CF6); // violet
  static const Color brand5 = Color(0xFFA855F7); // purple

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand2, brand4],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
  );

  static const LinearGradient softGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)],
  );

  // ========== Light Theme ==========
  static const Color lightBg = Color(0xFFF4F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFFAFBFC);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightText2 = Color(0xFF475569);
  static const Color lightText3 = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE5E9F0);

  // ========== Dark Theme ==========
  static const Color darkBg = Color(0xFF0A0F1C);
  static const Color darkSurface = Color(0xFF151E30);
  static const Color darkSurface2 = Color(0xFF1A2440);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkText2 = Color(0xFF94A3B8);
  static const Color darkText3 = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF243049);

  // ========== Semantic ==========
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color successSoftDark = Color(0xFF064E3B);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerSoftDark = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color infoSoftDark = Color(0xFF1E3A8A);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFEDE9FE);
  static const Color purpleSoftDark = Color(0xFF4C1D95);

  static const Color warn = Color(0xFFF59E0B);
  static const Color warnSoft = Color(0xFFFEF3C7);
  static const Color warnSoftDark = Color(0xFF78350F);

  static const Color pink = Color(0xFFEC4899);
  static const Color pinkSoft = Color(0xFFFCE7F3);
  static const Color pinkSoftDark = Color(0xFF831843);

  // ========== Summary Card (Finance) ==========
  static const LinearGradient summaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F1729)],
  );
}

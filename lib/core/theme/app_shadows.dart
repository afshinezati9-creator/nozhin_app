import 'package:flutter/material.dart';

/// سایه‌های استخراج‌شده از دمو
class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> md = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> xl = [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.16),
      blurRadius: 48,
      offset: const Offset(0, 24),
    ),
  ];

  static List<BoxShadow> fab = [
    BoxShadow(
      color: const Color(0xFF6366F1).withOpacity(0.45),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

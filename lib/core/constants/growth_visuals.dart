import 'package:flutter/material.dart';

/// پالت و آیکون جذاب هر برنامه — لعاب رنگی بدون تداخل تم
class GrowthVisual {
  final Color accent;
  final Color accentSoft;
  final IconData icon;
  final List<Color> gradient;

  const GrowthVisual({
    required this.accent,
    required this.accentSoft,
    required this.icon,
    required this.gradient,
  });
}

class GrowthVisuals {
  static const _map = <String, GrowthVisual>{
    'pomodoro': GrowthVisual(
      accent: Color(0xFF6366F1),
      accentSoft: Color(0xFFEEF2FF),
      icon: Icons.timer_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    'two_minute': GrowthVisual(
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFFFFFBEB),
      icon: Icons.bolt_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFF97316)],
    ),
    'daily_review': GrowthVisual(
      accent: Color(0xFF0EA5E9),
      accentSoft: Color(0xFFF0F9FF),
      icon: Icons.nightlight_round,
      gradient: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    ),
    'frog': GrowthVisual(
      accent: Color(0xFF22C55E),
      accentSoft: Color(0xFFF0FDF4),
      icon: Icons.priority_high_rounded,
      gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
    ),
    'eisenhower': GrowthVisual(
      accent: Color(0xFF8B5CF6),
      accentSoft: Color(0xFFF5F3FF),
      icon: Icons.grid_view_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    ),
    'habit_tracker': GrowthVisual(
      accent: Color(0xFF14B8A6),
      accentSoft: Color(0xFFF0FDFA),
      icon: Icons.checklist_rtl_rounded,
      gradient: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    ),
    'smart_goal': GrowthVisual(
      accent: Color(0xFFEC4899),
      accentSoft: Color(0xFFFDF2F8),
      icon: Icons.flag_rounded,
      gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ),
    'timeblock': GrowthVisual(
      accent: Color(0xFF3B82F6),
      accentSoft: Color(0xFFEFF6FF),
      icon: Icons.view_timeline_rounded,
      gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    'kaizen': GrowthVisual(
      accent: Color(0xFF10B981),
      accentSoft: Color(0xFFECFDF5),
      icon: Icons.trending_up_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    'deep_work': GrowthVisual(
      accent: Color(0xFF6366F1),
      accentSoft: Color(0xFFEEF2FF),
      icon: Icons.psychology_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF22C55E)],
    ),
    'five_s': GrowthVisual(
      accent: Color(0xFF0D9488),
      accentSoft: Color(0xFFF0FDFA),
      icon: Icons.cleaning_services_rounded,
      gradient: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    ),
    'kanban': GrowthVisual(
      accent: Color(0xFF2563EB),
      accentSoft: Color(0xFFEFF6FF),
      icon: Icons.view_column_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    ),
    'ikigai': GrowthVisual(
      accent: Color(0xFFE11D48),
      accentSoft: Color(0xFFFFF1F2),
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFE11D48), Color(0xFFF59E0B)],
    ),
    'gratitude': GrowthVisual(
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFFFFFBEB),
      icon: Icons.volunteer_activism_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    'mood_tracker': GrowthVisual(
      accent: Color(0xFFA855F7),
      accentSoft: Color(0xFFFAF5FF),
      icon: Icons.sentiment_satisfied_alt_rounded,
      gradient: [Color(0xFFA855F7), Color(0xFFEC4899)],
    ),
    'growth_mindset': GrowthVisual(
      accent: Color(0xFF059669),
      accentSoft: Color(0xFFECFDF5),
      icon: Icons.spa_rounded,
      gradient: [Color(0xFF059669), Color(0xFF34D399)],
    ),
    'pdca': GrowthVisual(
      accent: Color(0xFFEA580C),
      accentSoft: Color(0xFFFFF7ED),
      icon: Icons.loop_rounded,
      gradient: [Color(0xFFEA580C), Color(0xFFF59E0B)],
    ),
    'hoshin': GrowthVisual(
      accent: Color(0xFF7C3AED),
      accentSoft: Color(0xFFF5F3FF),
      icon: Icons.account_tree_rounded,
      gradient: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    ),
    'wheel': GrowthVisual(
      accent: Color(0xFFF43F5E),
      accentSoft: Color(0xFFFFF1F2),
      icon: Icons.donut_large_rounded,
      gradient: [Color(0xFFF43F5E), Color(0xFFFB923C)],
    ),
    'cbt_journal': GrowthVisual(
      accent: Color(0xFF0284C7),
      accentSoft: Color(0xFFF0F9FF),
      icon: Icons.edit_note_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF6366F1)],
    ),
    'swot': GrowthVisual(
      accent: Color(0xFF0F766E),
      accentSoft: Color(0xFFF0FDFA),
      icon: Icons.analytics_rounded,
      gradient: [Color(0xFF0F766E), Color(0xFF3B82F6)],
    ),
    'pareto': GrowthVisual(
      accent: Color(0xFFB45309),
      accentSoft: Color(0xFFFFFBEB),
      icon: Icons.pie_chart_rounded,
      gradient: [Color(0xFFB45309), Color(0xFFEF4444)],
    ),
    'gtd_next': GrowthVisual(
      accent: Color(0xFF4F46E5),
      accentSoft: Color(0xFFEEF2FF),
      icon: Icons.subdirectory_arrow_left_rounded,
      gradient: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
    ),
    'okr_lite': GrowthVisual(
      accent: Color(0xFFDB2777),
      accentSoft: Color(0xFFFDF2F8),
      icon: Icons.track_changes_rounded,
      gradient: [Color(0xFFDB2777), Color(0xFF8B5CF6)],
    ),
  };

  static GrowthVisual of(String programId) {
    return _map[programId] ??
        const GrowthVisual(
          accent: Color(0xFF6366F1),
          accentSoft: Color(0xFFEEF2FF),
          icon: Icons.spa_rounded,
          gradient: [Color(0xFF6366F1), Color(0xFF22C55E)],
        );
  }
}

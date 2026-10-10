import 'package:flutter/material.dart';

IconData programIcon(String id) {
  switch (id) {
    case 'kaizen':
      return Icons.trending_up_rounded;
    case 'fiveS':
      return Icons.grid_view_rounded;
    case 'kanban':
      return Icons.view_column_rounded;
    case 'ikigai':
      return Icons.favorite_rounded;
    case 'pdca':
      return Icons.loop_rounded;
    case 'hoshin':
      return Icons.flag_rounded;
    case 'pomodoro':
      return Icons.timer_rounded;
    case 'deepwork':
      return Icons.psychology_rounded;
    case 'frog':
      return Icons.priority_high_rounded;
    case 'twoMin':
      return Icons.bolt_rounded;
    case 'mood':
      return Icons.sentiment_satisfied_alt_rounded;
    case 'gratitude':
      return Icons.volunteer_activism_rounded;
    case 'cbt':
      return Icons.psychology_alt_rounded;
    case 'growth':
      return Icons.spa_rounded;
    case 'eisen':
      return Icons.dashboard_customize_rounded;
    case 'smart':
      return Icons.track_changes_rounded;
    case 'timeblock':
      return Icons.calendar_view_day_rounded;
    case 'wheel':
      return Icons.donut_large_rounded;
    case 'habits':
      return Icons.local_fire_department_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color programColor(String id) {
  switch (id) {
    case 'pomodoro':
    case 'habits':
      return const Color(0xFFEF4444);
    case 'eisen':
    case 'kanban':
      return const Color(0xFF3B82F6);
    case 'mood':
    case 'ikigai':
      return const Color(0xFFEC4899);
    case 'kaizen':
    case 'gratitude':
    case 'frog':
      return const Color(0xFF10B981);
    case 'pdca':
    case 'timeblock':
    case 'twoMin':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF8B5CF6);
  }
}

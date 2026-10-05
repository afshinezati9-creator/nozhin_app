import 'package:flutter/material.dart';
import '../../../core/utils/jalali.dart';
import '../../../core/utils/money_format.dart';

/// روزهای هفته شمسی: شنبه … جمعه
const kShamsiWeekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
const kShamsiWeekdaysFull = [
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
];

/// ایندکس روز هفته شمسی (۰=شنبه … ۶=جمعه)
int shamsiWeekdayIndex(DateTime d) {
  // DateTime.weekday: 1=Mon … 7=Sun
  // شمسی: شنبه بعد از جمعه
  // Mon=1 → دوشنبه=2, ..., Sat=6 → شنبه=0, Sun=7 → یکشنبه=1
  final w = d.weekday; // 1..7
  if (w == 7) return 1; // یکشنبه
  if (w == 6) return 0; // شنبه
  return w + 1; // Mon→2 … Fri→6
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// شبکه هفته شمسی (شنبه تا جمعه)
class WeekGridShamsi extends StatelessWidget {
  final DateTime weekStart; // باید شنبه باشد یا نزدیک‌ترین شنبه قبل
  final Set<String> completedKeys;
  final ValueChanged<DateTime>? onToggleDay;
  final Color? accent;
  final bool animateTick;

  const WeekGridShamsi({
    super.key,
    required this.weekStart,
    this.completedKeys = const {},
    this.onToggleDay,
    this.accent,
    this.animateTick = true,
  });

  /// شنبهٔ همان هفته برای تاریخ [d]
  static DateTime saturdayOf(DateTime d) {
    final only = dateOnly(d);
    final idx = shamsiWeekdayIndex(only);
    return only.subtract(Duration(days: idx));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    final start = saturdayOf(weekStart);
    final today = dateOnly(DateTime.now());

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  kShamsiWeekdays[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(7, (i) {
            final day = start.add(Duration(days: i));
            final key = dateKey(day);
            final done = completedKeys.contains(key);
            final isToday = day == today;
            final j = Jalali.fromDateTime(day);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: done
                        ? color
                        : theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onToggleDay == null
                          ? null
                          : () => onToggleDay!(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? Border.all(color: color, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              MoneyFormat.toPersianDigits('${j.day}'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: done ? Colors.white : null,
                              ),
                            ),
                            if (done)
                              const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// نوار ۳۰ روز (ماه جاری تقریبی از امروز به عقب/جلو)
class MonthStripShamsi extends StatelessWidget {
  final DateTime anchor;
  final Map<String, int> scores; // dateKey -> 1..5 یا 0/1
  final ValueChanged<DateTime>? onDayTap;
  final int days;
  final Color? accent;

  const MonthStripShamsi({
    super.key,
    required this.anchor,
    this.scores = const {},
    this.onDayTap,
    this.days = 30,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    final today = dateOnly(DateTime.now());
    // ۳۰ روز: از (today - 29) تا today برای مود/کایزن
    final start = today.subtract(Duration(days: days - 1));

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final day = start.add(Duration(days: i));
          final key = dateKey(day);
          final score = scores[key];
          final j = Jalali.fromDateTime(day);
          final isToday = day == today;
          final has = score != null && score > 0;

          return InkWell(
            onTap: onDayTap == null ? null : () => onDayTap!(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: has
                    ? color.withOpacity(0.15 + (score!.clamp(1, 5) / 5) * 0.35)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(color: color, width: 2)
                    : Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    MoneyFormat.toPersianDigits('${j.day}'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    j.monthName.substring(0, 2),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (has)
                    Text(
                      MoneyFormat.toPersianDigits('$score'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// جدول ۲۴ ساعته برای تایم‌بلاک
class DayTimelineShamsi extends StatelessWidget {
  final Map<int, String> hourLabels; // 0..23 -> activity id/name
  final ValueChanged<int>? onHourTap;
  final Color Function(String label)? colorOf;

  const DayTimelineShamsi({
    super.key,
    this.hourLabels = const {},
    this.onHourTap,
    this.colorOf,
  });

  static const presets = <String, Color>{
    'خواب': Color(0xFF6366F1),
    'غذا': Color(0xFFF59E0B),
    'ورزش': Color(0xFF10B981),
    'کار': Color(0xFF3B82F6),
    'مطالعه': Color(0xFF8B5CF6),
    'استراحت': Color(0xFF94A3B8),
    'خانواده': Color(0xFFEC4899),
    'عبادت': Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(24, (h) {
        final label = hourLabels[h];
        final c = label == null
            ? null
            : (colorOf?.call(label) ??
                presets[label] ??
                theme.colorScheme.primary);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: c?.withOpacity(0.18) ??
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onHourTap == null ? null : () => onHourTap!(h),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        MoneyFormat.toPersianDigits(
                            '${h.toString().padLeft(2, '0')}:00'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        label ?? 'خالی — بزن برای انتخاب',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: label == null
                              ? theme.colorScheme.onSurface.withOpacity(0.4)
                              : null,
                          fontWeight:
                              label == null ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (c != null)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../domain/entities/habit_entity.dart';
import '../../providers/planning_provider.dart';

class HabitsPane extends ConsumerWidget {
  const HabitsPane({super.key});

  /// شنبه تا جمعه (هفته شمسی‌وار: از شنبه)
  List<DateTime> _weekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // DateTime.weekday: Mon=1 ... Sun=7 → تبدیل به شنبه=شروع
    // شنبه در DateTime: weekday==6
    final daysFromSat = (today.weekday % 7); // Sat=0 ... Fri=6
    final sat = today.subtract(Duration(days: daysFromSat));
    return List.generate(7, (i) => sat.add(Duration(days: i)));
  }

  int _streak(HabitEntity h) {
    var streak = 0;
    var d = DateTime.now();
    d = DateTime(d.year, d.month, d.day);
    // اگر امروز نزده، از دیروز شروع کن
    if (!h.isDoneOn(d)) {
      d = d.subtract(const Duration(days: 1));
    }
    while (h.isDoneOn(d)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _weekRate(HabitEntity h, List<DateTime> week) {
    if (week.isEmpty) return 0;
    final done = week.where((d) => h.isDoneOn(d)).length;
    return done / week.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planningProvider);
    final theme = Theme.of(context);
    final habits = state.activeHabits;
    final week = _weekDays();
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final doneToday = habits.where((h) => h.isDoneOn(todayKey)).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'امروز',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormat.toPersianDigits('$doneToday')} از ${MoneyFormat.toPersianDigits('${habits.length}')} عادت',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.brand3,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openForm(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        // هدر روزهای هفته
        if (habits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Row(
              children: [
                const SizedBox(width: 88),
                ...week.map((d) {
                  final isToday = d.year == todayKey.year &&
                      d.month == todayKey.month &&
                      d.day == todayKey.day;
                  final j = Jalali.fromDateTime(d);
                  const names = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
                  final idx = d.weekday % 7; // Sat=0
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          names[idx],
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isToday ? FontWeight.w900 : FontWeight.w600,
                            color: isToday
                                ? AppColors.brand3
                                : theme.colorScheme.onSurface.withOpacity(0.45),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          MoneyFormat.toPersianDigits('${j.day}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: isToday
                                ? AppColors.brand3
                                : theme.colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(width: 36),
              ],
            ),
          ),
        Expanded(
          child: habits.isEmpty
              ? AppEmptyState(
                  icon: Icons.local_fire_department_outlined,
                  message:
                      'هنوز عادتی نداری\nبا + عادت روزانه بساز (ورزش، مطالعه، ...)',
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(planningProvider.notifier).load(),
                  color: AppColors.brand3,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: habits.length,
                    itemBuilder: (_, i) {
                      final h = habits[i];
                      final streak = _streak(h);
                      final rate = _weekRate(h, week);
                      return _HabitRow(
                        habit: h,
                        week: week,
                        today: todayKey,
                        streak: streak,
                        weekRate: rate,
                        onToggle: (day) => ref
                            .read(planningProvider.notifier)
                            .toggleHabitDay(h, day),
                        onEdit: () => _openForm(context, ref, existing: h),
                        onDelete: () => _confirmDelete(context, ref, h),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, HabitEntity h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف عادت'),
        content: Text('«${h.title}» و تاریخچه تیک‌ها حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(planningProvider.notifier).deleteHabit(h.id);
    }
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {HabitEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HabitFormSheet(existing: existing),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final HabitEntity habit;
  final List<DateTime> week;
  final DateTime today;
  final int streak;
  final double weekRate;
  final void Function(DateTime day) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitRow({
    required this.habit,
    required this.week,
    required this.today,
    required this.streak,
    required this.weekRate,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _color {
    switch (habit.color) {
      case 'red':
        return const Color(0xFFEF4444);
      case 'green':
        return const Color(0xFF10B981);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'orange':
        return const Color(0xFFF59E0B);
      case 'pink':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: onEdit,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            streak > 0
                                ? '🔥 ${MoneyFormat.toPersianDigits('$streak')} روز پشت سر هم · ${MoneyFormat.toPersianDigits((weekRate * 100).round().toString())}٪ هفته'
                                : '${MoneyFormat.toPersianDigits((weekRate * 100).round().toString())}٪ این هفته',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.35)),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 16),
                  ...week.map((d) {
                    final done = habit.isDoneOn(d);
                    final isToday = d.year == today.year &&
                        d.month == today.month &&
                        d.day == today.day;
                    final future = d.isAfter(today);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Material(
                            color: done
                                ? _color
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: future ? null : () => onToggle(d),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isToday
                                        ? AppColors.brand3
                                        : theme.colorScheme.outline,
                                    width: isToday ? 1.5 : 1,
                                  ),
                                ),
                                child: done
                                    ? const Icon(Icons.check_rounded,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitFormSheet extends ConsumerStatefulWidget {
  final HabitEntity? existing;
  const _HabitFormSheet({this.existing});

  @override
  ConsumerState<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<_HabitFormSheet> {
  late final TextEditingController _titleCtrl;
  late String _color;
  bool _saving = false;

  static const _colors = {
    'purple': Color(0xFF8B5CF6),
    'red': Color(0xFFEF4444),
    'green': Color(0xFF10B981),
    'blue': Color(0xFF3B82F6),
    'orange': Color(0xFFF59E0B),
    'pink': Color(0xFFEC4899),
  };

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.existing?.title ?? '');
    _color = widget.existing?.color ?? 'purple';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('نام عادت را وارد کن'),
        behavior: SnackBarBehavior.fixed,
      ));
      return;
    }
    if (title.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('نام عادت خیلی بلند است'),
        behavior: SnackBarBehavior.fixed,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      if (isEdit) {
        await ref.read(planningProvider.notifier).updateHabit(
              widget.existing!.copyWith(title: title, color: _color),
            );
      } else {
        await ref
            .read(planningProvider.notifier)
            .addHabit(title, color: _color);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isEdit ? 'ویرایش عادت' : 'عادت جدید',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'نام عادت',
                hintText: 'مثلاً ورزش، مطالعه، نوشیدن آب',
              ),
            ),
            const SizedBox(height: 14),
            Text('رنگ', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: _colors.entries.map((e) {
                final sel = e.key == _color;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = e.key),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: e.value.withOpacity(0.5),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEdit ? 'ذخیره' : 'ثبت عادت',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

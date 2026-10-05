import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../providers/growth_provider.dart';
import 'history_screen.dart';
import 'journeys_screen.dart';
import 'program_learn_flow.dart';

/// مرور دوره‌ای + بازگشت نرم بعد از مکث (T8)
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _note = TextEditingController();
  int _weekFeel = 3;
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final growth = ref.watch(growthProvider);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekSessions = growth.sessions
        .where((s) => (s.endedAt ?? s.startedAt).isAfter(weekAgo))
        .toList();
    final paused = growth.pausedJourneys;
    final active = growth.activeJourneys;

    return Scaffold(
      appBar: AppBar(title: const Text('مرور و بازگشت')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Welcome back / soft return
          if (paused.isNotEmpty)
            _Banner(
              color: AppColors.warn,
              icon: Icons.waving_hand_rounded,
              title: GrowthStrings.welcomeBack,
              body:
                  '${paused.length} مسیر در حالت مکث است. می‌توانی بدون فشار یکی را از سر بگیری.',
              action: 'مسیرهای من',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JourneysScreen()),
                );
              },
            ),

          _Banner(
            color: AppColors.brand3,
            icon: Icons.auto_awesome_rounded,
            title: 'مرور این هفته',
            body: weekSessions.isEmpty
                ? 'این هفته اجرایی ثبت نشده. یک قدم کوچک هم کافی است.'
                : '${weekSessions.length} اجرا در ۷ روز اخیر ثبت شده.',
            action: 'تاریخچه',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 8),
          Text(
            'مسیرهای فعال',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (active.isEmpty)
            Text(
              'مسیر فعالی نیست.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          else
            ...active.map((j) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.brand3.withOpacity(0.2)),
                ),
                child: ListTile(
                  title: Text(j.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: j.reason.isEmpty ? null : Text(j.reason),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JourneysScreen()),
                    );
                  },
                ),
              );
            }),

          const SizedBox(height: 12),
          Text(
            'اجراهای اخیر برای ادامه',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...() {
            final recent = growth.sessions.take(5).toList();
            if (recent.isEmpty) {
              return [
                Text(
                  GrowthStrings.emptyHistory,
                  style: theme.textTheme.bodySmall,
                ),
              ];
            }
            return recent.map((s) {
              final name =
                  GrowthCatalog.byId(s.programId)?.nameFa ?? s.programId;
              final v = GrowthVisuals.of(s.programId);
              final when = Jalali.fromDateTime(s.endedAt ?? s.startedAt)
                  .format(withMonthName: true);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: v.accent.withOpacity(0.15),
                    child: Icon(v.icon, color: v.accent, size: 20),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(when),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProgramEntryScreen(programId: s.programId),
                        ),
                      );
                    },
                    child: const Text('بازگشت'),
                  ),
                ),
              );
            }).toList();
          }(),

          const SizedBox(height: 16),
          Text(
            'حس کلی این دوره (اختیاری)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            value: _weekFeel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.brand3,
            label: '$_weekFeel',
            onChanged: (v) => setState(() => _weekFeel = v.round()),
          ),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'یک جمله از این دوره',
              hintText: 'چه چیزی را فهمیدی؟',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() => _saved = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('مرور ثبت شد — فقط برای خودت'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
            child: Text(_saved ? 'ثبت شد ✓' : 'ذخیره مرور'),
          ),
          const SizedBox(height: 8),
          Text(
            GrowthStrings.pauseIsOk,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onTap, child: Text(action)),
          ),
        ],
      ),
    );
  }
}

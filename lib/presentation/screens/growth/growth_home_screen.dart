import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../../domain/entities/growth/growth_session.dart';
import '../../providers/growth_provider.dart';
import 'create_journey_sheet.dart';
import 'history_screen.dart';
import 'journeys_screen.dart';
import 'program_library_screen.dart';
import 'program_learn_flow.dart';
import 'review_screen.dart';
import 'sensor_screen.dart';

/// خانه توسعه فردی — صیقل UX (T10)
class GrowthHomeScreen extends ConsumerWidget {
  const GrowthHomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صبح بخیر';
    if (h < 17) return 'ظهر بخیر';
    if (h < 21) return 'عصر بخیر';
    return 'شب بخیر';
  }

  String _dailyHint() {
    const hints = [
      'امروز فقط یک قدم کوچک کافی است.',
      'لازم نیست کامل باشی؛ کافی است واقعی تجربه کنی.',
      'اگر وقت کم است، همان ۵ دقیقه هم ارزش دارد.',
      'رشد یعنی ادامه دادن، نه بی‌نقص بودن.',
      'می‌توانی اول فقط یاد بگیری؛ بعد عمل کنی.',
    ];
    return hints[DateTime.now().day % hints.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final growth = ref.watch(growthProvider);
    final active = growth.activeJourneys;
    final resume = growth.activeSession;
    final dateLabel = Jalali.nowString(withMonthName: true, withTime: false);

    if (growth.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(growthProvider.notifier).load(),
      color: AppColors.brand3,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (growth.error != null)
            SliiverPad(
              child: Material(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('خطا در بارگذاری داده رشد'),
                  subtitle: Text('${growth.error}'),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(growthProvider.notifier).load(),
                    child: const Text('تلاش دوباره'),
                  ),
                ),
              ),
            ),

          // داشبورد خوش‌آمد — پالت جذاب
          SliiverPad(
            bottom: 12,
            child: _WelcomePalette(
              greeting: _greeting(),
              dateLabel: dateLabel,
              hint: _dailyHint(),
              isDark: isDark,
            ),
          ),

          // یادگیری جلوی چشم
          SliiverPad(
            child: _LearningSpotlight(
              onLibrary: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProgramLibraryScreen()),
              ),
              onHowTo: () => _showGrowthHowTo(context),
            ),
          ),

          // Resume banner
          if (resume != null)
            SliiverPad(
              child: _ResumeBanner(
                session: resume,
                onContinue: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgramEntryScreen(
                        programId: resume.programId,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Hero CTA
          SliiverPad(
            child: _HeroCard(
              isDark: isDark,
              hasActive: active.isNotEmpty,
              activeTitle: active.isNotEmpty ? active.first.title : null,
              onPrimary: () {
                if (active.isEmpty) {
                  showCreateJourneySheet(context);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JourneysScreen()),
                  );
                }
              },
              onSecondary: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SensorScreen()),
                );
              },
            ),
          ),

          // Quick actions grid
          SliiverPad(
            child: _SectionTitle('میان‌برها'),
          ),
          SliiverPad(
            child: _QuickGrid(
              items: [
                _QuickItem(
                  icon: Icons.explore_rounded,
                  label: 'سنسور',
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SensorScreen()),
                  ),
                ),
                _QuickItem(
                  icon: Icons.menu_book_rounded,
                  label: 'کتابخانه',
                  color: AppColors.brand3,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProgramLibraryScreen()),
                  ),
                ),
                _QuickItem(
                  icon: Icons.route_rounded,
                  label: 'مسیرها',
                  color: const Color(0xFF22C55E),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JourneysScreen()),
                  ),
                ),
                _QuickItem(
                  icon: Icons.history_edu_rounded,
                  label: 'نتایج',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                _QuickItem(
                  icon: Icons.refresh_rounded,
                  label: 'مرور',
                  color: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewScreen()),
                  ),
                ),
                _QuickItem(
                  icon: Icons.add_rounded,
                  label: 'مسیر نو',
                  color: const Color(0xFFEC4899),
                  onTap: () => showCreateJourneySheet(context),
                ),
              ],
            ),
          ),

          // Active journeys
          if (active.isNotEmpty) ...[
            SliiverPad(child: _SectionTitle('ادامه مسیر')),
            ...active.take(3).map(
                  (j) => SliiverPad(
                    child: _JourneyMini(
                      title: j.title,
                      reason: j.reason,
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const JourneysScreen()),
                      ),
                      onPause: () =>
                          ref.read(growthProvider.notifier).pause(j.id),
                    ),
                  ),
                ),
            if (active.length >= GrowthNotifier.maxSoftActive)
              SliiverPad(
                child: _SoftTip(
                  text:
                      'چند مسیر فعال داری. تمرکز روی یکی-دو مورد معمولاً بهتر جواب می‌دهد.',
                ),
              ),
          ],

          // Last insight
          if (growth.sessions.any((s) => s.status == SessionStatus.evaluated))
            SliiverPad(
              child: _LastInsightCard(
                sessions: (growth.sessions
                        .where((s) => s.status == SessionStatus.evaluated)
                        .toList()
                      ..sort((a, b) => (b.endedAt ?? b.startedAt)
                          .compareTo(a.endedAt ?? a.startedAt))),
              ),
            ),

          // Learn tip
          SliiverPad(
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withOpacity(isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      GrowthStrings.learnCarryOutside,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// padding helper sliver
class SliiverPad extends StatelessWidget {
  final Widget child;
  final double bottom;
  const SliiverPad({super.key, required this.child, this.bottom = 10});

  @override
  Widget build(BuildContext context) {
    return SliiverToBoxAdapterSafe(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
        child: child,
      ),
    );
  }
}

class SliiverToBoxAdapterSafe extends StatelessWidget {
  final Widget child;
  const SliiverToBoxAdapterSafe({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: child);
}


void _showGrowthHowTo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      const steps = <List<String>>[
        ['۱', 'نیازت را بشناس', 'با «سنسور» یا کمک انتخاب، بفهم الان روی چه چیزی کار کنی.'],
        ['۲', 'یک مسیر بساز', 'مسیر یعنی موضوع رشد تو. لازم نیست همه برنامه‌ها را باز کنی.'],
        ['۳', 'برنامه را یاد بگیر', 'در کتابخانه هر برنامه آموزش دارد؛ طوری که بدون اپ هم بتوانی همان روش را انجام دهی.'],
        ['۴', 'اجرا کن', 'حالت آموزش یا شروع سریع. ذخیره می‌شود و می‌توانی ادامه دهی.'],
        ['۵', 'ارزیابی و قدم بعدی', 'بعد از اجرا بگو چه شد و قدم بعدی را آگاهانه انتخاب کن.'],
        ['۶', 'مرور', 'گاهی نتایج و مرور را ببین تا الگوی خودت را بشناسی.'],
      ];
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'چطور با توسعه فردی کار کنم؟',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'این تب تمرین پراکنده نیست؛ یک چرخه است: فهمیدن ← انتخاب ← یادگیری ← عمل ← ثبت ← ارزیابی ← قدم بعدی.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              for (final s in steps)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.brand3.withOpacity(0.2),
                    ),
                    color: AppColors.brand3.withOpacity(0.06),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.brand3,
                        child: Text(
                          s[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s[1],
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s[2],
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'یادگیری عمداً جلوی چشم است: اول بفهم روش چیست، بعد اجرا کن. فشار زنجیره یا امتیاز اجباری اینجا هدف نیست.',
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _WelcomePalette extends StatelessWidget {
  final String greeting;
  final String dateLabel;
  final String hint;
  final bool isDark;
  const _WelcomePalette({
    required this.greeting,
    required this.dateLabel,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? const [
                  Color(0xFF1E3A5F),
                  Color(0xFF0F766E),
                  Color(0xFF134E4A),
                ]
              : const [
                  Color(0xFFECFDF5),
                  Color(0xFFE0E7FF),
                  Color(0xFFFAF5FF),
                ],
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF134E4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF0F766E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2DD4BF), const Color(0xFF6366F1)]
                        : [const Color(0xFF14B8A6), const Color(0xFF6366F1)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.spa_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSpotlight extends StatelessWidget {
  final VoidCallback onLibrary;
  final VoidCallback onHowTo;
  const _LearningSpotlight({
    required this.onLibrary,
    required this.onHowTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'یادگیری اول — بعد عمل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            GrowthStrings.learnCarryOutside,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onLibrary,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('کتابخانه و آموزش'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onHowTo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('چطور؟'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isDark;
  final bool hasActive;
  final String? activeTitle;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _HeroCard({
    required this.isDark,
    required this.hasActive,
    required this.onPrimary,
    required this.onSecondary,
    this.activeTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.brand3.withOpacity(0.22),
                  theme.colorScheme.surfaceContainerHighest,
                ]
              : [
                  AppColors.brand3.withOpacity(0.12),
                  Colors.white,
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand3.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            GrowthStrings.homeTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasActive
                ? 'مسیر فعال: $activeTitle'
                : GrowthStrings.emptyHome,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand3,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasActive
                        ? GrowthStrings.continueLabel
                        : GrowthStrings.firstJourney,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(GrowthStrings.helpChoose),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  final List<_QuickItem> items;
  const _QuickGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: items.map((e) => _QuickTile(item: e)).toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: item.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.color.withOpacity(0.18)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyMini extends StatelessWidget {
  final String title;
  final String reason;
  final VoidCallback onOpen;
  final VoidCallback onPause;
  const _JourneyMini({
    required this.title,
    required this.reason,
    required this.onOpen,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    if (reason.isNotEmpty)
                      Text(reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: onPause,
              child: const Text(GrowthStrings.pause),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  final GrowthSession session;
  final VoidCallback onContinue;
  const _ResumeBanner({required this.session, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final name =
        GrowthCatalog.byId(session.programId)?.nameFa ?? session.programId;
    final v = GrowthVisuals.of(session.programId);
    return Material(
      color: v.accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onContinue,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: v.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GrowthStrings.resume,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: v.accent,
                      ),
                    ),
                    Text(name, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: v.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftTip extends StatelessWidget {
  final String text;
  const _SoftTip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warn.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
    );
  }
}

class _LastInsightCard extends StatelessWidget {
  final List<GrowthSession> sessions;
  const _LastInsightCard({required this.sessions});

  String _nextLabel(NextStepKind? k) {
    switch (k) {
      case NextStepKind.continueSame:
        return 'ادامه همین روش';
      case NextStepKind.makeEasier:
        return 'ساده‌تر کردن';
      case NextStepKind.tryOtherMethod:
        return 'روش دیگر';
      case NextStepKind.pause:
        return 'مکث';
      case NextStepKind.review:
        return 'مرور';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sessions.isEmpty) return const SizedBox.shrink();
    final s = sessions.first;
    final name = GrowthCatalog.byId(s.programId)?.nameFa ?? 'برنامه';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand3.withOpacity(0.2)),
        color: AppColors.brand3.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            GrowthStrings.lastInsight,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$name · قدم بعدی: ${_nextLabel(s.nextStep)}',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (s.nextStepNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              s.nextStepNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

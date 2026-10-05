import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../providers/growth_provider.dart';
import 'program_intro_screen.dart';
import 'program_session_screen.dart';

/// Learn Mode پویا — کارت‌های بصری، نه متن تخت (T4/T5)
class ProgramLearnFlow extends StatefulWidget {
  final String programId;
  final String? journeyId;
  const ProgramLearnFlow({
    super.key,
    required this.programId,
    this.journeyId,
  });

  @override
  State<ProgramLearnFlow> createState() => _ProgramLearnFlowState();
}

class _ProgramLearnFlowState extends State<ProgramLearnFlow> {
  int page = 0;

  Color _accentFor(String id) {
    switch (id) {
      case 'pomodoro':
        return AppColors.brand3;
      case 'two_minute':
        return const Color(0xFFF59E0B);
      case 'daily_review':
        return const Color(0xFF38BDF8);
      case 'frog':
        return const Color(0xFF22C55E);
      default:
        return AppColors.brand3;
    }
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'pomodoro':
        return Icons.timer_rounded;
      case 'two_minute':
        return Icons.bolt_rounded;
      case 'daily_review':
        return Icons.nightlight_round;
      case 'frog':
        return Icons.priority_high_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = GrowthCatalog.byId(widget.programId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('برنامه پیدا نشد')),
      );
    }

    final accent = GrowthVisuals.of(p.id).accent;
    final steps = p.howSteps
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final pages = <Widget>[
      _VisualPage(
        accent: accent,
        icon: GrowthVisuals.of(p.id).icon,
        badge: 'آشنایی',
        title: p.nameFa,
        subtitle: p.oneLiner,
        cards: [
          _InfoCard(
            title: 'این چیست؟',
            body: p.whatIs,
            color: accent,
          ),
          _InfoCard(
            title: 'چرا مهم است؟',
            body: p.whyMatters,
            color: accent.withOpacity(0.85),
          ),
        ],
      ),
      _VisualPage(
        accent: accent,
        icon: Icons.map_rounded,
        badge: 'نقشه',
        title: 'چطور اجرا می‌شود؟',
        subtitle: 'مراحل قابل انجام حتی بدون اپ',
        cards: [
          for (var i = 0; i < steps.length; i++)
            _StepCard(
              index: i + 1,
              text: steps[i],
              color: accent,
            ),
        ],
      ),
      _VisualPage(
        accent: accent,
        icon: Icons.insights_rounded,
        badge: 'سنجش',
        title: 'چه چیزی را می‌بینیم؟',
        subtitle: 'داده عینی جدا از قضاوت سخت‌گیرانه',
        cards: [
          for (final c in p.learnCriteria)
            _InfoCard(title: 'معیار', body: c, color: accent),
          _InfoCard(
            title: 'حد انتظار واقع‌بینانه',
            body: p.notFor,
            color: const Color(0xFFF59E0B),
          ),
          _InfoCard(
            title: GrowthStrings.learnCarryOutside,
            body: 'این مراحل را می‌توانی روی کاغذ هم تکرار کنی.',
            color: const Color(0xFF38BDF8),
          ),
        ],
      ),
    ];

    final theme = Theme.of(context);
    final last = page >= pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${GrowthStrings.learnMode} · ${p.nameFa}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: List.generate(pages.length, (i) {
                final on = i <= page;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: on
                          ? accent
                          : theme.colorScheme.outline.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(
                key: ValueKey(page),
                child: pages[page],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (page > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => page--),
                    child: const Text('قبلی'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (!last) {
                      setState(() => page++);
                      return;
                    }
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ProgramSessionScreen(
                          programId: widget.programId,
                          journeyId: widget.journeyId,
                          fromLearn: true,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: Text(last ? 'آماده‌ام، شروع کنیم' : 'بعدی'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualPage extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final List<Widget> cards;

  const _VisualPage({
    required this.accent,
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.18),
                accent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...cards,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  const _InfoCard({
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final String text;
  final Color color;
  const _StepCard({
    required this.index,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// ورود: Resume / Quick / Learn
class ProgramEntryScreen extends ConsumerWidget {
  final String programId;
  final String? journeyId;
  const ProgramEntryScreen({
    super.key,
    required this.programId,
    this.journeyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = GrowthCatalog.byId(programId);
    final growth = ref.watch(growthProvider);
    final resume = growth.inProgressFor(programId);
    final theme = Theme.of(context);

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('برنامه پیدا نشد')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(p.nameFa)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brand3.withOpacity(0.14),
                  AppColors.brand3.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  p.oneLiner,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '≈ ${p.approxMinutes} دقیقه · ${p.difficulty}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (resume != null) ...[
            _EntryCard(
              icon: Icons.play_circle_outline,
              title: GrowthStrings.resume,
              subtitle: 'اجرای قبلی ذخیره شده؛ از همان‌جا ادامه بده.',
              primary: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProgramSessionScreen(
                      programId: programId,
                      journeyId: journeyId ?? resume.journeyId,
                      existingSessionId: resume.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          _EntryCard(
            icon: Icons.bolt_rounded,
            title: GrowthStrings.quickMode,
            subtitle: 'مستقیم به اجرای امروز — اگر روش را بلدی.',
            primary: resume == null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgramSessionScreen(
                    programId: programId,
                    journeyId: journeyId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _EntryCard(
            icon: Icons.menu_book_outlined,
            title: GrowthStrings.learnMode,
            subtitle: 'آشنایی تصویری + مراحل قابل اجرا حتی بدون اپ.',
            primary: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgramLearnFlow(
                    programId: programId,
                    journeyId: journeyId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProgramIntroScreen(programId: programId),
                ),
              );
            },
            child: const Text('مطالعه معرفی کامل'),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final VoidCallback onTap;
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: primary
          ? AppColors.brand3.withOpacity(0.1)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brand3),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

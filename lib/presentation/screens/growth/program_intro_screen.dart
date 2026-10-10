import 'package:flutter/material.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../../core/theme/app_colors.dart';
import 'program_learn_flow.dart';

/// معرفی برنامه با پالت و آیکون لعاب‌دار
class ProgramIntroScreen extends StatelessWidget {
  final String programId;
  const ProgramIntroScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final p = GrowthCatalog.byId(programId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('برنامه پیدا نشد')),
      );
    }

    final v = GrowthVisuals.of(p.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header لعاب‌دار
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 12,
                20,
                24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [
                          v.gradient[0].withOpacity(0.35),
                          theme.colorScheme.surface,
                        ]
                      : [
                          v.gradient[0].withOpacity(0.2),
                          v.gradient[1].withOpacity(0.08),
                          Colors.white,
                        ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'آموزش و اجرا',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: v.accent,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: v.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.difficulty,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: v.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: v.gradient),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: v.accent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(v.icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nameFa,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.oneLiner,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '≈ ${p.approxMinutes} دقیقه · ${p.difficulty}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: v.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          v.gradient[0],
                          v.gradient.length > 1 ? v.gradient[1] : v.gradient[0],
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: v.accent.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'آموزش و اجرا',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'اول بفهم روش چیست و چطور سنجیده می‌شود؛ بعد در زندگی واقعی اجرا کن — حتی بدون اپ.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionCard(
                  icon: Icons.lightbulb_outline_rounded,
                  accent: v.accent,
                  title: 'این برنامه چیست؟',
                  body: p.whatIs,
                ),
                _SectionCard(
                  icon: Icons.favorite_border_rounded,
                  accent: v.accent,
                  title: 'کاربردش چیست؟ چرا مهم است؟',
                  body: p.whyMatters +
                      (p.suitableFor.isEmpty
                          ? ''
                          : '\n\nمناسب برای: ' + p.suitableFor.join(' · ')),
                ),
                _StepsCard(accent: v.accent, howSteps: p.howSteps),
                if (p.learnCriteria.isNotEmpty)
                  _MetricsCard(
                    accent: v.accent,
                    items: p.learnCriteria,
                  ),
                _SectionCard(
                  icon: Icons.block_rounded,
                  accent: const Color(0xFFF59E0B),
                  title: 'چه انتظاری نباید داشت؟',
                  body: p.notFor,
                ),
                _SectionCard(
                  icon: Icons.menu_book_outlined,
                  accent: v.accent,
                  title: 'منبع / پیشینه',
                  body: p.origin,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: v.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: v.accent.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_outlined, color: v.accent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          GrowthStrings.learnCarryOutside,
                          style:
                              theme.textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramEntryScreen(programId: p.id),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: v.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('ورود به آموزش و اجرا'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  const _SectionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final Color accent;
  final String howSteps;
  const _StepsCard({required this.accent, required this.howSteps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = howSteps
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.08), accent.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'مراحل (حتی بدون اپ)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i].replaceFirst(RegExp(r'^[۰-۹0-9]+[\)\.\-]?\s*'), ''),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color accent;
  const _ChipsCard({
    required this.title,
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map(
                  (e) => Chip(
                    label: Text(e, style: const TextStyle(fontSize: 12)),
                    backgroundColor: accent.withOpacity(0.1),
                    side: BorderSide(color: accent.withOpacity(0.2)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final Color accent;
  final List<String> items;
  const _MetricsCard({required this.accent, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
        color: accent.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'شاخص عملکرد — چطور بفهمی جواب داده؟',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'بعد از چند بار اجرا، با این نشانه‌ها بسنج؛ نه با حس لحظه‌ای تنها.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

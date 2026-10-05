import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../../domain/entities/growth/growth_session.dart';
import '../../providers/growth_provider.dart';

/// تاریخچه نتایج + بینش الگوی ساده (T7)
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(growthProvider);
    final evaluated = growth.sessions
        .where((s) =>
            s.status == SessionStatus.evaluated ||
            s.status == SessionStatus.saved)
        .toList()
      ..sort((a, b) =>
          (b.endedAt ?? b.startedAt).compareTo(a.endedAt ?? a.startedAt));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(GrowthStrings.historyTitle)),
      body: evaluated.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  GrowthStrings.emptyHistory,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _InsightPanel(sessions: evaluated),
                const SizedBox(height: 16),
                Text(
                  'اجراها',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...evaluated.map((s) => _SessionTile(session: s)),
              ],
            ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final List<GrowthSession> sessions;
  const _InsightPanel({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = GrowthInsights.compute(sessions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brand3.withOpacity(0.14),
            AppColors.brand3.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand3.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.brand3),
              const SizedBox(width: 8),
              Text(
                GrowthStrings.insightsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (insight.bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...insight.bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(b, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'این‌ها حدس قطعی نیستند؛ فقط الگوی دادهٔ خودت است.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class GrowthInsightResult {
  final String summary;
  final List<String> bullets;
  const GrowthInsightResult({required this.summary, this.bullets = const []});
}

class GrowthInsights {
  static GrowthInsightResult compute(List<GrowthSession> sessions) {
    if (sessions.isEmpty) {
      return const GrowthInsightResult(summary: GrowthStrings.emptyInsights);
    }

    final evaluated =
        sessions.where((s) => s.status == SessionStatus.evaluated).toList();
    final n = sessions.length;
    final full = evaluated
        .where((s) => s.completion == CompletionLevel.full)
        .length;
    final partial = evaluated
        .where((s) => s.completion == CompletionLevel.partial)
        .length;

    // top program
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.programId] = (counts[s.programId] ?? 0) + 1;
    }
    String? topId;
    var topCount = 0;
    counts.forEach((k, v) {
      if (v > topCount) {
        topCount = v;
        topId = k;
      }
    });
    final topName =
        topId != null ? (GrowthCatalog.byId(topId!)?.nameFa ?? topId!) : null;

    // barriers
    final barrierCount = <String, int>{};
    for (final s in evaluated) {
      for (final b in s.barriers) {
        barrierCount[b] = (barrierCount[b] ?? 0) + 1;
      }
    }
    String? topBarrier;
    var bb = 0;
    barrierCount.forEach((k, v) {
      if (v > bb) {
        bb = v;
        topBarrier = k;
      }
    });

    // next steps
    final nextCount = <NextStepKind, int>{};
    for (final s in evaluated) {
      if (s.nextStep != null) {
        nextCount[s.nextStep!] = (nextCount[s.nextStep!] ?? 0) + 1;
      }
    }
    NextStepKind? topNext;
    var nn = 0;
    nextCount.forEach((k, v) {
      if (v > nn) {
        nn = v;
        topNext = k;
      }
    });

    final avgEnergy = _avgSubjective(evaluated, 'energy');
    final avgClarity = _avgSubjective(evaluated, 'clarity');

    final bullets = <String>[];
    if (topName != null) {
      bullets.add('بیشترین اجرا: $topName ($topCount بار)');
    }
    if (evaluated.isNotEmpty) {
      bullets.add(
          'تکمیل کامل: $full · ناقص: $partial از ${evaluated.length} ارزیابی');
    }
    if (topBarrier != null) {
      bullets.add('مانع پرتکرار: $topBarrier');
    }
    if (avgEnergy != null) {
      bullets.add('میانگین انرژی ثبت‌شده: ${avgEnergy.toStringAsFixed(1)} از ۵');
    }
    if (avgClarity != null) {
      bullets.add(
          'میانگین وضوح ذهنی: ${avgClarity.toStringAsFixed(1)} از ۵');
    }
    if (topNext != null) {
      bullets.add('قدم بعدی پرتکرار: ${_nextLabel(topNext!)}');
    }

    final summary = n < 3
        ? 'با چند اجرای بیشتر، الگوی پایدارتری از خودت اینجا دیده می‌شود. فعلاً $n اجرا ثبت شده.'
        : 'از روی $n اجرا، یک تصویر اولیه از الگوی کار تو شکل گرفته — بدون برچسب موفق/ناموفق.';

    return GrowthInsightResult(summary: summary, bullets: bullets);
  }

  static double? _avgSubjective(List<GrowthSession> list, String key) {
    final vals = <double>[];
    for (final s in list) {
      final v = s.subjective[key];
      if (v is num) vals.add(v.toDouble());
    }
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  static String _nextLabel(NextStepKind k) {
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
    }
  }
}

class _SessionTile extends StatelessWidget {
  final GrowthSession session;
  const _SessionTile({required this.session});

  String _statusFa(SessionStatus s) {
    switch (s) {
      case SessionStatus.evaluated:
        return 'ارزیابی‌شده';
      case SessionStatus.saved:
        return 'ذخیره‌شده';
      case SessionStatus.inProgress:
        return 'در جریان';
      case SessionStatus.abandoned:
        return 'رها شده';
    }
  }

  String _compFa(CompletionLevel? c) {
    switch (c) {
      case CompletionLevel.full:
        return 'کامل';
      case CompletionLevel.partial:
        return 'ناقص';
      case CompletionLevel.none:
        return 'تقریباً هیچ';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        GrowthCatalog.byId(session.programId)?.nameFa ?? session.programId;
    final when = session.endedAt ?? session.startedAt;
    final dateStr = Jalali.fromDateTime(when).format(withMonthName: true);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _statusFa(session.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.brand3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$dateStr · تکمیل: ${_compFa(session.completion)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            if (session.barriers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'مانع: ${session.barriers.join('، ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (session.nextStep != null) ...[
              const SizedBox(height: 4),
              Text(
                'قدم بعدی: ${GrowthInsights._nextLabel(session.nextStep!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (session.nextStepNote.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(session.nextStepNote, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../../domain/entities/growth/growth_journey.dart';
import '../../providers/growth_provider.dart';
import 'create_journey_sheet.dart';

class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(growthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(GrowthStrings.journeysTitle),
        actions: [
          IconButton(
            tooltip: 'مسیر جدید',
            onPressed: () => showCreateJourneySheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.journeys.isEmpty
              ? _Empty(
                  onCreate: () => showCreateJourneySheet(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (state.activeJourneys.length >=
                        GrowthNotifier.maxSoftActive)
                      _SoftLimitBanner(count: state.activeJourneys.length),
                    _Section(
                      title: 'فعال',
                      journeys: state.activeJourneys,
                      empty: 'مسیر فعالی نیست',
                    ),
                    _Section(
                      title: 'مکث',
                      journeys: state.pausedJourneys,
                      empty: 'مسیر متوقفی نیست',
                    ),
                    _Section(
                      title: 'سایر',
                      journeys: state.journeys
                          .where((j) =>
                              j.status != JourneyStatus.active &&
                              j.status != JourneyStatus.paused)
                          .toList(),
                      empty: 'مسیر دیگری نیست',
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateJourneySheet(context),
        backgroundColor: AppColors.brand3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('مسیر جدید',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _SoftLimitBanner extends StatelessWidget {
  final int count;
  const _SoftLimitBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warn.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warn.withOpacity(0.25)),
      ),
      child: Text(
        'الان $count مسیر فعال داری. شاید بهتر باشد روی دو مورد اصلی تمرکز کنیم — بدون عجله.',
        style: const TextStyle(height: 1.45, fontSize: 13),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  final String title;
  final List<GrowthJourney> journeys;
  final String empty;
  const _Section({
    required this.title,
    required this.journeys,
    required this.empty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (journeys.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          )
        else
          ...journeys.map((j) => _JourneyTile(journey: j)),
      ],
    );
  }
}

class _JourneyTile extends ConsumerWidget {
  final GrowthJourney journey;
  const _JourneyTile({required this.journey});

  String _statusLabel(JourneyStatus s) {
    switch (s) {
      case JourneyStatus.draft:
        return 'پیش‌نویس';
      case JourneyStatus.active:
        return 'فعال';
      case JourneyStatus.paused:
        return 'مکث';
      case JourneyStatus.completed:
        return 'تکمیل';
      case JourneyStatus.archived:
        return 'آرشیو';
    }
  }

  Color _statusColor(JourneyStatus s) {
    switch (s) {
      case JourneyStatus.active:
        return const Color(0xFF10B981);
      case JourneyStatus.paused:
        return AppColors.warn;
      case JourneyStatus.completed:
        return AppColors.brand3;
      case JourneyStatus.archived:
        return const Color(0xFF94A3B8);
      case JourneyStatus.draft:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final n = ref.read(growthProvider.notifier);
    final c = _statusColor(journey.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    journey.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(journey.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'activate':
                        await n.activate(journey.id);
                      case 'pause':
                        await n.pause(journey.id);
                      case 'complete':
                        await n.complete(journey.id);
                      case 'archive':
                        await n.archive(journey.id);
                      case 'delete':
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('حذف مسیر؟'),
                            content: const Text(
                              'این مسیر حذف می‌شود. تاریخچه اجراها در فازهای بعد جدا نگه داشته می‌شود.',
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('انصراف')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('حذف')),
                            ],
                          ),
                        );
                        if (ok == true) await n.deleteJourney(journey.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'activate', child: Text('فعال‌سازی')),
                    PopupMenuItem(value: 'pause', child: Text('مکث')),
                    PopupMenuItem(value: 'complete', child: Text('تکمیل')),
                    PopupMenuItem(value: 'archive', child: Text('آرشیو')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            if (journey.reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                journey.reason,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ],
            if (journey.successCriteria.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'معیار موفقیت: ${journey.successCriteria}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined,
                size: 56, color: AppColors.brand3.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              GrowthStrings.emptyJourneys,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'از یک هدف کوچک شروع کنیم.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreate,
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
              child: const Text(GrowthStrings.firstJourney),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/planning_constants.dart';
import '../../../core/constants/program_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/planning_archive_entity.dart';
import '../../providers/planning_provider.dart';

/// لیست و فیلتر آرشیو برنامه‌ریزی (فاز A1)
class PlanningArchivePane extends ConsumerStatefulWidget {
  const PlanningArchivePane({super.key});

  @override
  ConsumerState<PlanningArchivePane> createState() =>
      _PlanningArchivePaneState();
}

class _PlanningArchivePaneState extends ConsumerState<PlanningArchivePane> {
  String? _filterProgram; // null = همه
  int? _filterFeeling; // null = همه

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(planningProvider);
    var list = state.archives;

    if (_filterProgram != null) {
      list = list.where((a) => a.programId == _filterProgram).toList();
    }
    if (_filterFeeling != null) {
      list = list.where((a) => a.feelingScore == _filterFeeling).toList();
    }

    final programIds = state.archives.map((a) => a.programId).toSet().toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'آرشیو دوره‌ها',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'تاریخ شمسی، حس، خلاصه و آمار هر دوره اینجا می‌ماند.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      label: 'همه',
                      selected: _filterProgram == null,
                      onTap: () => setState(() => _filterProgram = null),
                    ),
                    ...programIds.map((id) {
                      final def = programCatalog.where((p) => p.id == id);
                      final name = def.isEmpty ? id : def.first.name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Chip(
                          label: name,
                          selected: _filterProgram == id,
                          onTap: () => setState(() => _filterProgram = id),
                          icon: programIcon(id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      label: 'هر حسی',
                      selected: _filterFeeling == null,
                      onTap: () => setState(() => _filterFeeling = null),
                    ),
                    for (var s = 5; s >= 1; s--)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Chip(
                          label: '${MoneyFormat.toPersianDigits('$s')} ★',
                          selected: _filterFeeling == s,
                          onTap: () => setState(() => _filterFeeling = s),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48,
                            color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          state.archives.isEmpty
                              ? 'هنوز دوره‌ای آرشیو نشده'
                              : 'با این فیلتر چیزی پیدا نشد',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'از داخل هر برنامه فعال، دکمه آرشیو را بزن.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return _ArchiveCard(
                      archive: a,
                      onOpen: () => _openDetail(context, a),
                      onDelete: () => _confirmDelete(context, a),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openDetail(BuildContext context, PlanningArchive a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanningArchiveDetailPage(archiveId: a.id),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PlanningArchive a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف آرشیو؟'),
        content: Text(
          '«${a.programName}» مربوط به ${a.jalaliDate} برای همیشه حذف شود؟',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(planningProvider.notifier).deleteArchive(a.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آرشیو حذف شد')),
        );
      }
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final PlanningArchive archive;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ArchiveCard({
    required this.archive,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = programColor(archive.programId);
    final preview = archive.summaryText.split('\n').take(3).join(' · ');

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(programIcon(archive.programId),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          archive.programName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${archive.jalaliDate}  ·  ${MoneyFormat.toPersianDigits(archive.jalaliTime)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (archive.feelingScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${MoneyFormat.toPersianDigits('${archive.feelingScore}')}★',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: theme.colorScheme.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (archive.periodTitle != null &&
                  archive.periodTitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  archive.periodTitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'مشاهده جزئیات ←',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحه جزئیات آرشیو
class PlanningArchiveDetailPage extends ConsumerWidget {
  final String archiveId;

  const PlanningArchiveDetailPage({super.key, required this.archiveId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archives = ref.watch(planningProvider).archives;
    final a = archives.where((e) => e.id == archiveId).toList();
    if (a.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('آرشیو')),
        body: const Center(child: Text('این آرشیو پیدا نشد')),
      );
    }
    final archive = a.first;
    final color = programColor(archive.programId);
    final days = archive.periodDuration.inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(archive.programName),
        actions: [
          IconButton(
            tooltip: 'کپی خلاصه',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: archive.summaryText));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('خلاصه کپی شد')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(programIcon(archive.programId),
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        archive.periodTitle?.trim().isNotEmpty == true
                            ? archive.periodTitle!
                            : archive.programName,
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
                  'آرشیو: ${archive.jalaliDate}  ${MoneyFormat.toPersianDigits(archive.jalaliTime)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withOpacity(0.9)),
                ),
                Text(
                  'مدت تقریبی: ${MoneyFormat.toPersianDigits('$days')} روز',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withOpacity(0.9)),
                ),
                if (archive.feelingScore != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'حس پایان: ${MoneyFormat.toPersianDigits('${archive.feelingScore}')} از ۵',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (archive.feelingNote != null &&
                      archive.feelingNote!.trim().isNotEmpty)
                    Text(
                      archive.feelingNote!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.92)),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('خلاصه متنی',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
            ),
            child: SelectableText(
              archive.summaryText.isEmpty
                  ? 'خلاصه‌ای ثبت نشده'
                  : archive.summaryText,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
          ),
          const SizedBox(height: 20),
          Text('آمار و نمودار',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _StatsChart(stats: archive.stats, programId: archive.programId),
          if (archive.stats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: archive.stats.entries
                  .where((e) => e.key != 'programId')
                  .map((e) {
                return Chip(
                  label: Text(
                    '${e.key}: ${MoneyFormat.toPersianDigits('${e.value}')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// نمودار ساده از روی stats (بدون پکیج)
class _StatsChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String programId;

  const _StatsChart({required this.stats, required this.programId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bars = <_Bar>[];

    switch (programId) {
      case 'habits':
        bars.add(_Bar('تیک‌ها', (stats['totalTicks'] as num?)?.toDouble() ?? 0,
            const Color(0xFFEF4444)));
        bars.add(_Bar('عادت‌ها', (stats['habitCount'] as num?)?.toDouble() ?? 0,
            const Color(0xFFF59E0B)));
        break;
      case 'eisen':
        bars.add(_Bar('انجام', (stats['doneCount'] as num?)?.toDouble() ?? 0,
            const Color(0xFF22C55E)));
        bars.add(_Bar('باز', (stats['openCount'] as num?)?.toDouble() ?? 0,
            const Color(0xFF3B82F6)));
        break;
      case 'kanban':
        bars.add(_Bar('انجام‌دادنی', (stats['todo'] as num?)?.toDouble() ?? 0,
            const Color(0xFF64748B)));
        bars.add(_Bar('در حال', (stats['doing'] as num?)?.toDouble() ?? 0,
            const Color(0xFFF59E0B)));
        bars.add(_Bar('شده', (stats['done'] as num?)?.toDouble() ?? 0,
            const Color(0xFF22C55E)));
        break;
      case 'mood':
        bars.add(_Bar('روزها', (stats['dayCount'] as num?)?.toDouble() ?? 0,
            const Color(0xFFEC4899)));
        bars.add(_Bar(
            'میانگین×۱۰',
            ((stats['avgMood'] as num?)?.toDouble() ?? 0) * 10,
            const Color(0xFF8B5CF6)));
        break;
      default:
        bars.add(_Bar(
            'طول یادداشت',
            ((stats['noteLength'] as num?)?.toDouble() ?? 0) / 10,
            theme.colorScheme.primary));
    }

    if (bars.isEmpty || bars.every((b) => b.value <= 0)) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'آمار عددی برای نمودار موجود نیست',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final maxV = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    final max = maxV <= 0 ? 1.0 : maxV;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: bars.map((b) {
          final ratio = (b.value / max).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(b.label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surface,
                      color: b.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    MoneyFormat.toPersianDigits('${b.value.round()}'),
                    textAlign: TextAlign.left,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Bar {
  final String label;
  final double value;
  final Color color;
  const _Bar(this.label, this.value, this.color);
}

/// دیالوگ آرشیو دوره (حس + تأیید)
Future<void> showArchivePeriodDialog(
  BuildContext context,
  WidgetRef ref, {
  required String programId,
  required String programName,
}) async {
  int? feeling = 3;
  final noteCtrl = TextEditingController();
  final titleCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text('آرشیو «$programName»'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'دوره جاری با تاریخ شمسی ذخیره می‌شود. داده فعلی پاک و برنامه از فعال‌ها خارج می‌شود.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان دوره (اختیاری)',
                      hintText: 'مثلاً هفته امتحان',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('حس پایان دوره (اختیاری)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final s = i + 1;
                      final sel = feeling == s;
                      return InkWell(
                        onTap: () => setLocal(() => feeling = s),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel
                                ? Theme.of(ctx).colorScheme.primary
                                : Theme.of(ctx)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            MoneyFormat.toPersianDigits('$s'),
                            style: TextStyle(
                              color: sel ? Colors.white : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'توضیح حس',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('لغو')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('آرشیو کن'),
              ),
            ],
          );
        },
      );
    },
  );

  if (ok != true || !context.mounted) {
    noteCtrl.dispose();
    titleCtrl.dispose();
    return;
  }

  final title = titleCtrl.text.trim();
  if (title.isNotEmpty) {
    await ref
        .read(planningProvider.notifier)
        .updatePeriodMeta(programId, title: title);
  }

  final saved = await ref.read(planningProvider.notifier).archiveCurrentPeriod(
        programId,
        feelingScore: feeling,
        feelingNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );

  noteCtrl.dispose();
  titleCtrl.dispose();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved == null
            ? 'آرشیو انجام نشد'
            : 'دوره آرشیو شد — در تب آرشیو ببین'),
      ),
    );
  }
}

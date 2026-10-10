import 'package:flutter/material.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_sensor.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../../domain/entities/growth/growth_program_def.dart';
import 'program_learn_flow.dart';

/// سنسور انتخاب — کمک به پیدا کردن قدم مناسب (T3)
class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  int _step = 0; // 0 area, 1 question, 2 result
  String? _areaId;
  String? _answerId;
  SensorResult? _result;

  void _pickArea(String id) {
    setState(() {
      _areaId = id;
      _answerId = null;
      _result = null;
      _step = 1;
    });
  }

  void _pickAnswer(String id) {
    final area = _areaId!;
    final result = GrowthSensor.resolve(area, id);
    setState(() {
      _answerId = id;
      _result = result;
      _step = 2;
    });
  }

  void _reset() {
    setState(() {
      _step = 0;
      _areaId = null;
      _answerId = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سنسور انتخاب'),
        actions: [
          if (_step > 0)
            TextButton(onPressed: _reset, child: const Text('از نو')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            _step == 0
                ? 'الان بیشتر می‌خواهی روی چه چیزی کار کنی؟'
                : _step == 1
                    ? 'کدام بیشتر به وضعیتت نزدیک است؟'
                    : 'برای شروع، این گزینه‌ها مناسب‌ترند',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _step < 2
                ? 'لازم نیست کامل بدانی؛ یک انتخاب تقریبی کافی است.'
                : GrowthStrings.whyThis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 16),
          if (_step == 0) ..._areaChips(),
          if (_step == 1) ..._questionChips(),
          if (_step == 2 && _result != null) ..._resultBlock(theme),
        ],
      ),
    );
  }

  List<Widget> _areaChips() {
    return GrowthSensor.areas
        .map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChoiceTile(
              label: o.label,
              highlighted: o.id == 'unknown',
              onTap: () => _pickArea(o.id),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _questionChips() {
    final qs = GrowthSensor.questionsFor(_areaId!);
    return qs
        .map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChoiceTile(
              label: o.label,
              onTap: () => _pickAnswer(o.id),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _resultBlock(ThemeData theme) {
    final r = _result!;
    final primary = GrowthCatalog.byId(r.primaryProgramId);
    final alts = r.alternatives
        .map((id) => GrowthCatalog.byId(id))
        .whereType<GrowthProgramDef>()
        .toList();

    return [
      if (primary != null) ...[
        Text(
          'پیشنهاد اصلی',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brand3,
          ),
        ),
        const SizedBox(height: 8),
        _ProgramResultCard(
          program: primary,
          isPrimary: true,
          onOpen: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProgramEntryScreen(programId: primary.id),
              ),
            );
          },
        ),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brand3.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          r.why,
          style: const TextStyle(height: 1.5, fontSize: 13),
        ),
      ),
      if (alts.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'گزینه‌های دیگر',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...alts.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ProgramResultCard(
              program: p,
              isPrimary: false,
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProgramEntryScreen(programId: p.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ];
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  const _ChoiceTile({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: highlighted
          ? AppColors.warn.withOpacity(0.1)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramResultCard extends StatelessWidget {
  final GrowthProgramDef program;
  final bool isPrimary;
  final VoidCallback onOpen;
  const _ProgramResultCard({
    required this.program,
    required this.isPrimary,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = GrowthVisuals.of(program.id);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPrimary
              ? v.accent.withOpacity(0.4)
              : theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: v.gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(v.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    program.nameFa,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(program.oneLiner,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
            const SizedBox(height: 6),
            Text(
              '≈ ${program.approxMinutes} دقیقه · ${program.difficulty}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isPrimary ? v.accent : theme.colorScheme.secondary,
                ),
                child: Text(isPrimary ? 'مشاهده و آموزش' : 'مشاهده'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

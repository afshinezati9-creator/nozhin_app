import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../../domain/entities/growth/growth_session.dart';
import '../../providers/growth_provider.dart';
import 'journeys_screen.dart';

/// ارزیابی پس از اجرا — عینی / ذهنی جدا + قدم بعدی (T6)
class SessionEvalScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionEvalScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionEvalScreen> createState() => _SessionEvalScreenState();
}

class _SessionEvalScreenState extends ConsumerState<SessionEvalScreen> {
  CompletionLevel _completion = CompletionLevel.partial;
  int _energy = 3; // 1-5
  int _clarity = 3;
  final Set<String> _barriers = {};
  NextStepKind _next = NextStepKind.continueSame;
  final _note = TextEditingController();
  bool _saving = false;

  static const _barrierOptions = [
    'حواس‌پرتی',
    'خستگی',
    'ابهام هدف',
    'وقفه بیرونی',
    'مقاومت شروع',
    'زمان کم',
  ];

  GrowthSession? get _session {
    final list = ref.read(growthProvider).sessions;
    for (final s in list) {
      if (s.id == widget.sessionId) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _suggestWhy(NextStepKind k) {
    switch (k) {
      case NextStepKind.continueSame:
        return 'اگر حس می‌کنی روش مناسب است، همان را تکرار کن تا الگو شکل بگیرد.';
      case NextStepKind.makeEasier:
        return 'اگر سنگین بود، نسخه کوتاه‌تر یا معیار ساده‌تر معمولاً بهتر جواب می‌دهد.';
      case NextStepKind.tryOtherMethod:
        return 'اگر با این روش جور نبودی، روش دیگری را امتحان کن — نه شکست، فقط داده.';
      case NextStepKind.pause:
        return 'مکث آگاهانه هم بخشی از مسیر است؛ فشار اضافه لازم نیست.';
      case NextStepKind.review:
        return 'یک مرور کوتاه کمک می‌کند ببینی چه چیزی واقعاً کمک کرد.';
    }
  }

  Future<void> _save() async {
    final s = _session;
    if (s == null) return;
    setState(() => _saving = true);
    final updated = s.copyWith(
      status: SessionStatus.evaluated,
      endedAt: s.endedAt ?? DateTime.now(),
      completion: _completion,
      barriers: _barriers.toList(),
      subjective: {
        'energy': _energy,
        'clarity': _clarity,
      },
      nextStep: _next,
      nextStepNote: _note.text.trim(),
    );
    await ref.read(growthProvider.notifier).markSessionEvaluated(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ثبت شد'),
        content: Text(
          _suggestWhy(_next),
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          if (s.journeyId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JourneysScreen()),
                );
              },
              child: const Text('مدیریت مسیر'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _session;
    final program = s != null ? GrowthCatalog.byId(s.programId) : null;

    // پیشنهاد اولیه بر اساس چک‌لیست عینی
    if (s != null && s.objective['checklist'] is Map) {
      // only seed once via didChangeDependencies pattern - skip auto for simplicity
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${GrowthStrings.evalTitle}${program != null ? ' · ${program.nameFa}' : ''}'),
      ),
      body: s == null
          ? const Center(child: Text('اجرا پیدا نشد'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _HeaderCard(session: s, programName: program?.nameFa ?? ''),
                const SizedBox(height: 16),
                Text(
                  'چقدر انجام شد؟ (عینی)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _compChip('کامل', CompletionLevel.full),
                    _compChip('ناقص', CompletionLevel.partial),
                    _compChip('تقریباً هیچ', CompletionLevel.none),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'مانع‌ها (اختیاری)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _barrierOptions.map((b) {
                    final on = _barriers.contains(b);
                    return FilterChip(
                      label: Text(b),
                      selected: on,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _barriers.add(b);
                          } else {
                            _barriers.remove(b);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'حس بعد از اجرا (ذهنی — جدا از نتیجه)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'این‌ها قضاوت «موفق/ناموفق» نیستند؛ فقط ثبت حس است.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text('انرژی: $_energy / 5'),
                Slider(
                  value: _energy.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.brand3,
                  onChanged: (v) => setState(() => _energy = v.round()),
                ),
                Text('وضوح ذهنی: $_clarity / 5'),
                Slider(
                  value: _clarity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: const Color(0xFF38BDF8),
                  onChanged: (v) => setState(() => _clarity = v.round()),
                ),
                const SizedBox(height: 12),
                Text(
                  GrowthStrings.nextStep,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...NextStepKind.values.map((k) {
                  return RadioListTile<NextStepKind>(
                    value: k,
                    groupValue: _next,
                    onChanged: (v) {
                      if (v != null) setState(() => _next = v);
                    },
                    title: Text(_nextLabel(k)),
                    subtitle: Text(
                      _suggestWhy(k),
                      style: theme.textTheme.bodySmall,
                    ),
                    activeColor: AppColors.brand3,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'یادداشت کوتاه (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand3,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ثبت ارزیابی و قدم بعدی'),
                ),
              ],
            ),
    );
  }

  Widget _compChip(String label, CompletionLevel level) {
    final on = _completion == level;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _completion = level),
      selectedColor: AppColors.brand3.withOpacity(0.2),
    );
  }

  String _nextLabel(NextStepKind k) {
    switch (k) {
      case NextStepKind.continueSame:
        return 'ادامه همین روش';
      case NextStepKind.makeEasier:
        return 'ساده‌ترش کنم';
      case NextStepKind.tryOtherMethod:
        return 'روش دیگری را امتحان کنم';
      case NextStepKind.pause:
        return 'فعلاً مکث';
      case NextStepKind.review:
        return 'اول مرور کنم';
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final GrowthSession session;
  final String programName;
  const _HeaderCard({required this.session, required this.programName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checks = session.objective['checklist'];
    int done = 0;
    int total = 0;
    if (checks is Map) {
      total = checks.length;
      done = checks.values.where((v) => v == true).length;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brand3.withOpacity(0.14),
            AppColors.brand3.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            programName.isEmpty ? 'خلاصه اجرا' : programName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total > 0
                ? 'چک‌لیست عینی: $done از $total'
                : 'اجرا ثبت شد — حالا بدون قضاوت سخت، حس و قدم بعدی را بنویس.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (session.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'یادداشت اجرا: ${session.note}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

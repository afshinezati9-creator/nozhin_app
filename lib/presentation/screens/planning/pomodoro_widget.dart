import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../providers/planning_provider.dart';

enum PomoPhase { work, shortBreak, longBreak }

class PomodoroWidget extends ConsumerStatefulWidget {
  const PomodoroWidget({super.key});

  @override
  ConsumerState<PomodoroWidget> createState() => _PomodoroWidgetState();
}

class _PomodoroWidgetState extends ConsumerState<PomodoroWidget> {
  static const workSec = 25 * 60;
  static const shortBreakSec = 5 * 60;
  static const longBreakSec = 15 * 60;
  static const sessionsUntilLong = 4;

  PomoPhase _phase = PomoPhase.work;
  int _left = workSec;
  bool _running = false;
  int _completedSessions = 0;
  Timer? _timer;
  final _taskCtrl = TextEditingController();
  int _rating = 3;
  int? _moodBefore;
  int? _moodAfter;

  @override
  void dispose() {
    _timer?.cancel();
    _taskCtrl.dispose();
    super.dispose();
  }

  int get _phaseDuration {
    switch (_phase) {
      case PomoPhase.work:
        return workSec;
      case PomoPhase.shortBreak:
        return shortBreakSec;
      case PomoPhase.longBreak:
        return longBreakSec;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case PomoPhase.work:
        return 'تمرکز';
      case PomoPhase.shortBreak:
        return 'استراحت کوتاه';
      case PomoPhase.longBreak:
        return 'استراحت بلند';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case PomoPhase.work:
        return AppColors.brand3;
      case PomoPhase.shortBreak:
        return const Color(0xFF10B981);
      case PomoPhase.longBreak:
        return const Color(0xFF3B82F6);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || !mounted) return;
      if (_left <= 1) {
        _onPhaseComplete();
      } else {
        setState(() => _left--);
      }
    });
  }

  Future<void> _onPhaseComplete() async {
    _timer?.cancel();
    setState(() => _running = false);

    if (_phase == PomoPhase.work) {
      final sessions = _completedSessions + 1;
      setState(() => _completedSessions = sessions);
      await _logSession();
      if (sessions % sessionsUntilLong == 0) {
        _setPhase(PomoPhase.longBreak);
      } else {
        _setPhase(PomoPhase.shortBreak);
      }
    } else {
      _setPhase(PomoPhase.work);
    }
  }

  Future<void> _logSession() async {
    final notes = ref.read(planningProvider).programNotes;
    final prev = notes['pomo_log'] ?? '';
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final task = _taskCtrl.text.trim().isEmpty ? 'بدون عنوان' : _taskCtrl.text.trim();
    final line =
        '$stamp|$task|$_rating|${_moodBefore ?? "-"}|${_moodAfter ?? "-"}';
    final next = [line, ...prev.split('\n').where((e) => e.trim().isNotEmpty)]
        .take(30)
        .join('\n');
    await ref.read(planningProvider.notifier).saveProgramNote('pomo_log', next);
    final count = (int.tryParse(notes['pomo_count'] ?? '0') ?? 0) + 1;
    await ref
        .read(planningProvider.notifier)
        .saveProgramNote('pomo_count', '$count');
  }

  void _setPhase(PomoPhase p) {
    setState(() {
      _phase = p;
      _left = _phaseDuration;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      setState(() => _running = false);
      _timer?.cancel();
    } else {
      setState(() => _running = true);
      _startTimer();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _left = _phaseDuration;
    });
  }

  void _skip() {
    _timer?.cancel();
    _onPhaseComplete();
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${MoneyFormat.toPersianDigits(m.toString().padLeft(2, '0'))}:${MoneyFormat.toPersianDigits(s.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1 - (_left / _phaseDuration);
    final log = ref.watch(planningProvider).programNotes['pomo_log'] ?? '';
    final lines = log.split('\n').where((e) => e.trim().isNotEmpty).toList();
    final avgRating = () {
      final rs = lines
          .map((l) {
            final p = l.split('|');
            return p.length > 2 ? int.tryParse(p[2]) ?? 0 : 0;
          })
          .where((x) => x > 0)
          .toList();
      if (rs.isEmpty) return 0.0;
      return rs.reduce((a, b) => a + b) / rs.length;
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _taskCtrl,
          decoration: const InputDecoration(
            labelText: 'تمرکز روی چه کاری؟',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('حس قبل: ', style: TextStyle(fontSize: 12)),
            for (var i = 1; i <= 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(MoneyFormat.toPersianDigits('$i'),
                      style: const TextStyle(fontSize: 11)),
                  selected: _moodBefore == i,
                  onSelected: (_) => setState(() => _moodBefore = i),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: _phaseColor.withOpacity(0.15),
                    color: _phaseColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_phaseLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _phaseColor,
                          fontWeight: FontWeight.w800,
                        )),
                    Text(_fmt(_left),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        )),
                    Text(
                      'جلسه ${MoneyFormat.toPersianDigits('$_completedSessions')}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _toggle,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? 'توقف' : 'شروع'),
                style: FilledButton.styleFrom(backgroundColor: _phaseColor),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _reset, child: const Text('ریست')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _skip, child: const Text('رد')),
          ],
        ),
        const SizedBox(height: 10),
        Text('نمره تمرکز این جلسه',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Row(
          children: List.generate(5, (i) {
            final s = i + 1;
            return IconButton(
              onPressed: () => setState(() => _rating = s),
              icon: Icon(
                s <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
              ),
            );
          }),
        ),
        Row(
          children: [
            const Text('حس بعد: ', style: TextStyle(fontSize: 12)),
            for (var i = 1; i <= 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  label: Text(MoneyFormat.toPersianDigits('$i'),
                      style: const TextStyle(fontSize: 11)),
                  selected: _moodAfter == i,
                  onSelected: (_) => setState(() => _moodAfter = i),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (lines.isNotEmpty) ...[
          Text(
            'میانگین نمره: ${MoneyFormat.toPersianDigits(avgRating.toStringAsFixed(1))} · ${MoneyFormat.toPersianDigits('${lines.length}')} جلسه',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...lines.take(5).map((l) {
            final p = l.split('|');
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined, size: 18),
              title: Text(p.length > 1 ? p[1] : l,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                p.isNotEmpty
                    ? '${p[0]} · نمره ${p.length > 2 ? MoneyFormat.toPersianDigits(p[2]) : "—"}'
                    : '',
                style: const TextStyle(fontSize: 11),
              ),
            );
          }),
        ],
      ],
    );
  }
}

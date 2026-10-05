import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/growth/growth_session.dart';
import '../../providers/growth_provider.dart';
import 'program_tools.dart';
import 'session_eval_screen.dart';

/// پوسته اجرای مشترک — ذخیره خودکار + خروج امن (T4)
/// ابزار اختصاصی عمیق در T5 روی همین اسکلت سوار می‌شود.
class ProgramSessionScreen extends ConsumerStatefulWidget {
  final String programId;
  final String? journeyId;
  final String? existingSessionId;
  final bool fromLearn;

  const ProgramSessionScreen({
    super.key,
    required this.programId,
    this.journeyId,
    this.existingSessionId,
    this.fromLearn = false,
  });

  @override
  ConsumerState<ProgramSessionScreen> createState() =>
      _ProgramSessionScreenState();
}

class _ProgramSessionScreenState extends ConsumerState<ProgramSessionScreen> {
  GrowthSession? _session;
  final _noteCtrl = TextEditingController();
  final Map<String, bool> _checks = {};
  bool _ready = false;
  bool _saving = false;
  Timer? _debounce;
  String? _savedHint;
  Map<String, dynamic> _toolState = {};

  List<String> get _stepLabels {
    final p = GrowthCatalog.byId(widget.programId);
    if (p == null) return ['شروع', 'انجام', 'یادداشت'];
    // از howSteps خطوط را به‌عنوان چک‌لیست اجرا
    final lines = p.howSteps
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(6)
        .toList();
    if (lines.isEmpty) return ['شروع', 'انجام', 'یادداشت کوتاه'];
    return lines;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // جلوگیری از modify provider هنگام build
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final n = ref.read(growthProvider.notifier);
    GrowthSession session;
    if (widget.existingSessionId != null) {
      final found = ref
          .read(growthProvider)
          .sessions
          .where((s) => s.id == widget.existingSessionId)
          .toList();
      if (found.isNotEmpty) {
        session = found.first;
      } else {
        session = await n.startSession(
          programId: widget.programId,
          journeyId: widget.journeyId,
        );
      }
    } else {
      session = await n.startSession(
        programId: widget.programId,
        journeyId: widget.journeyId,
      );
    }

    final obj = Map<String, dynamic>.from(session.objective);
    if (obj['tool'] is Map) {
      _toolState = Map<String, dynamic>.from(obj['tool'] as Map);
    }
    final rawChecks = obj['checklist'];
    if (rawChecks is Map) {
      rawChecks.forEach((k, v) {
        _checks['$k'] = v == true;
      });
    }
    _noteCtrl.text = session.note;

    if (mounted) {
      setState(() {
        _session = session;
        _ready = true;
      });
    }
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persist);
  }

  Future<void> _persist() async {
    if (_session == null) return;
    setState(() => _saving = true);
    final obj = Map<String, dynamic>.from(_session!.objective);
    obj['checklist'] = Map<String, bool>.from(_checks);
    obj['tool'] = Map<String, dynamic>.from(_toolState);
    final updated = _session!.copyWith(
      objective: obj,
      note: _noteCtrl.text.trim(),
    );
    await ref.read(growthProvider.notifier).autoSaveSession(updated);
    if (!mounted) return;
    setState(() {
      _session = updated;
      _saving = false;
      _savedHint = GrowthStrings.savedHint;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedHint = null);
    });
  }

  Future<void> _onWillLeave() async {
    await _persist();
  }

  Future<void> _finish() async {
    await _persist();
    if (_session == null) return;
    await ref.read(growthProvider.notifier).finishSessionForEval(_session!);
    if (!mounted) return;
    final id = _session!.id;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionEvalScreen(sessionId: id),
      ),
    );
  }

  Future<void> _pauseAndExit() async {
    await _persist();
    if (_session != null) {
      // وضعیت inProgress می‌ماند تا Resume کار کند
    }
    if (mounted) Navigator.of(context).pop();
  }


  Widget _buildSpecialTool() {
    void on(Map<String, dynamic> m) {
      _toolState = m;
      _scheduleSave();
    }
    switch (widget.programId) {
      case 'pomodoro':
        return PomodoroTool(onTickState: on, initial: _toolState);
      case 'two_minute':
        return TwoMinuteTool(onChanged: on, initial: _toolState);
      case 'daily_review':
        return DailyReviewTool(onChanged: on, initial: _toolState);
      case 'frog':
        return FrogTool(onChanged: on, initial: _toolState);
      case 'eisenhower':
        return EisenhowerTool(onChanged: on, initial: _toolState);
      case 'habit_tracker':
        return HabitTrackerTool(onChanged: on, initial: _toolState);
      case 'smart_goal':
        return SmartGoalTool(onChanged: on, initial: _toolState);
      case 'timeblock':
        return TimeblockTool(onChanged: on, initial: _toolState);
      case 'kaizen':
        return KaizenTool(onChanged: on, initial: _toolState);
      case 'deep_work':
        return DeepWorkTool(onChanged: on, initial: _toolState);
      case 'five_s':
        return FiveSTool(onChanged: on, initial: _toolState);
      case 'kanban':
        return KanbanTool(onChanged: on, initial: _toolState);
      case 'ikigai':
        return IkigaiTool(onChanged: on, initial: _toolState);
      case 'gratitude':
        return GratitudeTool(onChanged: on, initial: _toolState);
      case 'mood_tracker':
        return MoodTrackerTool(onChanged: on, initial: _toolState);
      case 'growth_mindset':
        return GrowthMindsetTool(onChanged: on, initial: _toolState);
      case 'pdca':
        return PdcaTool(onChanged: on, initial: _toolState);
      case 'hoshin':
        return HoshinTool(onChanged: on, initial: _toolState);
      case 'wheel':
        return WheelTool(onChanged: on, initial: _toolState);
      case 'cbt_journal':
        return CbtJournalTool(onChanged: on, initial: _toolState);
      case 'swot':
        return SwotTool(onChanged: on, initial: _toolState);
      case 'pareto':
        return ParetoTool(onChanged: on, initial: _toolState);
      case 'gtd_next':
        return GtdNextTool(onChanged: on, initial: _toolState);
      case 'okr_lite':
        return OkrLiteTool(onChanged: on, initial: _toolState);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = GrowthCatalog.byId(widget.programId);
    final theme = Theme.of(context);
    final done = _checks.values.where((v) => v).length;
    final total = _stepLabels.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Scaffold(
        appBar: AppBar(
          title: Text(p?.nameFa ?? 'اجرا'),
          actions: [
            if (_savedHint != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    _savedHint!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (_saving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        bottomNavigationBar: !_ready
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pauseAndExit,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text(GrowthStrings.pause),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _finish,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(GrowthStrings.finishSession),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand3,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (widget.fromLearn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'اولین اجرا بعد از آموزش — آرام و واقعی کافی است.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brand3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    'پیشرفت اجرا',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.brand3,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$done از $total',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'راهنمای کوتاه (قابل انجام بدون اپ)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_stepLabels.length, (i) {
                    final label = _stepLabels[i];
                    final key = 's$i';
                    final checked = _checks[key] == true;
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() => _checks[key] = v == true);
                        _scheduleSave();
                      },
                      title: Text(label, style: const TextStyle(height: 1.35)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),

                  // ابزار برنامه
                  if ([
                    'pomodoro', 'two_minute', 'daily_review', 'frog',
                    'eisenhower', 'habit_tracker', 'smart_goal',
                    'timeblock', 'kaizen', 'deep_work',
                    'five_s', 'kanban', 'ikigai', 'gratitude', 'mood_tracker',
                    'growth_mindset', 'pdca', 'hoshin', 'wheel', 'cbt_journal',
                    'swot', 'pareto', 'gtd_next', 'okr_lite',
                  ].contains(widget.programId)) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ابزار این برنامه',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildSpecialTool(),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت کوتاه اجرا (اختیاری)',
                      hintText: 'چه اتفاقی افتاد؟',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _scheduleSave(),
                  ),
                                    const SizedBox(height: 8),
                  Text(
                    'با خروج امن، داده ذخیره می‌ماند.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
      );
  }
}

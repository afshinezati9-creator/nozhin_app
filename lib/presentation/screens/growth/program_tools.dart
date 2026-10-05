import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// ابزارهای اختصاصی موج ۱ (T5)

class PomodoroTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onTickState;
  final Map<String, dynamic>? initial;
  const PomodoroTool({super.key, required this.onTickState, this.initial});

  @override
  State<PomodoroTool> createState() => _PomodoroToolState();
}

class _PomodoroToolState extends State<PomodoroTool> {
  static const workSec = 25 * 60;
  static const breakSec = 5 * 60;
  late int _remaining;
  bool _isWork = true;
  bool _running = false;
  int _completed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _remaining = (i['remaining'] as int?) ?? workSec;
    _isWork = i['isWork'] != false;
    _completed = (i['completed'] as int?) ?? 0;
  }

  void _emit() {
    widget.onTickState({
      'remaining': _remaining,
      'isWork': _isWork,
      'completed': _completed,
      'running': _running,
    });
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _emit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _running = false;
          if (_isWork) {
            _completed++;
            _isWork = false;
            _remaining = breakSec;
          } else {
            _isWork = true;
            _remaining = workSec;
          }
        });
        _emit();
        return;
      }
      setState(() => _remaining--);
      _emit();
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
    _emit();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isWork = true;
      _remaining = workSec;
    });
    _emit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _isWork ? AppColors.brand3 : const Color(0xFF38BDF8);
    final progress = _isWork
        ? 1 - (_remaining / workSec)
        : 1 - (_remaining / breakSec);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            _isWork ? 'جلسه تمرکز' : 'استراحت',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.12),
                    color: color,
                  ),
                ),
                Text(
                  _label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جلسات تمام‌شده: $_completed',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? _pause : _start,
                  style: FilledButton.styleFrom(backgroundColor: color),
                  child: Text(_running ? 'توقف' : 'شروع'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _reset, child: const Text('از نو')),
            ],
          ),
        ],
      ),
    );
  }
}

class TwoMinuteTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const TwoMinuteTool({super.key, required this.onChanged, this.initial});

  @override
  State<TwoMinuteTool> createState() => _TwoMinuteToolState();
}

class _TwoMinuteToolState extends State<TwoMinuteTool> {
  final _task = TextEditingController();
  bool _done = false;
  int _seconds = 120;
  Timer? _t;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _task.text = '${i['task'] ?? ''}';
    _done = i['done'] == true;
    _seconds = (i['seconds'] as int?) ?? 120;
  }

  void _emit() {
    widget.onChanged({
      'task': _task.text.trim(),
      'done': _done,
      'seconds': _seconds,
    });
  }

  void _startTimer() {
    if (_running) return;
    setState(() => _running = true);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 0) {
        _t?.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _seconds--);
      _emit();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _task.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'قانون ۲ دقیقه',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _task,
            decoration: const InputDecoration(
              labelText: 'کار کوچک (کمتر از ۲ دقیقه)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          Text(
            'زمان: ${_seconds}s',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? null : _startTimer,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                  child: Text(_running ? 'در حال شمارش…' : 'شروع ۲ دقیقه'),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_done ? 'انجام شد' : 'علامت انجام'),
                selected: _done,
                onSelected: (v) {
                  setState(() => _done = v);
                  _emit();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyReviewTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const DailyReviewTool({super.key, required this.onChanged, this.initial});

  @override
  State<DailyReviewTool> createState() => _DailyReviewToolState();
}

class _DailyReviewToolState extends State<DailyReviewTool> {
  final _went = TextEditingController();
  final _learned = TextEditingController();
  final _tomorrow = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _went.text = '${i['went'] ?? ''}';
    _learned.text = '${i['learned'] ?? ''}';
    _tomorrow.text = '${i['tomorrow'] ?? ''}';
  }

  void _emit() {
    widget.onChanged({
      'went': _went.text.trim(),
      'learned': _learned.text.trim(),
      'tomorrow': _tomorrow.text.trim(),
    });
  }

  @override
  void dispose() {
    _went.dispose();
    _learned.dispose();
    _tomorrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget field(String label, TextEditingController c, Color color) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: TextField(
          controller: c,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          onChanged: (_) => _emit(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'مرور روزانه',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        field('امروز چه چیزی خوب پیش رفت؟', _went, const Color(0xFF10B981)),
        field('چه چیزی یاد گرفتم؟', _learned, AppColors.brand3),
        field('فردا یک قدم کوچک؟', _tomorrow, const Color(0xFFF59E0B)),
      ],
    );
  }
}

class FrogTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const FrogTool({super.key, required this.onChanged, this.initial});

  @override
  State<FrogTool> createState() => _FrogToolState();
}

class _FrogToolState extends State<FrogTool> {
  final _frog = TextEditingController();
  final _why = TextEditingController();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _frog.text = '${i['frog'] ?? ''}';
    _why.text = '${i['why'] ?? ''}';
    _done = i['done'] == true;
  }

  void _emit() {
    widget.onChanged({
      'frog': _frog.text.trim(),
      'why': _why.text.trim(),
      'done': _done,
    });
  }

  @override
  void dispose() {
    _frog.dispose();
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withOpacity(0.12),
            const Color(0xFF16A34A).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🐸', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'قورباغه امروز',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _frog,
            decoration: const InputDecoration(
              labelText: 'سخت‌ترین کار مهم امروز',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _why,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'چرا مهم است؟',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          FilterChip(
            label: Text(_done ? 'قورباغه خورده شد ✓' : 'هنوز نخورده‌ام'),
            selected: _done,
            onSelected: (v) {
              setState(() => _done = v);
              _emit();
            },
            selectedColor: const Color(0xFF22C55E).withOpacity(0.25),
          ),
        ],
      ),
    );
  }
}

/// —— موج ۲ ——

class EisenhowerTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const EisenhowerTool({super.key, required this.onChanged, this.initial});

  @override
  State<EisenhowerTool> createState() => _EisenhowerToolState();
}

class _EisenhowerToolState extends State<EisenhowerTool> {
  final _input = TextEditingController();
  final Map<String, List<String>> _quads = {
    'do': [],
    'schedule': [],
    'delegate': [],
    'delete': [],
  };
  String _selected = 'do';

  static const labels = {
    'do': 'مهم و فوری',
    'schedule': 'مهم و غیرفوری',
    'delegate': 'غیرمهم و فوری',
    'delete': 'غیرمهم و غیرفوری',
  };
  static const colors = {
    'do': Color(0xFFEF4444),
    'schedule': Color(0xFF22C55E),
    'delegate': Color(0xFFF59E0B),
    'delete': Color(0xFF94A3B8),
  };

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    for (final k in _quads.keys) {
      final list = i[k];
      if (list is List) {
        _quads[k] = list.map((e) => '$e').toList();
      }
    }
  }

  void _emit() {
    widget.onChanged({for (final e in _quads.entries) e.key: e.value});
  }

  void _add() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _quads[_selected] = [..._quads[_selected]!, t];
      _input.clear();
    });
    _emit();
  }

  void _remove(String key, int index) {
    setState(() {
      final list = [..._quads[key]!];
      list.removeAt(index);
      _quads[key] = list;
    });
    _emit();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ماتریس آیزنهاور',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: labels.entries.map((e) {
            final on = _selected == e.key;
            return ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              selected: on,
              selectedColor: colors[e.key]!.withOpacity(0.2),
              onSelected: (_) => setState(() => _selected = e.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  hintText: 'کار را بنویس…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _add,
              style: FilledButton.styleFrom(
                backgroundColor: colors[_selected],
              ),
              child: const Text('افزودن'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...labels.entries.map((e) {
          final items = _quads[e.key]!;
          final c = colors[e.key]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c,
                    fontSize: 13,
                  ),
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('خالی', style: TextStyle(fontSize: 12)),
                  )
                else
                  ...List.generate(items.length, (i) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(items[i], style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _remove(e.key, i),
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class HabitTrackerTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const HabitTrackerTool({super.key, required this.onChanged, this.initial});

  @override
  State<HabitTrackerTool> createState() => _HabitTrackerToolState();
}

class _HabitTrackerToolState extends State<HabitTrackerTool> {
  final _name = TextEditingController();
  final Map<String, bool> _days = {};

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _name.text = '${i['name'] ?? ''}';
    final d = i['days'];
    if (d is Map) {
      d.forEach((k, v) => _days['$k'] = v == true);
    }
    // ensure last 7 day keys
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      _days.putIfAbsent(key, () => false);
    }
  }

  void _emit() {
    widget.onChanged({
      'name': _name.text.trim(),
      'days': Map<String, bool>.from(_days),
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = _days.keys.toList()..sort();
    final done = _days.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ردیاب عادت',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'عادت کوچک',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 12),
          Text('۷ روز اخیر · انجام‌شده: $done',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: keys.map((k) {
              final on = _days[k] == true;
              final parts = k.split('-');
              final label = parts.length == 3 ? parts[2] : k;
              return FilterChip(
                label: Text(label),
                selected: on,
                onSelected: (v) {
                  setState(() => _days[k] = v);
                  _emit();
                },
                selectedColor: const Color(0xFF14B8A6).withOpacity(0.3),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SmartGoalTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const SmartGoalTool({super.key, required this.onChanged, this.initial});

  @override
  State<SmartGoalTool> createState() => _SmartGoalToolState();
}

class _SmartGoalToolState extends State<SmartGoalTool> {
  final ctrls = {
    's': TextEditingController(),
    'm': TextEditingController(),
    'a': TextEditingController(),
    'r': TextEditingController(),
    't': TextEditingController(),
    'step': TextEditingController(),
  };

  static const labels = {
    's': 'Specific — مشخص',
    'm': 'Measurable — قابل اندازه‌گیری',
    'a': 'Achievable — دست‌یافتنی',
    'r': 'Relevant — مرتبط',
    't': 'Time-bound — زمان‌دار',
    'step': 'قدم ۷۲ساعته',
  };

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    for (final k in ctrls.keys) {
      ctrls[k]!.text = '${i[k] ?? ''}';
    }
  }

  void _emit() {
    widget.onChanged({for (final e in ctrls.entries) e.key: e.value.text.trim()});
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: labels.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: ctrls[e.key],
            maxLines: e.key == 'step' ? 2 : 2,
            decoration: InputDecoration(
              labelText: e.value,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
        );
      }).toList(),
    );
  }
}

class TimeblockTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const TimeblockTool({super.key, required this.onChanged, this.initial});

  @override
  State<TimeblockTool> createState() => _TimeblockToolState();
}

class _TimeblockToolState extends State<TimeblockTool> {
  final List<Map<String, String>> _blocks = [];
  final _title = TextEditingController();
  final _range = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    final list = i['blocks'];
    if (list is List) {
      for (final e in list) {
        if (e is Map) {
          _blocks.add({
            'title': '${e['title'] ?? ''}',
            'range': '${e['range'] ?? ''}',
            'done': '${e['done'] ?? 'false'}',
          });
        }
      }
    }
  }

  void _emit() {
    widget.onChanged({'blocks': List<Map<String, String>>.from(_blocks)});
  }

  void _add() {
    final t = _title.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _blocks.add({
        'title': t,
        'range': _range.text.trim(),
        'done': 'false',
      });
      _title.clear();
      _range.clear();
    });
    _emit();
  }

  @override
  void dispose() {
    _title.dispose();
    _range.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('بلوک‌های امروز',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            labelText: 'عنوان بلوک',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _range,
          decoration: const InputDecoration(
            labelText: 'بازه (مثلاً ۱۰:۰۰–۱۱:۰۰)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _add,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
          child: const Text('افزودن بلوک'),
        ),
        const SizedBox(height: 12),
        ...List.generate(_blocks.length, (i) {
          final b = _blocks[i];
          final done = b['done'] == 'true';
          return CheckboxListTile(
            value: done,
            onChanged: (v) {
              setState(() => _blocks[i]['done'] = v == true ? 'true' : 'false');
              _emit();
            },
            title: Text(b['title'] ?? ''),
            subtitle: Text(b['range'] ?? ''),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}

class KaizenTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const KaizenTool({super.key, required this.onChanged, this.initial});

  @override
  State<KaizenTool> createState() => _KaizenToolState();
}

class _KaizenToolState extends State<KaizenTool> {
  final _area = TextEditingController();
  final _improve = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _area.text = '${i['area'] ?? ''}';
    _improve.text = '${i['improve'] ?? ''}';
    _note.text = '${i['note'] ?? ''}';
  }

  void _emit() {
    widget.onChanged({
      'area': _area.text.trim(),
      'improve': _improve.text.trim(),
      'note': _note.text.trim(),
    });
  }

  @override
  void dispose() {
    _area.dispose();
    _improve.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _area,
          decoration: const InputDecoration(
            labelText: 'حوزه (مثلاً تمرکز)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _improve,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'بهبود ۱٪ امروز',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'چه شد؟',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

class DeepWorkTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const DeepWorkTool({super.key, required this.onChanged, this.initial});

  @override
  State<DeepWorkTool> createState() => _DeepWorkToolState();
}

class _DeepWorkToolState extends State<DeepWorkTool> {
  final _task = TextEditingController();
  final _out = TextEditingController();
  int _minutes = 45;
  int _remaining = 45 * 60;
  bool _running = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _task.text = '${i['task'] ?? ''}';
    _out.text = '${i['out'] ?? ''}';
    _minutes = (i['minutes'] as int?) ?? 45;
    _remaining = (i['remaining'] as int?) ?? _minutes * 60;
  }

  void _emit() {
    widget.onChanged({
      'task': _task.text.trim(),
      'out': _out.text.trim(),
      'minutes': _minutes,
      'remaining': _remaining,
    });
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _t?.cancel();
        setState(() => _running = false);
        _emit();
        return;
      }
      setState(() => _remaining--);
      _emit();
    });
  }

  void _pause() {
    _t?.cancel();
    setState(() => _running = false);
    _emit();
  }

  @override
  void dispose() {
    _t?.cancel();
    _task.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF6366F1).withOpacity(0.12),
          const Color(0xFF22C55E).withOpacity(0.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('کار عمیق',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF6366F1),
              )),
          const SizedBox(height: 8),
          TextField(
            controller: _task,
            decoration: const InputDecoration(
              labelText: 'کار عمیق امروز',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 10),
          Text('$m:$s',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? _pause : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: Text(_running ? 'توقف' : 'شروع تمرکز'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _out,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'خروجی / حس بعد از بازه',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

// ——— موج ۳ ———

class _SimpleFieldsTool extends StatefulWidget {
  final String title;
  final List<(String key, String label, int lines)> fields;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  final Color accent;

  const _SimpleFieldsTool({
    required this.title,
    required this.fields,
    required this.onChanged,
    this.initial,
    this.accent = const Color(0xFF6366F1),
  });

  @override
  State<_SimpleFieldsTool> createState() => _SimpleFieldsToolState();
}

class _SimpleFieldsToolState extends State<_SimpleFieldsTool> {
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _ctrls = {
      for (final f in widget.fields)
        f.$1: TextEditingController(text: '${i[f.$1] ?? ''}'),
    };
  }

  void _emit() {
    widget.onChanged({
      for (final e in _ctrls.entries) e.key: e.value.text.trim(),
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.accent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: a.withOpacity(0.22)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            a.withOpacity(0.08),
            a.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note_rounded, color: a, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: a,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.fields.length; i++) ...[
            TextField(
              controller: _ctrls[widget.fields[i].$1],
              maxLines: widget.fields[i].$3,
              decoration: InputDecoration(
                labelText: widget.fields[i].$2,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: a,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 36, minHeight: 24),
                filled: true,
                fillColor: theme.colorScheme.surface.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: a.withOpacity(0.25)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: a.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: a, width: 1.5),
                ),
              ),
              onChanged: (_) => _emit(),
            ),
            if (i < widget.fields.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class FiveSTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const FiveSTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: '۵S',
      accent: const Color(0xFF0D9488),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('seiri', 'جداسازی (چه چیزی حذف شد؟)', 2),
        ('seiton', 'ساماندهی (جای ثابت)', 2),
        ('seiso', 'پاکیزگی (چه کردی؟)', 2),
        ('seiketsu', 'استاندارد / قانون ساده', 2),
        ('shitsuke', 'تداوم (فردا چه؟)', 2),
      ],
    );
  }
}

class KanbanTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const KanbanTool({super.key, required this.onChanged, this.initial});

  @override
  State<KanbanTool> createState() => _KanbanToolState();
}

class _KanbanToolState extends State<KanbanTool> {
  final _input = TextEditingController();
  final Map<String, List<String>> cols = {
    'todo': [],
    'doing': [],
    'done': [],
  };
  String target = 'todo';

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    for (final k in cols.keys) {
      final v = i[k];
      if (v is List) cols[k] = v.map((e) => '$e').toList();
    }
  }

  void _emit() =>
      widget.onChanged({for (final e in cols.entries) e.key: e.value});

  void _add() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      cols[target] = [...cols[target]!, t];
      _input.clear();
    });
    _emit();
  }

  void _move(String from, int index, String to) {
    setState(() {
      final item = cols[from]!.removeAt(index);
      cols[to] = [...cols[to]!, item];
    });
    _emit();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'todo': 'باید',
      'doing': 'در حال (حداکثر ۳)',
      'done': 'انجام شد',
    };
    final colors = {
      'todo': const Color(0xFF64748B),
      'doing': const Color(0xFF2563EB),
      'done': const Color(0xFF16A34A),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('کانبان',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cols['doing']!.length >= 3
                    ? const Color(0xFFEF4444).withOpacity(0.15)
                    : const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'در حال: ${cols['doing']!.length}/۳',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cols['doing']!.length >= 3
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: labels.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12)),
                    selected: target == e.key,
                    onSelected: (_) => setState(() => target = e.key),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  hintText: 'کارت جدید…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _add,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: const Text('افزودن'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final e in labels.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors[e.key]!.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors[e.key]!.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(e.value,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: colors[e.key])),
                ...List.generate(cols[e.key]!.length, (i) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cols[e.key]![i],
                        style: const TextStyle(fontSize: 13)),
                    trailing: Wrap(
                      children: [
                        if (e.key != 'todo')
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: () => _move(
                                e.key,
                                i,
                                e.key == 'done' ? 'doing' : 'todo'),
                          ),
                        if (e.key != 'done')
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: () {
                              if (e.key == 'todo' &&
                                  cols['doing']!.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'حداکثر ۳ کار همزمان در «در حال»')),
                                );
                                return;
                              }
                              _move(e.key, i,
                                  e.key == 'todo' ? 'doing' : 'done');
                            },
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class IkigaiTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const IkigaiTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'ایکیگای',
      accent: const Color(0xFFE11D48),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('love', 'دوست دارم', 2),
        ('good', 'بلدم / در آن خوبم', 2),
        ('need', 'جهان به آن نیاز دارد', 2),
        ('paid', 'بابت آن می‌توانم پاداش بگیرم', 2),
        ('experiment', 'آزمایش ۷روزه از تقاطع', 2),
      ],
    );
  }
}

class GratitudeTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const GratitudeTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'شکرگزاری',
      accent: const Color(0xFFF59E0B),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('g1', 'نعمت / اتفاق ۱', 1),
        ('g2', 'نعمت / اتفاق ۲', 1),
        ('g3', 'نعمت / اتفاق ۳', 1),
        ('why', 'چرا یکی از این‌ها مهم بود؟', 2),
      ],
    );
  }
}

class MoodTrackerTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const MoodTrackerTool({super.key, required this.onChanged, this.initial});

  @override
  State<MoodTrackerTool> createState() => _MoodTrackerToolState();
}

class _MoodTrackerToolState extends State<MoodTrackerTool> {
  int mood = 3;
  final note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    mood = (i['mood'] as int?) ?? 3;
    note.text = '${i['note'] ?? ''}';
  }

  void _emit() => widget.onChanged({'mood': mood, 'note': note.text.trim()});

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFA855F7);
    final faces = ['😔', '😐', '🙂', '😊', '😄'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
        color: accent.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حال امروز',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            faces[mood - 1],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40),
          ),
          Text(
            '$mood از ۵',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: mood.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$mood',
            activeColor: accent,
            onChanged: (v) {
              setState(() => mood = v.round());
              _emit();
            },
          ),
          TextField(
            controller: note,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'چه چیزی روی حالت اثر داشت؟',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

class GrowthMindsetTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const GrowthMindsetTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'ذهن رشد',
      accent: const Color(0xFF059669),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('situation', 'موقعیت', 2),
        ('fixed', 'فکر ثابت', 2),
        ('growth', 'جمله رشد جایگزین', 2),
        ('step', 'قدم آزمایشی کوچک', 2),
      ],
    );
  }
}

class PdcaTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const PdcaTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'PDCA',
      accent: const Color(0xFFEA580C),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('plan', 'Plan — طرح', 2),
        ('do', 'Do — اجرا', 2),
        ('check', 'Check — بررسی', 2),
        ('act', 'Act — اقدام بعدی', 2),
      ],
    );
  }
}

class HoshinTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const HoshinTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'هوشین (ساده)',
      accent: const Color(0xFF7C3AED),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('aim', 'هدف ۱۲ماهه', 2),
        ('a1', 'اقدام کلیدی ۱', 1),
        ('a2', 'اقدام کلیدی ۲', 1),
        ('a3', 'اقدام کلیدی ۳', 1),
        ('metric', 'سنجه موفقیت', 2),
      ],
    );
  }
}

class WheelTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const WheelTool({super.key, required this.onChanged, this.initial});

  @override
  State<WheelTool> createState() => _WheelToolState();
}

class _WheelToolState extends State<WheelTool> {
  static const areas = [
    'سلامت',
    'کار/درآمد',
    'رشد',
    'رابطه',
    'خانواده',
    'تفریح',
    'محیط',
    'معنا',
  ];
  late Map<String, double> scores;
  final step = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    scores = {
      for (final a in areas) a: ((i[a] as num?)?.toDouble() ?? 5),
    };
    step.text = '${i['step'] ?? ''}';
  }

  void _emit() {
    widget.onChanged({
      ...scores,
      'step': step.text.trim(),
    });
  }

  @override
  void dispose() {
    step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final a in areas)
          Row(
            children: [
              SizedBox(width: 88, child: Text(a, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: Slider(
                  value: scores[a]!,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: scores[a]!.round().toString(),
                  activeColor: const Color(0xFFF43F5E),
                  onChanged: (v) {
                    setState(() => scores[a] = v);
                    _emit();
                  },
                ),
              ),
              Text('${scores[a]!.round()}'),
            ],
          ),
        TextField(
          controller: step,
          decoration: const InputDecoration(
            labelText: 'قدم کوچک این هفته برای یک حوزه',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

class CbtJournalTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const CbtJournalTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'ژورنال CBT (ساده)',
      accent: const Color(0xFF0284C7),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('situation', 'موقعیت', 2),
        ('feeling', 'احساس', 1),
        ('thought', 'فکر خودکار', 2),
        ('reframe', 'بازنویسی متعادل', 2),
      ],
    );
  }
}

class SwotTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const SwotTool({super.key, required this.onChanged, this.initial});

  @override
  State<SwotTool> createState() => _SwotToolState();
}

class _SwotToolState extends State<SwotTool> {
  final topic = TextEditingController();
  final ctrls = {
    's': TextEditingController(),
    'w': TextEditingController(),
    'o': TextEditingController(),
    't': TextEditingController(),
    'act1': TextEditingController(),
    'act2': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    topic.text = '${i['topic'] ?? ''}';
    for (final k in ctrls.keys) {
      ctrls[k]!.text = '${i[k] ?? ''}';
    }
  }

  void _emit() {
    widget.onChanged({
      'topic': topic.text.trim(),
      for (final e in ctrls.entries) e.key: e.value.text.trim(),
    });
  }

  @override
  void dispose() {
    topic.dispose();
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget box(String key, String label, Color c) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: TextField(
          controller: ctrls[key],
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            labelStyle: TextStyle(color: c, fontWeight: FontWeight.w800),
          ),
          onChanged: (_) => _emit(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SWOT',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: topic,
          decoration: const InputDecoration(
            labelText: 'موضوع تحلیل',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 8),
        box('s', 'قوت‌ها (S)', const Color(0xFF16A34A)),
        box('w', 'ضعف‌ها (W)', const Color(0xFFEA580C)),
        box('o', 'فرصت‌ها (O)', const Color(0xFF2563EB)),
        box('t', 'تهدیدها (T)', const Color(0xFFDC2626)),
        TextField(
          controller: ctrls['act1'],
          decoration: const InputDecoration(
            labelText: 'اقدام از قوت×فرصت',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrls['act2'],
          decoration: const InputDecoration(
            labelText: 'اقدام از ضعف×تهدید',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

class ParetoTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const ParetoTool({super.key, required this.onChanged, this.initial});

  @override
  State<ParetoTool> createState() => _ParetoToolState();
}

class _ParetoToolState extends State<ParetoTool> {
  final _input = TextEditingController();
  final List<Map<String, String>> items = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    final list = i['items'];
    if (list is List) {
      for (final e in list) {
        if (e is Map) {
          items.add({
            'title': '${e['title'] ?? ''}',
            'impact': '${e['impact'] ?? 'med'}',
          });
        }
      }
    }
  }

  void _emit() => widget.onChanged({'items': List<Map<String, String>>.from(items)});

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('۸۰/۲۰',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  hintText: 'مورد…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final t = _input.text.trim();
                if (t.isEmpty) return;
                setState(() {
                  items.add({'title': t, 'impact': 'med'});
                  _input.clear();
                });
                _emit();
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFFB45309)),
            ),
          ],
        ),
        ...List.generate(items.length, (i) {
          final it = items[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(it['title'] ?? ''),
            subtitle: Text({
              'high': 'اثر زیاد',
              'med': 'اثر متوسط',
              'low': 'اثر کم',
            }[it['impact']]!),
            trailing: DropdownButton<String>(
              value: it['impact'],
              items: const [
                DropdownMenuItem(value: 'high', child: Text('زیاد')),
                DropdownMenuItem(value: 'med', child: Text('متوسط')),
                DropdownMenuItem(value: 'low', child: Text('کم')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => items[i]['impact'] = v);
                _emit();
              },
            ),
          );
        }),
      ],
    );
  }
}

class GtdNextTool extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const GtdNextTool({super.key, required this.onChanged, this.initial});

  @override
  State<GtdNextTool> createState() => _GtdNextToolState();
}

class _GtdNextToolState extends State<GtdNextTool> {
  final project = TextEditingController();
  final next = TextEditingController();
  final List<Map<String, String>> rows = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    final list = i['rows'];
    if (list is List) {
      for (final e in list) {
        if (e is Map) {
          rows.add({
            'project': '${e['project'] ?? ''}',
            'next': '${e['next'] ?? ''}',
          });
        }
      }
    }
  }

  void _emit() =>
      widget.onChanged({'rows': List<Map<String, String>>.from(rows)});

  @override
  void dispose() {
    project.dispose();
    next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: project,
          decoration: const InputDecoration(
            labelText: 'پروژه / سربار',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: next,
          decoration: const InputDecoration(
            labelText: 'اقدام فیزیکی بعدی',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            if (next.text.trim().isEmpty) return;
            setState(() {
              rows.add({
                'project': project.text.trim(),
                'next': next.text.trim(),
              });
              project.clear();
              next.clear();
            });
            _emit();
          },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
          child: const Text('افزودن به لیست'),
        ),
        ...rows.map((r) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r['next'] ?? ''),
              subtitle: Text(r['project'] ?? ''),
            )),
      ],
    );
  }
}

class OkrLiteTool extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onChanged;
  final Map<String, dynamic>? initial;
  const OkrLiteTool({super.key, required this.onChanged, this.initial});

  @override
  Widget build(BuildContext context) {
    return _SimpleFieldsTool(
      title: 'OKR سبک',
      accent: const Color(0xFFDB2777),
      initial: initial,
      onChanged: onChanged,
      fields: const [
        ('objective', 'Objective (هدف کیفی)', 2),
        ('kr1', 'نتیجه کلیدی ۱', 1),
        ('kr2', 'نتیجه کلیدی ۲', 1),
        ('kr3', 'نتیجه کلیدی ۳', 1),
        ('progress', 'پیشرفت تقریبی / یادداشت', 2),
      ],
    );
  }
}

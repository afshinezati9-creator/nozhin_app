import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/program_guides.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../providers/planning_provider.dart';

// ═══════════════════════════════════════════════════════════
// فاز B — هسته مشترک برنامه‌ها
// ═══════════════════════════════════════════════════════════

/// پوسته مشترک: راهنما · جهت متن · ذخیره · چک‌لیست · SMART · بدنه
class ProgramChrome extends ConsumerStatefulWidget {
  final String programId;
  final String? title;
  final Widget child;
  final bool showChecklist;
  final bool showSmart;
  final bool showMoodBeforeAfter;
  /// اگر true باشد، child داخل Expanded قرار می‌گیرد (برای HabitsPane و مشابه)
  final bool expandChild;

  const ProgramChrome({
    super.key,
    required this.programId,
    required this.child,
    this.title,
    this.showChecklist = true,
    this.showSmart = true,
    this.showMoodBeforeAfter = false,
    this.expandChild = false,
  });

  @override
  ConsumerState<ProgramChrome> createState() => _ProgramChromeState();
}

class _ProgramChromeState extends ConsumerState<ProgramChrome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _helpPulse;
  TextDirection _dir = TextDirection.rtl;
  final List<_ChecklistItem> _checklist = [];
  final Map<String, TextEditingController> _smartCtrls = {
    's': TextEditingController(),
    'm': TextEditingController(),
    'a': TextEditingController(),
    'r': TextEditingController(),
    't': TextEditingController(),
  };
  bool _smartOpen = false;
  bool _checkOpen = true;
  int? _moodBefore;
  int? _moodAfter;
  bool _savedFlash = false;

  String get _ckKey => '${widget.programId}__checklist_json';
  String get _smartKey => '${widget.programId}__smart_json';
  String get _moodKey => '${widget.programId}__mood_ba';
  String get _dirKey => '${widget.programId}__dir';

  @override
  void initState() {
    super.initState();
    _helpPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    _helpPulse.dispose();
    for (final c in _smartCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate() {
    final notes = ref.read(planningProvider).programNotes;
    final dir = notes[_dirKey];
    if (dir == 'ltr') _dir = TextDirection.ltr;

    final raw = notes[_ckKey];
    if (raw != null && raw.isNotEmpty) {
      _checklist
        ..clear()
        ..addAll(_parseChecklist(raw));
    }
    final smart = notes[_smartKey];
    if (smart != null && smart.isNotEmpty) {
      final map = _parseKv(smart);
      for (final e in map.entries) {
        _smartCtrls[e.key]?.text = e.value;
      }
    }
    final mood = notes[_moodKey];
    if (mood != null && mood.contains('|')) {
      final parts = mood.split('|');
      _moodBefore = int.tryParse(parts[0]);
      _moodAfter = int.tryParse(parts.length > 1 ? parts[1] : '');
    }
    if (mounted) setState(() {});
  }

  List<_ChecklistItem> _parseChecklist(String raw) {
    // format: done§text\n
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty);
    return lines.map((l) {
      final parts = l.split('§');
      if (parts.length >= 2) {
        return _ChecklistItem(done: parts[0] == '1', text: parts.sublist(1).join('§'));
      }
      return _ChecklistItem(done: false, text: l);
    }).toList();
  }

  String _encodeChecklist() =>
      _checklist.map((e) => '${e.done ? 1 : 0}§${e.text}').join('\n');

  Map<String, String> _parseKv(String raw) {
    final m = <String, String>{};
    for (final line in raw.split('\n')) {
      final i = line.indexOf('=');
      if (i > 0) m[line.substring(0, i)] = line.substring(i + 1);
    }
    return m;
  }

  String _encodeSmart() =>
      _smartCtrls.entries.map((e) => '${e.key}=${e.value.text.trim()}').join('\n');

  Future<void> _saveAll() async {
    final n = ref.read(planningProvider.notifier);
    await n.saveProgramNote(_ckKey, _encodeChecklist());
    await n.saveProgramNote(_smartKey, _encodeSmart());
    await n.saveProgramNote(_dirKey, _dir == TextDirection.rtl ? 'rtl' : 'ltr');
    if (widget.showMoodBeforeAfter) {
      await n.saveProgramNote(
        _moodKey,
        '${_moodBefore ?? ''}|${_moodAfter ?? ''}',
      );
    }
    if (!mounted) return;
    setState(() => _savedFlash = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ذخیره شد'),
        duration: Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _savedFlash = false);
    });
  }

  void _openHelp() {
    final guide = programGuides[widget.programId] ??
        'این برنامه بخشی از سیستم برنامه‌ریزی هاوژین است. فیلدها را پر کن، ذخیره بزن و در پایان دوره آرشیو کن.';
    final sections = guide
        .split(RegExp(r'\n\s*\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, sc) => ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: AppColors.brand3),
                  const SizedBox(width: 8),
                  Text(
                    'راهنمای استفاده',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...sections.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brand3.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.brand3.withOpacity(0.15)),
                    ),
                    child: Text(s.trim(),
                        style: const TextStyle(height: 1.5, fontSize: 13.5)),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: _dir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // نوار ابزار مشترک
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // ؟ انیمیشنی
                ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(
                        parent: _helpPulse, curve: Curves.easeInOut),
                  ),
                  child: IconButton(
                    tooltip: 'راهنما',
                    onPressed: _openHelp,
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brand3,
                            AppColors.brand3.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand3.withOpacity(0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.question_mark_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                TextDirToggle(
                  direction: _dir,
                  onChanged: (d) => setState(() => _dir = d),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: _saveAll,
                  icon: Icon(
                    _savedFlash ? Icons.check_rounded : Icons.save_rounded,
                    size: 18,
                  ),
                  label: Text(_savedFlash ? 'ذخیره شد' : 'ذخیره'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (widget.showMoodBeforeAfter) ...[
            MoodBeforeAfter(
              before: _moodBefore,
              after: _moodAfter,
              onBefore: (v) => setState(() => _moodBefore = v),
              onAfter: (v) => setState(() => _moodAfter = v),
            ),
            const SizedBox(height: 10),
          ],

          if (widget.showSmart) ...[
            _ExpandSection(
              title: 'هدف SMART این دوره',
              open: _smartOpen,
              onToggle: () => setState(() => _smartOpen = !_smartOpen),
              child: ProgramSmartBlock(controllers: _smartCtrls),
            ),
            const SizedBox(height: 8),
          ],

          if (widget.showChecklist) ...[
            _ExpandSection(
              title:
                  'چک‌لیست (${MoneyFormat.toPersianDigits('${_checklist.where((e) => e.done).length}')}/${MoneyFormat.toPersianDigits('${_checklist.length}')})',
              open: _checkOpen,
              onToggle: () => setState(() => _checkOpen = !_checkOpen),
              child: ProgramChecklist(
                items: _checklist,
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // بدنه اختصاصی
          if (widget.expandChild)
            Expanded(child: widget.child)
          else
            widget.child,
        ],
      ),
    );
  }
}

class _ExpandSection extends StatelessWidget {
  final String title;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandSection({
    required this.title,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    open
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_left_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// تغییر جهت نوشتار
class TextDirToggle extends StatelessWidget {
  final TextDirection direction;
  final ValueChanged<TextDirection> onChanged;

  const TextDirToggle({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TextDirection>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(
          value: TextDirection.rtl,
          label: Text('راست', style: TextStyle(fontSize: 11)),
          icon: Icon(Icons.format_textdirection_r_to_l, size: 14),
        ),
        ButtonSegment(
          value: TextDirection.ltr,
          label: Text('چپ', style: TextStyle(fontSize: 11)),
          icon: Icon(Icons.format_textdirection_l_to_r, size: 14),
        ),
      ],
      selected: {direction},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// فیلد با ارتفاع خودکار (بدون اسکرول داخلی اجباری)
class ExpandingTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSave;

  const ExpandingTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.minLines = 2,
    this.maxLines = 12,
    this.onChanged,
    this.onSave,
  });

  @override
  State<ExpandingTextField> createState() => _ExpandingTextFieldState();
}

class _ExpandingTextFieldState extends State<ExpandingTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        alignLabelWithHint: true,
        suffixIcon: widget.onSave == null
            ? null
            : IconButton(
                tooltip: 'ذخیره این فیلد',
                icon: const Icon(Icons.check_rounded, size: 20),
                onPressed: widget.onSave,
              ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _ChecklistItem {
  bool done;
  String text;
  _ChecklistItem({required this.done, required this.text});
}

/// چک‌لیست مشترک
class ProgramChecklist extends StatefulWidget {
  final List<_ChecklistItem> items;
  final VoidCallback onChanged;

  const ProgramChecklist({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ProgramChecklist> createState() => _ProgramChecklistState();
}

class _ProgramChecklistState extends State<ProgramChecklist> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ...List.generate(widget.items.length, (i) {
          final item = widget.items[i];
          return Dismissible(
            key: ValueKey('ck_${i}_${item.text}'),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) {
              widget.items.removeAt(i);
              widget.onChanged();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              color: theme.colorScheme.error.withOpacity(0.15),
              child: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
            ),
            child: CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: item.done,
              onChanged: (v) {
                setState(() => item.done = v ?? false);
                widget.onChanged();
              },
              title: Text(
                item.text,
                style: TextStyle(
                  decoration:
                      item.done ? TextDecoration.lineThrough : null,
                  color: item.done
                      ? theme.colorScheme.onSurface.withOpacity(0.45)
                      : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                decoration: const InputDecoration(
                  hintText: 'آیتم جدید…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }

  void _add() {
    final t = _addCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      widget.items.add(_ChecklistItem(done: false, text: t));
      _addCtrl.clear();
    });
    widget.onChanged();
  }
}

/// بلوک SMART مشترک
class ProgramSmartBlock extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const ProgramSmartBlock({super.key, required this.controllers});

  static const _labels = {
    's': 'Specific — مشخص',
    'm': 'Measurable — قابل اندازه‌گیری',
    'a': 'Achievable — قابل دستیابی',
    'r': 'Relevant — مرتبط',
    't': 'Time-bound — زمان‌دار',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _labels.entries.map((e) {
        final ctrl = controllers[e.key]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ExpandingTextField(
            controller: ctrl,
            label: e.value,
            minLines: 1,
            maxLines: 4,
          ),
        );
      }).toList(),
    );
  }
}

/// حس قبل / بعد
class MoodBeforeAfter extends StatelessWidget {
  final int? before;
  final int? after;
  final ValueChanged<int> onBefore;
  final ValueChanged<int> onAfter;

  const MoodBeforeAfter({
    super.key,
    required this.before,
    required this.after,
    required this.onBefore,
    required this.onAfter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('حس قبل و بعد',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('قبل از کار', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          _MoodRow(value: before, onSelect: onBefore),
          const SizedBox(height: 10),
          Text('بعد از کار', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          _MoodRow(value: after, onSelect: onAfter),
        ],
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onSelect;
  const _MoodRow({required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(5, (i) {
        final s = i + 1;
        final sel = value == s;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onSelect(s),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  MoneyFormat.toPersianDigits('$s'),
                  style: TextStyle(
                    color: sel ? Colors.white : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

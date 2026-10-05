import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/planning_constants.dart';
import '../../../core/constants/program_guides.dart';
import '../../../core/constants/program_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/planning_provider.dart';

/// صفحه انتخاب مدل یا تنظیمات/شخصی‌سازی یک مدل
class ProgramSetupScreen extends ConsumerStatefulWidget {
  final String? programId; // null = انتخاب از لیست
  final bool activateOnSave;

  const ProgramSetupScreen({
    super.key,
    this.programId,
    this.activateOnSave = true,
  });

  @override
  ConsumerState<ProgramSetupScreen> createState() => _ProgramSetupScreenState();
}

class _ProgramSetupScreenState extends ConsumerState<ProgramSetupScreen> {
  String? _selectedId;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _goalCtrl;
  int _intensity = 3; // 1-5
  bool _reminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedId = widget.programId;
    final notes = ref.read(planningProvider).programNotes;
    _noteCtrl = TextEditingController(
      text: _selectedId != null ? (notes['${_selectedId}_setup'] ?? '') : '',
    );
    _goalCtrl = TextEditingController(
      text: _selectedId != null ? (notes['${_selectedId}_goal'] ?? '') : '',
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  ProgramDef? get _def {
    final id = _selectedId;
    if (id == null) return null;
    final list = programCatalog.where((p) => p.id == id);
    return list.isEmpty ? null : list.first;
  }

  Future<void> _save() async {
    final id = _selectedId;
    if (id == null) return;
    final notifier = ref.read(planningProvider.notifier);
    await notifier.saveProgramNote('${id}_setup', _noteCtrl.text.trim());
    await notifier.saveProgramNote('${id}_goal', _goalCtrl.text.trim());
    await notifier.saveProgramNote(
        '${id}_intensity', _intensity.toString());
    await notifier.saveProgramNote(
        '${id}_reminder', _reminder ? '1' : '0');
    if (widget.activateOnSave) {
      final active = ref.read(planningProvider).activePrograms;
      if (!active.contains(id)) {
        await notifier.toggleProgram(id);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ذخیره شد'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 1),
      ));
      Navigator.pop(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = _def;

    // مرحله انتخاب مدل
    if (_selectedId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('انتخاب مدل برنامه‌ریزی'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
          children: [
            Text(
              'یک مدل را برای زندگی فردی‌ات انتخاب و شخصی‌سازی کن',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 12),
            ...programCatalog.map((p) {
              final on =
                  ref.watch(planningProvider).activePrograms.contains(p.id);
              final color = programColor(p.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedId = p.id;
                        final notes =
                            ref.read(planningProvider).programNotes;
                        _noteCtrl.text = notes['${p.id}_setup'] ?? '';
                        _goalCtrl.text = notes['${p.id}_goal'] ?? '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: on
                              ? color
                              : theme.colorScheme.outline,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(programIcon(p.id),
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: theme
                                            .textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w900),
                                      ),
                                    ),
                                    if (on)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'فعال',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.desc,
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  p.origin,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.35)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // مرحله تنظیمات مدل
    final guide = programGuides[def!.id] ?? def.desc;

    return Scaffold(
      appBar: AppBar(
        title: Text(def.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.programId == null) {
              setState(() => _selectedId = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('ذخیره',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text('${def.desc} · ${def.origin}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('آموزش گام‌به‌گام',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...guide
              .split(RegExp(r'\n\s*\n'))
              .where((s) => s.trim().isNotEmpty)
              .map((sec) {
            final lines = sec.trim().split('\n');
            final title = lines.first.trim();
            final body = lines.length > 1
                ? lines.skip(1).join('\n').trim()
                : '';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brand3.withOpacity(0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand3,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(body,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(height: 1.65)),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text('هدف شخصی از این برنامه',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _goalCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'مثلاً: هر روز ۲۵ دقیقه مطالعه عمیق',
            ),
          ),
          const SizedBox(height: 14),
          Text('یادداشت / شخصی‌سازی',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'قوانین خودت، استثناها، انگیزه…',
            ),
          ),
          const SizedBox(height: 14),
          Text('شدت تعهد (۱ تا ۵)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_intensity',
            activeColor: AppColors.brand3,
            onChanged: (v) => setState(() => _intensity = v.round()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('یادآوری روزانه (نمایشی)'),
            subtitle: Text(
              _reminder
                  ? 'ساعت ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
                  : 'فعلاً فقط ذخیره می‌شود؛ اعلان سیستم بعداً',
            ),
            value: _reminder,
            activeThumbColor: AppColors.brand3,
            onChanged: (v) => setState(() => _reminder = v),
          ),
          if (_reminder)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ساعت یادآوری'),
              trailing: Text(
                '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime,
                );
                if (t != null) setState(() => _reminderTime = t);
              },
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand3,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              widget.activateOnSave ? 'فعال‌سازی و ذخیره' : 'ذخیره تنظیمات',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

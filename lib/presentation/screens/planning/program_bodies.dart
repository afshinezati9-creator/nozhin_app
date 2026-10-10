import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/program_guides.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/utils/jalali.dart';
import '../../../domain/entities/eisen_task_entity.dart';
import '../../providers/planning_provider.dart';
import '../../widgets/planning/program_shared.dart';
import '../../widgets/planning/shamsi_grids.dart';

/// بدنهٔ غنی هر برنامه — مناسب زندگی روزمره در ایران
class ProgramBody extends ConsumerWidget {
  final String programId;
  const ProgramBody({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (programId) {
      case 'pomodoro':
      case 'kanban':
      case 'habits':
      case 'eisen':
        return const SizedBox.shrink();
      case 'mood':
        return const MoodBody();
      case 'frog':
        return const FrogBody();
      case 'wheel':
        return const WheelBody();
      case 'fiveS':
        return const FiveSBody();
      case 'ikigai':
        return const IkigaiBody();
      case 'gratitude':
        return const GratitudeBody();
      case 'twoMin':
        return const TwoMinBody();
      case 'smart':
        return const SmartBody();
      case 'timeblock':
        return const TimeblockBody();
      case 'pdca':
        return const PdcaBody();
      case 'kaizen':
        return const KaizenBody();
      case 'kaizen_legacy_unused':
        return const ChecklistJournalBody(
          programId: 'kaizen',
          title: 'بهبود ۱٪ امروز',
          prompts: [
            'یک کار کوچک که امروز بهتر انجام دادم',
            'یک اشتباه که از آن یاد گرفتم',
            'فردا همان را ۱٪ بهتر چطور انجام می‌دهم؟',
          ],
        );
      case 'cbt':
        return const ChecklistJournalBody(
          programId: 'cbt',
          title: 'ژورنال CBT',
          prompts: [
            'موقعیت چه بود؟',
            'فکر خودکار چه بود؟',
            'چه احساسی داشتم؟ (۰–۱۰)',
            'شواهد مخالف این فکر؟',
            'فکر متعادل‌تر چیست؟',
          ],
        );
      case 'growth':
        return const ChecklistJournalBody(
          programId: 'growth',
          title: 'ذهن رشد',
          prompts: [
            'امروز کجا گیر کردم یا شکست خوردم؟',
            'چه مهارتی از آن یاد گرفتم؟',
            'دفعه بعد دقیقاً چه کار متفاوتی می‌کنم؟',
          ],
        );
      case 'deepwork':
        return const DeepWorkBody();
      case 'hoshin':
        return const HoshinBody();
      default:
        return GenericRichBody(programId: programId);
    }
  }
}

Future<void> _save(WidgetRef ref, String key, String val) =>
    ref.read(planningProvider.notifier).saveProgramNote(key, val);

String _note(WidgetRef ref, String key) =>
    ref.watch(planningProvider).programNotes[key] ?? '';

// ─── Mood ───────────────────────────────────────────────
class MoodBody extends ConsumerWidget {
  const MoodBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(planningProvider).moodMap;
    final n = DateTime.now();
    final key =
        '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    final current = map[key];
    const emoji = ['😞', '😕', '😐', '🙂', '😄'];
    const labels = ['خیلی بد', 'بد', 'معمولی', 'خوب', 'عالی'];
    final noteCtrl = TextEditingController(text: _note(ref, 'mood_note_$key'));
    final sleepCtrl =
        TextEditingController(text: _note(ref, 'mood_sleep_$key'));
    final energyCtrl =
        TextEditingController(text: _note(ref, 'mood_energy_$key'));
    final triggerCtrl =
        TextEditingController(text: _note(ref, 'mood_trigger_$key'));

    // last 7 days mini trend
    final days = List.generate(7, (i) {
      final d = n.subtract(Duration(days: 6 - i));
      final k =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return MapEntry(k, map[k]);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.mood_rounded,
          title: 'فرایند مود امروز',
          subtitle: '۱ نمره · ۲ عوامل · ۳ یادداشت · ۴ روند ۳۰روز',
        ),
        MonthStripShamsi(
          anchor: n,
          scores: map,
          onDayTap: (d) {
            final k = dateKey(d);
          },
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          if (map.isEmpty) {
            return Text('هنوز داده مود برای تحلیل نیست',
                style: Theme.of(context).textTheme.bodySmall);
          }
          final vals = map.values.toList();
          final avg = vals.reduce((a, b) => a + b) / vals.length;
          final best = vals.reduce((a, b) => a > b ? a : b);
          final worst = vals.reduce((a, b) => a < b ? a : b);
          // روز هفته الگو
          final byWd = List.filled(7, 0.0);
          final cnt = List.filled(7, 0);
          for (final e in map.entries) {
            final parts = e.key.split('-');
            if (parts.length != 3) continue;
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            final wi = dt.weekday % 7; // approx
            byWd[wi] += e.value;
            cnt[wi] += 1;
          }
          var bestWd = 0;
          var bestAvg = -1.0;
          for (var i = 0; i < 7; i++) {
            if (cnt[i] == 0) continue;
            final a = byWd[i] / cnt[i];
            if (a > bestAvg) {
              bestAvg = a;
              bestWd = i;
            }
          }
          const names = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand3.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'تحلیل روند مود: میانگین ${avg.toStringAsFixed(1)} از ۵ · بهترین ${best} · ضعیف‌ترین ${worst} · '
              '${map.length} روز ثبت‌شده'
              '${bestAvg > 0 ? " · معمولاً روز ${names[bestWd]} بهتر است" : ""}',
              style: const TextStyle(height: 1.45, fontSize: 13),
            ),
          );
        }),
        const SizedBox(height: 10),
        _ProcessCard(
          step: '۱',
          title: 'نمره حال',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final score = i + 1;
              final sel = current == score;
              return InkWell(
                onTap: () =>
                    ref.read(planningProvider.notifier).setMood(key, score),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.brand3.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppColors.brand3
                          : Colors.grey.withOpacity(0.25),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(emoji[i], style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(labels[i],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                sel ? FontWeight.w900 : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        _ProcessCard(
          step: '۲',
          title: 'عوامل تأثیرگذار',
          child: Column(
            children: [
              TextField(
                controller: sleepCtrl,
                decoration: const InputDecoration(
                  labelText: 'خواب (ساعت تقریبی)',
                  hintText: 'مثلاً ۶',
                  prefixIcon: Icon(Icons.bedtime_outlined),
                ),
                onSubmitted: (v) => _save(ref, 'mood_sleep_$key', v.trim()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: energyCtrl,
                decoration: const InputDecoration(
                  labelText: 'سطح انرژی (۱–۵)',
                  prefixIcon: Icon(Icons.bolt_outlined),
                ),
                onSubmitted: (v) => _save(ref, 'mood_energy_$key', v.trim()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: triggerCtrl,
                decoration: const InputDecoration(
                  labelText: 'محرک اصلی حال',
                  hintText: 'کار، خانواده، خبر، ترافیک…',
                  prefixIcon: Icon(Icons.flash_on_outlined),
                ),
                onSubmitted: (v) =>
                    _save(ref, 'mood_trigger_$key', v.trim()),
              ),
            ],
          ),
        ),
        _ProcessCard(
          step: '۳',
          title: 'یادداشت کوتاه',
          child: TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'امروز چه چیزی حال را ساخت؟',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => _save(ref, 'mood_note_$key', v.trim()),
          ),
        ),
        _ProcessCard(
          step: '۴',
          title: 'روند ۷ روز اخیر',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((e) {
              final v = e.value;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28 + (v != null ? v * 6.0 : 0),
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: v == null
                          ? Colors.grey.withOpacity(0.2)
                          : AppColors.brand3.withOpacity(0.2 + v * 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      v == null ? '–' : emoji[v - 1],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MoneyFormat.toPersianDigits(e.key.substring(8)),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            _save(ref, 'mood_note_$key', noteCtrl.text.trim());
            _save(ref, 'mood_sleep_$key', sleepCtrl.text.trim());
            _save(ref, 'mood_energy_$key', energyCtrl.text.trim());
            _save(ref, 'mood_trigger_$key', triggerCtrl.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('مود امروز ذخیره شد'),
              behavior: SnackBarBehavior.fixed,
            ));
          },
          icon: const Icon(Icons.check),
          label: const Text('ثبت کامل مود امروز'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}

// ─── Frog ───────────────────────────────────────────────
class FrogBody extends ConsumerWidget {
  const FrogBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = WeekGridShamsi.saturdayOf(DateTime.now());
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.priority_high_rounded,
          title: 'قورباغه هفتگی',
          subtitle: 'هر روز یک کار سخت · از شنبه · باکس بازشو برای روزهای دیگر',
        ),
        ...List.generate(7, (i) {
          final d = days[i];
          final key = dateKey(d);
          final j = Jalali.fromDateTime(d);
          final title = '${kShamsiWeekdaysFull[i]} ${j.day} ${j.monthName}';
          final frog = _note(ref, 'frog_$key');
          final done = _note(ref, 'frog_done_$key') == '1';
          final ctrl = TextEditingController(text: frog);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              initiallyExpanded: i == shamsiWeekdayIndex(DateTime.now()),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? const Color(0xFF22C55E) : null,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'قورباغه امروز (سخت‌ترین کار)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _save(ref, 'frog_$key', ctrl.text.trim()),
                              child: const Text('ذخیره'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await _save(ref, 'frog_$key', ctrl.text.trim());
                                await _save(ref, 'frog_done_$key', done ? '0' : '1');
                              },
                              child: Text(done ? 'لغو انجام' : 'انجام شد'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        Builder(builder: (context) {
          final doneN = days.where((d) => _note(ref, 'frog_done_${dateKey(d)}') == '1').length;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand3.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'تحلیل هفته: $doneN از ۷ قورباغه انجام شد '
              '(${(doneN / 7 * 100).round()}٪). '
              '${doneN >= 5 ? "عالی — سخت‌ها را خوردی." : doneN >= 3 ? "خوب پیش می‌روی." : "هنوز جا برای بلعیدن قورباغه‌ها هست."}',
              style: const TextStyle(height: 1.45, fontSize: 13),
            ),
          );
        }),
      ],
    );
  }
}


// ─── Wheel ──────────────────────────────────────────────
class WheelBody extends ConsumerWidget {
  const WheelBody({super.key});

  static const areas = [
    ('health', 'سلامت'),
    ('career', 'شغل/تحصیل'),
    ('money', 'مالی'),
    ('family', 'خانواده'),
    ('friends', 'دوستان'),
    ('growth', 'رشد فردی'),
    ('fun', 'تفریح'),
    ('spirit', 'معنویت'),
  ];

  String _direction(int v) {
    if (v <= 3) return 'ضعیف — نیاز به توجه فوری';
    if (v <= 5) return 'متوسط رو به ضعیف';
    if (v <= 7) return 'قابل قبول — جا برای رشد';
    return 'قوی — حفظ و تقویت';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.donut_large_rounded,
          title: 'چرخ زندگی',
          subtitle: 'نمره ۱–۱۰ · جهت ضعیف/قوی · تحلیل متنی هر حوزه',
        ),
        ...areas.map((a) {
          final key = 'wheel_${a.$1}';
          final raw = _note(ref, key);
          final val = int.tryParse(raw) ?? 5;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(a.$2,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Text('$val / ۱۰',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Slider(
                    value: val.toDouble().clamp(1, 10),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$val',
                    onChanged: (v) {
                      _save(ref, key, '${v.round()}');
                    },
                  ),
                  Text(_direction(val),
                      style: TextStyle(
                        fontSize: 12,
                        color: val <= 3
                            ? const Color(0xFFEF4444)
                            : val <= 5
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          );
        }),
        Builder(builder: (context) {
          final scores = areas.map((a) {
            return int.tryParse(_note(ref, 'wheel_${a.$1}')) ?? 5;
          }).toList();
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          final minI = scores.indexOf(scores.reduce((a, b) => a < b ? a : b));
          final maxI = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand3.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'تحلیل چرخ: میانگین ${avg.toStringAsFixed(1)} از ۱۰. '
              'قوی‌ترین: ${areas[maxI].$2}. ضعیف‌ترین: ${areas[minI].$2} — '
              'این هفته روی «${areas[minI].$2}» یک اقدام کوچک بگذار.',
              style: const TextStyle(height: 1.45, fontSize: 13),
            ),
          );
        }),
      ],
    );
  }
}


class FiveSBody extends ConsumerWidget {
  const FiveSBody({super.key});

  static const steps = [
    ('Seiri — جداسازی', 'چیزهای غیرضروری را جدا یا دور بریز', 'fiveS_note_0'),
    ('Seiton — نظم', 'برای هر چیز یک جای ثابت تعریف کن', 'fiveS_note_1'),
    ('Seiso — تمیزی', 'سطح کار، صفحه گوشی، یا اتاق را تمیز کن', 'fiveS_note_2'),
    ('Seiketsu — استاندارد', 'یک قانون ساده بنویس تا نظم حفظ شود', 'fiveS_note_3'),
    ('Shitsuke — استمرار', 'امروز همان قانون را رعایت کردم', 'fiveS_note_4'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(planningProvider).programNotes;
    final theme = Theme.of(context);
    final doneCount =
        List.generate(5, (i) => notes['fiveS_$i'] == '1').where((e) => e).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.cleaning_services_outlined,
          title: 'چک‌لیست ۵S امروز',
          subtitle:
              '${MoneyFormat.toPersianDigits('$doneCount')} از ۵ انجام شد',
        ),
        const _Tip(
          'از یک نقطه کوچک شروع کن: کشوی میز، صفحه اصلی گوشی، یا کیف روزانه. برای هر مرحله جزئیات بنویس.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: doneCount / 5,
              minHeight: 8,
              backgroundColor: AppColors.brand3.withOpacity(0.12),
              color: AppColors.brand3,
            ),
          ),
        ),
        ...List.generate(steps.length, (i) {
          final done = notes['fiveS_$i'] == '1';
          final noteKey = steps[i].$3;
          final noteCtrl = TextEditingController(text: notes[noteKey] ?? '');
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: done,
                    activeColor: AppColors.brand3,
                    title: Text(steps[i].$1,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text(steps[i].$2),
                    onChanged: (v) =>
                        _save(ref, 'fiveS_$i', v == true ? '1' : '0'),
                  ),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'جزئیات این مرحله',
                      hintText: 'مثلاً چه چیزی را جدا کردم / قانون من چیست',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (v) => _save(ref, noteKey, v.trim()),
                    onEditingComplete: () =>
                        _save(ref, noteKey, noteCtrl.text.trim()),
                  ),
                ],
              ),
            ),
          );
        }),
        TextField(
          controller: TextEditingController(text: notes['fiveS_area'] ?? ''),
          decoration: const InputDecoration(
            labelText: 'محدوده امروز (میز / اتاق / گوشی / کیف…)',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onSubmitted: (v) => _save(ref, 'fiveS_area', v.trim()),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('وضعیت ۵S ذخیره شد — Enter روی فیلدها هم ذخیره می‌کند'),
              behavior: SnackBarBehavior.fixed,
            ));
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('ثبت وضعیت امروز'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}


// ─── Ikigai ─────────────────────────────────────────────
class IkigaiBody extends ConsumerWidget {
  const IkigaiBody({super.key});

  static const fields = [
    ('ikigai_love', 'علاقه', 'چه کاری را حتی بدون پول دوست داری انجام دهی؟', Icons.favorite_outline),
    ('ikigai_good', 'مهارت', 'در چه چیزی نسبت به اطرافیانت بهتر هستی؟', Icons.star_outline),
    ('ikigai_paid', 'درآمد', 'بابت چه مهارتی می‌توانی درآمد بگیری؟', Icons.payments_outlined),
    ('ikigai_world', 'نیاز دنیا', 'جامعه یا اطرافیانت به چه چیزی از تو نیاز دارند؟', Icons.public_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.spa_outlined,
          title: 'نقشه ایکیگای تو',
          subtitle: 'هر چهار باکس را پر کن؛ بعد نقطه تلاقی را بنویس',
        ),
        const _Tip(
          'لازم نیست فوری شغل عوض کنی. هدف پیدا کردن جهت آزمایشی است. برای هر باکس مثال واقعی از زندگی خودت بنویس.',
        ),
        ...fields.map((f) {
          final ctrl = TextEditingController(text: _note(ref, f.$1));
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(f.$4, size: 18, color: AppColors.brand3),
                      const SizedBox(width: 6),
                      Text(f.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: f.$3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (v) => _save(ref, f.$1, v.trim()),
                    onEditingComplete: () =>
                        _save(ref, f.$1, ctrl.text.trim()),
                  ),
                ],
              ),
            ),
          );
        }),
        TextField(
          controller:
              TextEditingController(text: _note(ref, 'ikigai_overlap')),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'نقطه تلاقی (ایکیگای من)',
            hintText: 'از هم‌پوشانی چهار باکس چه مسیری می‌بینی؟',
            prefixIcon: Icon(Icons.auto_awesome),
          ),
          onSubmitted: (v) => _save(ref, 'ikigai_overlap', v.trim()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller:
              TextEditingController(text: _note(ref, 'ikigai_experiment')),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'آزمایش کوچک این ماه',
            hintText: 'مثلاً: هفته‌ای ۳ ساعت روی X کار می‌کنم',
          ),
          onSubmitted: (v) => _save(ref, 'ikigai_experiment', v.trim()),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('برای ذخیره هر فیلد Enter بزن یا از صفحه خارج شو بعد از ویرایش'),
              behavior: SnackBarBehavior.fixed,
            ));
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('تأیید نقشه ایکیگای'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}

// ─── Gratitude ──────────────────────────────────────────
class GratitudeBody extends ConsumerWidget {
  const GratitudeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = DateTime.now();
    final day =
        '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    final keys = ['grat_1_$day', 'grat_2_$day', 'grat_3_$day'];
    final labels = [
      'یک نفر یا رابطه',
      'یک اتفاق یا فرصت',
      'یک چیز کوچک روزمره',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.favorite_rounded,
          title: 'شکرگزاری امروز',
          subtitle: 'سه نعمت — حتی کوچک — ذهن را متعادل می‌کند',
        ),
        ...List.generate(3, (i) {
          final ctrl = TextEditingController(text: _note(ref, keys[i]));
          return _ProcessCard(
            step: '${i + 1}',
            title: labels[i],
            accent: const Color(0xFFEC4899),
            child: TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'مثلاً…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) => _save(ref, keys[i], v.trim()),
            ),
          );
        }),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Enter روی هر فیلد = ذخیره'),
              behavior: SnackBarBehavior.fixed,
            ));
          },
          icon: const Icon(Icons.favorite_border),
          label: const Text('ثبت سه نعمت'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}

// ─── Two minute ─────────────────────────────────────────
class TwoMinBody extends ConsumerWidget {
  const TwoMinBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = _note(ref, 'twomin_log');
    final lines = log.split('\n').where((e) => e.trim().isNotEmpty).toList();
    final ctrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.bolt_rounded,
          title: 'قانون ۲ دقیقه',
          subtitle: 'کارهای کوچک از صبح تا شب · با ساعت شمسی',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'کار زیر ۲ دقیقه…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) async {
                  final t = ctrl.text.trim();
                  if (t.isEmpty) return;
                  final stamp = Jalali.nowString(withMonthName: true);
                  final next = ['$stamp | $t', ...lines].take(50).join('\n');
                  await _save(ref, 'twomin_log', next);
                  ctrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final t = ctrl.text.trim();
                if (t.isEmpty) return;
                final stamp = Jalali.nowString(withMonthName: true);
                final next = ['$stamp | $t', ...lines].take(50).join('\n');
                await _save(ref, 'twomin_log', next);
                ctrl.clear();
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('پیشرفت امروز: ${lines.length} کار کوچک',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (lines.length / 15).clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        ...lines.take(20).map((l) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, size: 18),
              title: Text(l, style: const TextStyle(fontSize: 13, height: 1.3)),
            )),
      ],
    );
  }
}


// ─── SMART ──────────────────────────────────────────────
class SmartBody extends ConsumerWidget {
  const SmartBody({super.key});

  static const letters = [
    ('s', 'Specific — مشخص', 'هدف دقیق چیست؟'),
    ('m', 'Measurable — قابل اندازه‌گیری', 'با چه عددی؟'),
    ('a', 'Achievable — دست‌یافتنی', 'چطور واقع‌بینانه است؟'),
    ('r', 'Relevant — مرتبط', 'چرا مهم است؟'),
    ('t', 'Time-bound — زمان‌دار', 'مهلت چیست؟'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.track_changes,
          title: 'هدف SMART (چند موردی)',
          subtitle: 'در هر حرف می‌توانی چند خط بنویسی — شمارنده خودکار',
        ),
        ...letters.map((f) {
          final key = 'smart_multi_${f.$1}';
          final raw = _note(ref, key);
          final lines = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
          final ctrl = TextEditingController(text: raw);
          return _ProcessCard(
            step: f.$1.toUpperCase(),
            title: '${f.$2}  (${lines.length})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: ctrl,
                  minLines: 2,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '${f.$3}\nهر خط = یک مورد',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () => _save(ref, key, ctrl.text.trim()),
                    child: Text('ذخیره ${f.$1.toUpperCase()} (${lines.length} مورد)'),
                  ),
                ),
              ],
            ),
          );
        }),
        _ProcessCard(
          step: '✓',
          title: 'جمله نهایی هدف',
          child: Builder(builder: (context) {
            final ctrl = TextEditingController(text: _note(ref, 'smart_final'));
            return Column(
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'همه حروف را در یک جمله جمع کن',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () => _save(ref, 'smart_final', ctrl.text.trim()),
                  child: const Text('ذخیره جمله نهایی'),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}


// ─── Time block ─────────────────────────────────────────
// ─── Time block ─────────────────────────────────────────
class TimeblockBody extends ConsumerWidget {
  const TimeblockBody({super.key});

  static const presets = [
    'خواب', 'غذا', 'ورزش', 'کار', 'مطالعه', 'استراحت', 'خانواده', 'عبادت', 'خالی'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(planningProvider).programNotes;
    final hourMap = <int, String>{};
    for (var h = 0; h < 24; h++) {
      final v = notes['tb_h_$h'];
      if (v != null && v.isNotEmpty && v != 'خالی') hourMap[h] = v;
    }
    final filled = hourMap.length;
    final workH = hourMap.values.where((v) => v == 'کار' || v == 'مطالعه').length;
    final sleepH = hourMap.values.where((v) => v == 'خواب').length;

    Future<void> pickHour(int h) async {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('ساعت ${h.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              ...presets.map((p) => ListTile(
                    title: Text(p),
                    onTap: () => Navigator.pop(ctx, p),
                  )),
            ],
          ),
        ),
      );
      if (choice != null) {
        await _save(ref, 'tb_h_$h', choice == 'خالی' ? '' : choice);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.schedule_rounded,
          title: 'تایم‌بلاکینگ ۲۴ ساعته',
          subtitle: 'پیش‌فرض‌ها را انتخاب کن · نمودار و نتیجه‌گیری خودکار',
        ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.brand3.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            filled == 0
                ? 'هنوز بازه‌ای انتخاب نشده — روی هر ساعت بزن.'
                : 'نتیجه: ${filled} ساعت برنامه‌ریزی‌شده · خواب ≈ ${sleepH}س · کار/مطالعه ≈ ${workH}س · '
                    '${filled >= 16 ? "پوشش خوب روز" : "هنوز جا برای تکمیل برنامه هست"}.',
            style: const TextStyle(height: 1.45, fontSize: 13),
          ),
        ),
        // خلاصه توزیع
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets.where((p) => p != 'خالی').map((p) {
            final n = hourMap.values.where((v) => v == p).length;
            if (n == 0) return const SizedBox.shrink();
            return Chip(
              label: Text('$p: $nس', style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        DayTimelineShamsi(
          hourLabels: hourMap,
          onHourTap: pickHour,
        ),
      ],
    );
  }
}


// ─── PDCA ───────────────────────────────────────────────
class PdcaBody extends ConsumerWidget {
  const PdcaBody({super.key});

  static const phases = [
    (
      'pdca_p',
      'Plan — طرح',
      'هدف این دور چیست؟ معیار موفقیت چیست؟',
      Icons.map_outlined,
    ),
    (
      'pdca_d',
      'Do — اجرا',
      'چه کارهایی انجام دادی؟ چه مدت؟',
      Icons.play_circle_outline,
    ),
    (
      'pdca_c',
      'Check — بررسی',
      'نتیجه چه بود؟ با هدف چقدر فاصله داشت؟',
      Icons.fact_check_outlined,
    ),
    (
      'pdca_a',
      'Act — اصلاح',
      'برای دور بعد چه چیزی را عوض می‌کنی؟',
      Icons.autorenew_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.loop_rounded,
          title: 'چرخه PDCA این هفته',
          subtitle: 'یک موضوع مشخص انتخاب کن و هر چهار فاز را پر کن',
        ),
        const _Tip(
          'مثال موضوع: نظم خواب، کاهش هزینه غذا، مطالعه زبان، نظم میز کار. اول Plan را کامل بنویس بعد اجرا کن.',
        ),
        TextField(
          controller: TextEditingController(text: _note(ref, 'pdca_topic')),
          decoration: const InputDecoration(
            labelText: 'موضوع این چرخه',
            hintText: 'مثلاً: خواب منظم قبل از ۱۲',
            prefixIcon: Icon(Icons.flag_outlined),
          ),
          onSubmitted: (v) => _save(ref, 'pdca_topic', v.trim()),
        ),
        const SizedBox(height: 10),
        ...phases.map((f) {
          final ctrl = TextEditingController(text: _note(ref, f.$1));
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(f.$4, color: AppColors.brand3, size: 20),
                      const SizedBox(width: 8),
                      Text(f.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: f.$3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (v) => _save(ref, f.$1, v.trim()),
                    onEditingComplete: () =>
                        _save(ref, f.$1, ctrl.text.trim()),
                  ),
                ],
              ),
            ),
          );
        }),
        TextField(
          controller: TextEditingController(text: _note(ref, 'pdca_next')),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'شروع چرخه بعد (تاریخ/یادداشت)',
            hintText: 'مثلاً از شنبه دوباره با Plan جدید',
          ),
          onSubmitted: (v) => _save(ref, 'pdca_next', v.trim()),
        ),
      ],
    );
  }
}

// ─── Deep work ──────────────────────────────────────────
class DeepWorkBody extends ConsumerWidget {
  const DeepWorkBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = TextEditingController(text: _note(ref, 'dw_topic'));
    final mins = TextEditingController(text: _note(ref, 'dw_mins'));
    final prep = TextEditingController(text: _note(ref, 'dw_prep'));
    final out = TextEditingController(text: _note(ref, 'dw_output'));
    final historyRaw = _note(ref, 'dw_history');
    final history = historyRaw
        .split('\n---\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    Future<void> registerBlock() async {
      final t = topic.text.trim();
      final m = mins.text.trim();
      final p = prep.text.trim();
      final o = out.text.trim();
      await _save(ref, 'dw_topic', t);
      await _save(ref, 'dw_mins', m);
      await _save(ref, 'dw_prep', p);
      await _save(ref, 'dw_output', o);
      await _save(ref, 'dw_done', '1');
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final entry =
          '$stamp | $t | ${m.isEmpty ? "?" : m}دقیقه | خروجی: ${o.isEmpty ? "—" : o}';
      final next = [entry, ...history].take(20).join('\n---\n');
      await _save(ref, 'dw_history', next);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بلوک کار عمیق ثبت شد')),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.psychology_outlined,
          title: 'بلوک کار عمیق',
          subtitle: 'موضوع · آماده‌سازی · مدت · خروجی · ثبت در تاریخچه هفته',
        ),
        _ProcessCard(
          step: '۱',
          title: 'موضوع واحد',
          child: TextField(
            controller: topic,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'فقط یک موضوع — نه چند کار همزمان',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ProcessCard(
          step: '۲',
          title: 'آماده‌سازی محیط',
          child: TextField(
            controller: prep,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'گوشی سکوت · اعلان‌ها بسته · مکان آرام',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ProcessCard(
          step: '۳',
          title: 'مدت بلوک (دقیقه)',
          child: TextField(
            controller: mins,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '۴۵ تا ۹۰ پیشنهاد می‌شود',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ProcessCard(
          step: '۴',
          title: 'خروجی جلسه',
          child: TextField(
            controller: out,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'چه چیزی تولید شد؟',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: registerBlock,
          icon: const Icon(Icons.check_rounded),
          label: const Text('ثبت بلوک'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
        const SizedBox(height: 16),
        Text(
          'تاریخچه بلوک‌ها',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Text(
            'هنوز بلوکی ثبت نشده',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
          )
        else
          ...history.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brand3.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.brand3.withOpacity(0.15)),
                ),
                child: Text(e, style: const TextStyle(height: 1.4, fontSize: 13)),
              )),
      ],
    );
  }
}

// ─── Hoshin ─────────────────────────────────────────────
class HoshinBody extends ConsumerWidget {
  const HoshinBody({super.key});

  static const layers = [
    ('hoshin_year', 'سال', 'هدف بزرگ امسال در یک جمله', Icons.flag_rounded, Color(0xFF6366F1)),
    ('hoshin_season', 'فصل', '۳ ماه آینده روی چه تمرکز می‌کنی؟', Icons.calendar_month_outlined, Color(0xFF8B5CF6)),
    ('hoshin_month', 'ماه', 'این ماه چه نتیجه قابل اندازه‌گیری؟', Icons.date_range_outlined, Color(0xFFA855F7)),
    ('hoshin_week', 'هفته', 'این هفته ۲–۳ کار هم‌راستا با هدف ماه', Icons.view_week_outlined, Color(0xFFEC4899)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.account_tree_outlined,
          title: 'هم‌راستاسازی هوشین',
          subtitle: 'از سال تا هفته — هر لایه باید لایه بالاتر را پشتیبانی کند',
        ),
        const _Tip(
          'اگر کار این هفته به هدف سال وصل نیست، اولویت را عوض کن. بعد از پر کردن لایه‌ها، یک کار امروز بنویس.',
        ),
        ...List.generate(layers.length, (i) {
          final f = layers[i];
          final ctrl = TextEditingController(text: _note(ref, f.$1));
          return _ProcessCard(
            step: '${i + 1}',
            title: 'لایه ${f.$2}',
            accent: f.$5,
            child: TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: f.$3,
                prefixIcon: Icon(f.$4, color: f.$5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (v) => _save(ref, f.$1, v.trim()),
              onEditingComplete: () => _save(ref, f.$1, ctrl.text.trim()),
            ),
          );
        }),
        _ProcessCard(
          step: '۵',
          title: 'اقدام امروز (هم‌راستا)',
          child: TextField(
            controller:
                TextEditingController(text: _note(ref, 'hoshin_today')),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'امروز دقیقاً چه کاری برای هدف هفته می‌کنم؟',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => _save(ref, 'hoshin_today', v.trim()),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('لایه‌ها با Enter ذخیره می‌شوند'),
              behavior: SnackBarBehavior.fixed,
            ));
          },
          icon: const Icon(Icons.link),
          label: const Text('تأیید هم‌راستایی'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}

// ─── Checklist journal ──────────────────────────────────

// ─── Kaizen ─────────────────────────────────────────────
class KaizenBody extends ConsumerWidget {
  const KaizenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = DateTime.now();
    final dayKey = dateKey(n);
    final notes = ref.watch(planningProvider).programNotes;
    // scores: days with action filled => 1
    final scores = <String, int>{};
    for (final e in notes.entries) {
      if (e.key.startsWith('kaizen_action_') && e.value.trim().isNotEmpty) {
        scores[e.key.replaceFirst('kaizen_action_', '')] = 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.trending_up_rounded,
          title: 'کایزن ۳۰ روزه',
          subtitle: 'بهبود ۱٪ روزانه · جدول ماه · نمودار پیشرفت',
        ),
        MonthStripShamsi(anchor: n, scores: scores, days: 30),
        const SizedBox(height: 8),
        Text(
          'روزهای ثبت‌شده: ${scores.length} از ۳۰',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (scores.length / 30).clamp(0.0, 1.0),
          minHeight: 10,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: _note(ref, 'kaizen_action_$dayKey')),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'بهبود ۱٪ امروز',
            hintText: 'یک اقدام خیلی کوچک و مشخص',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => _save(ref, 'kaizen_action_$dayKey', v.trim()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _note(ref, 'kaizen_learn_$dayKey')),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'چه یاد گرفتم؟',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => _save(ref, 'kaizen_learn_$dayKey', v.trim()),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _note(ref, 'kaizen_tomorrow_$dayKey')),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'گام فردا',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => _save(ref, 'kaizen_tomorrow_$dayKey', v.trim()),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('با Enter روی هر فیلد ذخیره می‌شود'),
            ));
          },
          icon: const Icon(Icons.check),
          label: const Text('ثبت بهبود امروز'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand3),
        ),
      ],
    );
  }
}


class ChecklistJournalBody extends ConsumerWidget {
  final String programId;
  final String title;
  final List<String> prompts;
  const ChecklistJournalBody({
    super.key,
    required this.programId,
    required this.title,
    required this.prompts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.edit_note_rounded,
          title: title,
          subtitle: 'گام‌به‌گام پاسخ بده — هر فیلد یک مرحله',
        ),
        ...List.generate(prompts.length, (i) {
          final key = '${programId}_p$i';
          final ctrl = TextEditingController(text: _note(ref, key));
          return _ProcessCard(
            step: '${i + 1}',
            title: prompts[i],
            child: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'پاسخ…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) => _save(ref, key, v.trim()),
            ),
          );
        }),
      ],
    );
  }
}

class GenericRichBody extends ConsumerWidget {
  final String programId;
  const GenericRichBody({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = programGuides[programId] ?? '';
    final ctrl = TextEditingController(
        text: _note(ref, '${programId}_journal'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (guide.isNotEmpty) ...[
          _Tip(guide),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'یادداشت امروز',
          ),
          onSubmitted: (v) => _save(ref, '${programId}_journal', v),
        ),
        TextButton(
          onPressed: () =>
              _save(ref, '${programId}_journal', ctrl.text.trim()),
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}



class _ProcessCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;
  final Color? accent;

  const _ProcessCard({
    required this.step,
    required this.title,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = accent ?? AppColors.brand3;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.withOpacity(0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: c,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand3.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brand3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.brand3.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand3.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 18, color: AppColors.brand3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.45, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/growth/growth_enums.dart';
import '../../providers/growth_provider.dart';

Future<void> showCreateJourneySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CreateJourneySheet(),
  );
}

class _CreateJourneySheet extends ConsumerStatefulWidget {
  const _CreateJourneySheet();

  @override
  ConsumerState<_CreateJourneySheet> createState() =>
      _CreateJourneySheetState();
}

class _CreateJourneySheetState extends ConsumerState<_CreateJourneySheet> {
  final _title = TextEditingController();
  final _reason = TextEditingController();
  final _criteria = TextEditingController();
  bool _startActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    _criteria.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان مسیر لازم است')),
      );
      return;
    }
    setState(() => _saving = true);
    final n = ref.read(growthProvider.notifier);
    final activeBefore = ref.read(growthProvider).activeJourneys.length;
    final j = await n.createJourney(
      title: t,
      reason: _reason.text,
      successCriteria: _criteria.text,
      startActive: _startActive,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    if (_startActive &&
        activeBefore >= GrowthNotifier.maxSoftActive &&
        j.status != JourneyStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مسیر به‌صورت پیش‌نویس ذخیره شد تا تعداد فعال‌ها زیاد نشود. هر وقت خواستی فعالش کن.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مسیر ساخته شد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مسیر جدید',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هدف کوچک و روشن بهتر از هدف مبهم بزرگ است.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'عنوان مسیر *',
                hintText: 'مثلاً تمرکز بهتر هنگام کار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'چرا این مسیر؟',
                hintText: 'دلیل شخصی‌ات',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _criteria,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'معیار موفقیت (ساده)',
                hintText: 'مثلاً ۳ روز در هفته جلسه تمرکز',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('همین حالا فعال شود'),
              subtitle: Text(
                'اگر مسیر فعال زیاد باشد، به‌صورت پیش‌نویس ذخیره می‌شود',
                style: theme.textTheme.bodySmall,
              ),
              value: _startActive,
              activeColor: AppColors.brand3,
              onChanged: (v) => setState(() => _startActive = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand3,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ساخت مسیر'),
            ),
          ],
        ),
      ),
    );
  }
}


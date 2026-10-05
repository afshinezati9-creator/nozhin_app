import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/jalali.dart';
import '../../core/utils/money_format.dart';

/// انتخابگر تاریخ هجری شمسی (نه میلادی، نه قمری)
Future<DateTime?> showShamsiDatePicker(
  BuildContext context, {
  DateTime? initial,
}) async {
  final init = initial ?? DateTime.now();
  var j = Jalali.fromDateTime(init);

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSt) {
          final daysInMonth = j.monthLength;
          if (j.day > daysInMonth) {
            j = Jalali(j.year, j.month, daysInMonth);
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تاریخ شمسی',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  j.format(withMonthName: true),
                  style: TextStyle(
                    color: AppColors.brand3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: j.day,
                        decoration: const InputDecoration(
                          labelText: 'روز',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (var d = 1; d <= daysInMonth; d++)
                            DropdownMenuItem(
                              value: d,
                              child: Text(MoneyFormat.toPersianDigits('$d')),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setSt(() => j = Jalali(j.year, j.month, v));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: j.month,
                        decoration: const InputDecoration(
                          labelText: 'ماه',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(Jalali.months[m - 1]),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setSt(() {
                            final len = Jalali(j.year, v, 1).monthLength;
                            final day = j.day > len ? len : j.day;
                            j = Jalali(j.year, v, day);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: j.year,
                        decoration: const InputDecoration(
                          labelText: 'سال',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (var y = j.year - 5; y <= j.year + 8; y++)
                            DropdownMenuItem(
                              value: y,
                              child: Text(MoneyFormat.toPersianDigits('$y')),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setSt(() {
                            final len = Jalali(v, j.month, 1).monthLength;
                            final day = j.day > len ? len : j.day;
                            j = Jalali(v, j.month, day);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, j.toDateTime()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand3,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('تأیید'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

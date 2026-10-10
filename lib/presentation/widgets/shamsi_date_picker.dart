import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/jalali.dart';
import '../../core/utils/money_format.dart';

/// انتخابگر تاریخ هجری شمسی — بدون overflow، فشرده و واضح
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
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (ctx, setSt) {
          final daysInMonth = j.monthLength;
          if (j.day > daysInMonth) {
            j = Jalali(j.year, j.month, daysInMonth);
          }

          Widget field({
            required String label,
            required Widget child,
          }) {
            return Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(child: child),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'تاریخ شمسی',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  j.format(withMonthName: true),
                  style: const TextStyle(
                    color: AppColors.brand3,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                // ارتفاع ثابت تا overflow ندهد
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      field(
                        label: 'روز',
                        child: DropdownButton<int>(
                          value: j.day,
                          isExpanded: true,
                          isDense: true,
                          items: [
                            for (var d = 1; d <= daysInMonth; d++)
                              DropdownMenuItem(
                                value: d,
                                child: Text(
                                  MoneyFormat.toPersianDigits('$d'),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setSt(() => j = Jalali(j.year, j.month, v));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      field(
                        label: 'ماه',
                        child: DropdownButton<int>(
                          value: j.month,
                          isExpanded: true,
                          isDense: true,
                          items: [
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(
                                  Jalali.months[m - 1],
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                      field(
                        label: 'سال',
                        child: DropdownButton<int>(
                          value: j.year,
                          isExpanded: true,
                          isDense: true,
                          items: [
                            for (var y = j.year - 8; y <= j.year + 10; y++)
                              DropdownMenuItem(
                                value: y,
                                child: Text(
                                  MoneyFormat.toPersianDigits('$y'),
                                  style: const TextStyle(fontSize: 14),
                                ),
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
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, j.toDateTime()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تأیید',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

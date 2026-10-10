import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// دیالوگ اکسل — نوشتن در سلول + فرمول + تغییر اندازه
class TableInsertDialog extends StatefulWidget {
  final int initialRows;
  final int initialCols;
  final bool excelStyle;
  final Map<String, dynamic>? initialData;

  const TableInsertDialog({
    super.key,
    this.initialRows = 5,
    this.initialCols = 4,
    this.excelStyle = true,
    this.initialData,
  });

  @override
  State<TableInsertDialog> createState() => _TableInsertDialogState();
}

class _TableInsertDialogState extends State<TableInsertDialog> {
  late int rows;
  late int cols;
  late List<List<TextEditingController>> cells;
  double _colWidth = 100;
  int? _focusR;
  int? _focusC;
  bool _headerRow = true;
  bool _altRows = true;
  bool _showGrid = true;
  int _maxRows = 30;
  int _maxCols = 12;

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    if (init != null) {
      rows = (init['rows'] as num?)?.toInt() ?? widget.initialRows;
      cols = (init['cols'] as num?)?.toInt() ?? widget.initialCols;
      _colWidth = (init['colWidth'] as num?)?.toDouble() ?? 100;
      final data = (init['data'] as List?)
              ?.map((r) => (r as List).map((c) => '$c').toList())
              .toList() ??
          [];
      cells = List.generate(rows, (r) {
        return List.generate(cols, (c) {
          final ctrl = TextEditingController();
          if (r < data.length && c < data[r].length) {
            ctrl.text = data[r][c];
          }
          return ctrl;
        });
      });
    } else {
      rows = widget.initialRows;
      cols = widget.initialCols;
      _rebuild(keepData: false);
    }
  }

  void _rebuild({bool keepData = true}) {
    final old = keepData
        ? cells.map((r) => r.map((c) => c.text).toList()).toList()
        : <List<String>>[];

    if (keepData) {
      for (final row in cells) {
        for (final c in row) {
          c.dispose();
        }
      }
    }

    cells = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final ctrl = TextEditingController();
        if (keepData && r < old.length && c < old[r].length) {
          ctrl.text = old[r][c];
        } else if (r == 0) {
          ctrl.text = String.fromCharCode(65 + c); // A B C
        } else if (c == 0) {
          ctrl.text = '$r';
        }
        return ctrl;
      });
    });
  }

  @override
  void dispose() {
    for (final row in cells) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Map<String, dynamic> toData() {
    return {
      'rows': rows,
      'cols': cols,
      'excel': true,
      'colWidth': _colWidth,
      'headerRow': _headerRow,
      'altRows': _altRows,
      'showGrid': _showGrid,
      'data': cells.map((row) => row.map((c) => c.text).toList()).toList(),
    };
  }

  /// جمع‌آوری اعداد از سلول‌ها (بدون فرمول‌ها)
  List<double> _allNumbers({int? excludeR, int? excludeC}) {
    final nums = <double>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (r == excludeR && c == excludeC) continue;
        final t = cells[r][c].text.trim();
        if (t.startsWith('=')) continue;
        final n = double.tryParse(t.replaceAll(',', ''));
        if (n != null) nums.add(n);
      }
    }
    return nums;
  }

  /// اعداد یک ستون (بدون ردیف هدر)
  List<double> _colNumbers(int col) {
    final nums = <double>[];
    for (var r = 1; r < rows; r++) {
      final t = cells[r][col].text.trim();
      if (t.startsWith('=')) continue;
      final n = double.tryParse(t.replaceAll(',', ''));
      if (n != null) nums.add(n);
    }
    return nums;
  }

  void _insertFormula(String kind) {
    if (_focusR == null || _focusC == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اول روی یک سلول کلیک کن، بعد فرمول را بزن'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final r = _focusR!;
    final c = _focusC!;
    // فرمول خام برای ذخیره
    cells[r][c].text = '=$kind';
    setState(() {});
  }

  void _computeAllFormulas() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final t = cells[r][c].text.trim();
        if (!t.startsWith('=')) continue;
        final kind = t.substring(1).toUpperCase().replaceAll('()', '');
        final nums = _colNumbers(c).isNotEmpty ? _colNumbers(c) : _allNumbers(excludeR: r, excludeC: c);
        String result;
        if (nums.isEmpty) {
          result = '0';
        } else if (kind == 'SUM' || kind == 'SUM()') {
          result = nums.fold<double>(0, (a, b) => a + b).toString();
        } else if (kind == 'AVERAGE' || kind == 'AVG' || kind == 'AVERAGE()') {
          result = (nums.fold<double>(0, (a, b) => a + b) / nums.length)
              .toStringAsFixed(2);
        } else if (kind == 'MIN' || kind == 'MIN()') {
          result = nums.reduce((a, b) => a < b ? a : b).toString();
        } else if (kind == 'MAX' || kind == 'MAX()') {
          result = nums.reduce((a, b) => a > b ? a : b).toString();
        } else if (kind == 'COUNT' || kind == 'COUNT()') {
          result = nums.length.toString();
        } else {
          // حساب ساده مثل =10+5
          final expr = t.substring(1);
          final simple = RegExp(r'^(\d+\.?\d*)\s*([+\-*/])\s*(\d+\.?\d*)$')
              .firstMatch(expr);
          if (simple != null) {
            final a = double.parse(simple.group(1)!);
            final op = simple.group(2)!;
            final b = double.parse(simple.group(3)!);
            double v;
            switch (op) {
              case '+':
                v = a + b;
                break;
              case '-':
                v = a - b;
                break;
              case '*':
                v = a * b;
                break;
              default:
                v = b != 0 ? a / b : 0;
            }
            result = v.toString();
          } else {
            continue;
          }
        }
        // نگه داشتن فرمول در tooltip-like: ذخیره نتیجه با یادداشت فرمول
        cells[r][c].text = result;
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فرمول‌ها محاسبه شدند'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

            // تنظیمات بیشتر اکسل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تنظیمات جدول',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('ردیف عنوان'),
                        selected: _headerRow,
                        onSelected: (v) => setState(() => _headerRow = v),
                      ),
                      FilterChip(
                        label: const Text('ردیف راه‌راه'),
                        selected: _altRows,
                        onSelected: (v) => setState(() => _altRows = v),
                      ),
                      FilterChip(
                        label: const Text('نمایش خطوط'),
                        selected: _showGrid,
                        onSelected: (v) => setState(() => _showGrid = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('عرض ستون: ${_colWidth.round()}',
                      style: theme.textTheme.labelSmall),
                  Slider(
                    value: _colWidth.clamp(60, 180),
                    min: 60,
                    max: 180,
                    divisions: 12,
                    label: '${_colWidth.round()}',
                    onChanged: (v) => setState(() => _colWidth = v),
                  ),
                  Row(
                    children: [
                      Text('سطر ${rows}', style: theme.textTheme.labelMedium),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: rows > 2
                            ? () => setState(() {
                                  rows--;
                                  _rebuild(keepData: true);
                                })
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: rows < _maxRows
                            ? () => setState(() {
                                  rows++;
                                  _rebuild(keepData: true);
                                })
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text('ستون ${cols}', style: theme.textTheme.labelMedium),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: cols > 2
                            ? () => setState(() {
                                  cols--;
                                  _rebuild(keepData: true);
                                })
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: cols < _maxCols
                            ? () => setState(() {
                                  cols++;
                                  _rebuild(keepData: true);
                                })
                            : null,
                      ),
                    ],
                  ),
                  Text(
                    'فرمول: روی سلول کلیک کن، SUM/AVG/MIN/MAX بزن، بعد «محاسبه». یا بنویس =10+5',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grid_on_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialData != null
                              ? 'ویرایش جدول اکسل'
                              : 'جدول اکسل',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'محتوا را فقط داخل همین جدول بنویس',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // راهنما
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brand3.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brand3.withOpacity(0.2)),
                ),
                child: Text(
                  '۱) روی سلول کلیک کن و بنویس\n'
                  '۲) برای فرمول: سلول را انتخاب کن → SUM / AVG / ...\n'
                  '۳) «محاسبه فرمول‌ها» را بزن تا نتیجه جای فرمول بنشیند\n'
                  '۴) عرض و تعداد سطر/ستون را از پایین تنظیم کن',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 10),

              // تب‌های فرمول — اسکرول افقی؛ «نتیجه محاسبه» اول
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: FilledButton.icon(
                        onPressed: _computeAllFormulas,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand3,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.calculate_rounded, size: 16),
                        label: const Text('نتیجه محاسبه',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final f in [
                      ('SUM', 'جمع'),
                      ('AVERAGE', 'میانگین'),
                      ('MIN', 'کمینه'),
                      ('MAX', 'بیشینه'),
                      ('COUNT', 'تعداد'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ActionChip(
                          avatar: const Icon(Icons.functions_rounded, size: 14),
                          label: Text('${f.$1} · ${f.$2}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () => _insertFormula(f.$1),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // کنترل اندازه
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SizeChip(
                            label: 'سطر',
                            value: rows,
                            onMinus: () {
                              if (rows > 2) {
                                setState(() {
                                  rows--;
                                  _rebuild(keepData: true);
                                });
                              }
                            },
                            onPlus: () {
                              if (rows < 20) {
                                setState(() {
                                  rows++;
                                  _rebuild(keepData: true);
                                });
                              }
                            }),
                        const SizedBox(width: 8),
                        _SizeChip(
                            label: 'ستون',
                            value: cols,
                            onMinus: () {
                              if (cols > 2) {
                                setState(() {
                                  cols--;
                                  _rebuild(keepData: true);
                                });
                              }
                            },
                            onPlus: () {
                              if (cols < 12) {
                                setState(() {
                                  cols++;
                                  _rebuild(keepData: true);
                                });
                              }
                            }),
                        const Spacer(),
                        Text('${rows}×$cols',
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.brand3)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('عرض', style: theme.textTheme.labelSmall),
                        Expanded(
                          child: Slider(
                            value: _colWidth,
                            min: 64,
                            max: 160,
                            divisions: 12,
                            activeColor: AppColors.brand3,
                            onChanged: (v) => setState(() => _colWidth = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // جدول
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(48),
                    minScale: 0.6,
                    maxScale: 2.5,
                    child: Table(
                      border: TableBorder.all(
                          color: theme.colorScheme.outline, width: 1),
                      defaultColumnWidth: FixedColumnWidth(_colWidth),
                      children: List.generate(rows, (r) {
                        final isHeader = r == 0;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: isHeader
                                ? AppColors.brand3.withOpacity(0.15)
                                : (_focusR == r
                                    ? AppColors.brand3.withOpacity(0.05)
                                    : (r.isEven
                                        ? theme.colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.35)
                                        : theme.colorScheme.surface)),
                          ),
                          children: List.generate(cols, (c) {
                            final focused = _focusR == r && _focusC == c;
                            return Container(
                              decoration: focused
                                  ? BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.brand3, width: 2),
                                    )
                                  : null,
                              constraints: BoxConstraints(
                                minHeight: isHeader ? 36 : 44,
                                minWidth: _colWidth,
                              ),
                              child: TextField(
                                controller: cells[r][c],
                                maxLines: null,
                                minLines: 1,
                                textAlign: TextAlign.center,
                                onTap: () => setState(() {
                                  _focusR = r;
                                  _focusC = c;
                                }),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isHeader
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('لغو')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, jsonEncode(toData())),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand3,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      widget.initialData != null ? 'ذخیره تغییرات' : 'درج جدول',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _SizeChip({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(' $label ', style: theme.textTheme.labelSmall),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            onPressed: onMinus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Text('$value',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            onPressed: onPlus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

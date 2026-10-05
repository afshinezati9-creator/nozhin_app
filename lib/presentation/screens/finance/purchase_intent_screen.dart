import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/purchase_intent_entity.dart';
import '../../providers/purchase_intent_provider.dart';
import '../../widgets/shamsi_date_picker.dart';

/// قصد خرید — ساده: زمان · عنوان · مبلغ · خریدم/نتوانستم · آرشیو
class PurchaseIntentScreen extends ConsumerWidget {
  const PurchaseIntentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseIntentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قصد خرید'),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(purchaseIntentProvider.notifier)
                  .setShowArchive(!state.showArchive);
            },
            child: Text(state.showArchive ? 'فعال' : 'آرشیو'),
          ),
        ],
      ),
      floatingActionButton: state.showArchive
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              backgroundColor: AppColors.brand3,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('مورد جدید',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!state.showArchive) ...[
                  _TimeTabs(
                    tab: state.tab,
                    onChanged: (t) =>
                        ref.read(purchaseIntentProvider.notifier).setTab(t),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'تعهد باز (تقریبی): ${MoneyFormat.toman(state.openCommitment)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.overdue.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warn.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.overdue.length} مورد عقب‌افتاده (تاریخ گذشته، هنوز نخریدی)',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'آرشیو: خریده‌شده‌ها و مواردی که نتوانستی بخری',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),
                Expanded(
                  child: _ListBody(state: state),
                ),
              ],
            ),
    );
  }

  static Future<void> _openForm(BuildContext context, WidgetRef ref,
      {PurchaseIntentEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormSheet(existing: existing),
    );
  }
}

class _TimeTabs extends StatelessWidget {
  final PurchaseTimeTab tab;
  final ValueChanged<PurchaseTimeTab> onChanged;
  const _TimeTabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      PurchaseTimeTab.today: 'امروز',
      PurchaseTimeTab.week: 'این هفته',
      PurchaseTimeTab.month: 'این ماه',
      PurchaseTimeTab.year: 'امسال',
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: PurchaseTimeTab.values.map((t) {
          final on = tab == t;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(labels[t]!),
              selected: on,
              selectedColor: AppColors.brand3.withOpacity(0.2),
              onSelected: (_) => onChanged(t),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ListBody extends ConsumerWidget {
  final PurchaseIntentState state;
  const _ListBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = state.showArchive
        ? state.items.where((e) => e.archived).toList()
        : [
            ...state.overdue.where((e) =>
                !PurchaseTimeFilter.matches(e.plannedDate, state.tab)),
            ...state.visible,
          ];

    // de-dupe by id while keeping order
    final seen = <String>{};
    final unique = <PurchaseIntentEntity>[];
    for (final e in list) {
      if (seen.add(e.id)) unique.add(e);
    }

    if (unique.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            state.showArchive
                ? 'آرشیو خالی است'
                : 'در این بازه چیزی نیست.\nبا + یک مورد اضافه کن.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: unique.length,
      itemBuilder: (_, i) {
        final item = unique[i];
        return _ItemCard(item: item);
      },
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final PurchaseIntentEntity item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final n = ref.read(purchaseIntentProvider.notifier);
    final overdue = PurchaseTimeFilter.isOverdue(item.plannedDate, item.status);
    final dateLabel =
        Jalali.fromDateTime(item.plannedDate).format(withMonthName: true);

    Color statusColor;
    String statusLabel;
    switch (item.status) {
      case PurchaseIntentStatus.bought:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'خریدم';
      case PurchaseIntentStatus.couldNot:
        statusColor = AppColors.warn;
        statusLabel = 'نتوانستم';
      case PurchaseIntentStatus.pending:
        statusColor = overdue ? const Color(0xFFEF4444) : AppColors.brand3;
        statusLabel = overdue ? 'عقب‌افتاده' : 'در انتظار';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await PurchaseIntentScreen._openForm(context, ref,
                            existing: item);
                      case 'archive':
                        await n.archive(item.id);
                      case 'restore':
                        await n.restore(item.id);
                      case 'delete':
                        await n.delete(item.id);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!item.archived)
                      const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                    if (!item.archived)
                      const PopupMenuItem(
                          value: 'archive', child: Text('آرشیو')),
                    if (item.archived)
                      const PopupMenuItem(
                          value: 'restore', child: Text('بازگردانی')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (item.amount != null)
                  MoneyFormat.toman(item.amount!),
                dateLabel,
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
            if (!item.archived &&
                item.status == PurchaseIntentStatus.pending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => n.markBought(item.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('خریدم'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => n.markCouldNot(item.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('نتوانستم'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormSheet extends ConsumerStatefulWidget {
  final PurchaseIntentEntity? existing;
  const _FormSheet({this.existing});

  @override
  ConsumerState<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends ConsumerState<_FormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(
      text: e?.amount != null ? e!.amount!.toStringAsFixed(0) : '',
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.plannedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showShamsiDatePicker(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  double? get _parsedAmount {
    final raw = _amount.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    return double.tryParse(MoneyFormat.fromPersianDigits(raw));
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان لازم است')),
      );
      return;
    }
    final amount = _parsedAmount;
    setState(() => _saving = true);
    final n = ref.read(purchaseIntentProvider.notifier);
    if (widget.existing != null) {
      await n.update(widget.existing!.copyWith(
        title: title,
        amount: amount,
        clearAmount: amount == null,
        plannedDate: _date,
        note: _note.text.trim(),
      ));
    } else {
      await n.add(
        title: title,
        amount: amount,
        plannedDate: _date,
        note: _note.text.trim(),
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final j = Jalali.fromDateTime(_date);
    final amount = _parsedAmount;

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
            const SizedBox(height: 14),
            Text(
              widget.existing == null ? 'مورد جدید' : 'ویرایش',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'چی می‌خوای بخری؟ *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'مبلغ تقریبی (تومان)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (amount != null && amount > 0) ...[
              const SizedBox(height: 6),
              Text(
                MoneyFormat.toWordsToman(amount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brand3,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تاریخ مدنظر (شمسی)'),
              subtitle: Text(j.format(withMonthName: true)),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'توضیحات (اختیاری)',
                hintText: 'رنگ، سایز، لینک، یادداشت…',
                border: OutlineInputBorder(),
              ),
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}

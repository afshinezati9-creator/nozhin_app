import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/kanban_card_entity.dart';
import '../../providers/planning_provider.dart';

class KanbanWidget extends ConsumerWidget {
  const KanbanWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(planningProvider).kanbanCards;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(builder: (context) {
          final cards = ref.watch(planningProvider).kanbanCards;
          final todo = cards.where((c) => c.column.name == 'todo').length;
          final doing = cards.where((c) => c.column.name == 'doing').length;
          final done = cards.where((c) => c.column.name == 'done').length;
          final tot = cards.isEmpty ? 1 : cards.length;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نمودار جریان', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _KBar(label: 'انجام‌دادنی', v: todo, tot: tot, c: const Color(0xFF64748B)),
                  _KBar(label: 'در حال انجام', v: doing, tot: tot, c: const Color(0xFFF59E0B)),
                  _KBar(label: 'انجام‌شده', v: done, tot: tot, c: const Color(0xFF22C55E)),
                ],
              ),
            ),
          );
        }),

        Row(
          children: [
            Text(
              'تخته کانبان',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _add(context, ref, KanbanColumn.todo),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('کارت'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand3,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Column(
                  title: 'انجام',
                  column: KanbanColumn.todo,
                  color: const Color(0xFF64748B),
                  cards: cards
                      .where((c) => c.column == KanbanColumn.todo)
                      .toList(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Column(
                  title: 'در حال',
                  column: KanbanColumn.doing,
                  color: const Color(0xFF3B82F6),
                  cards: cards
                      .where((c) => c.column == KanbanColumn.doing)
                      .toList(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Column(
                  title: 'شده',
                  column: KanbanColumn.done,
                  color: const Color(0xFF10B981),
                  cards: cards
                      .where((c) => c.column == KanbanColumn.done)
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'جمع: ${MoneyFormat.toPersianDigits('${cards.length}')} کارت',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Future<void> _add(
      BuildContext context, WidgetRef ref, KanbanColumn col) async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var priority = 2;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('کارت جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'عنوان کار',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'جزئیات / معیار انجام',
                    hintText: 'چرا مهم است؟ چطور می‌فهمم تمام شده؟',
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('اولویت',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('کم')),
                    ButtonSegment(value: 2, label: Text('عادی')),
                    ButtonSegment(value: 3, label: Text('بالا')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (s) =>
                      setLocal(() => priority = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لغو')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      await ref.read(planningProvider.notifier).addKanbanCard(
            titleCtrl.text.trim(),
            column: col,
            note: noteCtrl.text.trim(),
            priority: priority,
          );
    }
  }
}

class _Column extends ConsumerWidget {
  final String title;
  final KanbanColumn column;
  final Color color;
  final List<KanbanCardEntity> cards;

  const _Column({
    required this.title,
    required this.column,
    required this.color,
    required this.cards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sorted = List<KanbanCardEntity>.from(cards)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: color, width: 3)),
            ),
            child: Text(
              '$title (${MoneyFormat.toPersianDigits('${cards.length}')})',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Text(
                      '—',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final c = sorted[i];
                      return _CardTile(card: c);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  final KanbanCardEntity card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _menu(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(card.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: const Text('انتقال یا حذف'),
            ),
            if (card.column != KanbanColumn.todo)
              ListTile(
                leading: const Icon(Icons.list_alt_rounded),
                title: const Text('به «انجام»'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(planningProvider.notifier)
                      .moveKanbanCard(card.id, KanbanColumn.todo);
                },
              ),
            if (card.column != KanbanColumn.doing)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('به «در حال»'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(planningProvider.notifier)
                      .moveKanbanCard(card.id, KanbanColumn.doing);
                },
              ),
            if (card.column != KanbanColumn.done)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('به «شده»'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(planningProvider.notifier)
                      .moveKanbanCard(card.id, KanbanColumn.done);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(planningProvider.notifier).deleteKanbanCard(card.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _KBar extends StatelessWidget {
  final String label;
  final int v;
  final int tot;
  final Color c;
  const _KBar({required this.label, required this.v, required this.tot, required this.c});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        Expanded(child: LinearProgressIndicator(value: (v / tot).clamp(0.0, 1.0), minHeight: 8, color: c, backgroundColor: c.withOpacity(0.12))),
        const SizedBox(width: 8),
        Text('$v', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

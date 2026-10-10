import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../domain/entities/note_entity.dart';
import '../../providers/notes_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchCtrl = TextEditingController();
  bool _listView = true; // true=لیست  false=کارتی فشرده
  final _catScrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _catScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEditor(String noteId) async {
    final notes = ref.read(notesProvider).notes;
    NoteEntity? note;
    for (final n in notes) {
      if (n.id == noteId) { note = n; break; }
    }
    if (note == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note!)),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف یادداشت'),
        content: const Text('این یادداشت حذف شود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(notesProvider.notifier).deleteNote(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final theme = Theme.of(context);

    if (state.isLoading && state.notes.isEmpty) {
      return const AppLoading(message: 'در حال بارگذاری...');
    }

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLowest,
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFEEF2FF).withOpacity(0.45),
                  const Color(0xFFF8FAFC),
                ],
          stops: isDark ? null : const [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
      children: [
        // هدر لیست: جستجو + مرتب‌سازی
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(isDark ? 1 : 0.92),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
          ),
          child: Column(
            children: [
              AppSearchBar(
                controller: _searchCtrl,
                hint: 'جستجو در یادداشت‌ها...',
                onChanged: (q) =>
                    ref.read(notesProvider.notifier).setSearch(q),
              ),
              const SizedBox(height: 12),
              // دسته‌بندی‌ها — اسکرول افقی (نوار اسکرول پایین‌تر)
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: Scrollbar(
                        controller: _catScrollCtrl,
                        thumbVisibility: true,
                        thickness: 3,
                        radius: const Radius.circular(4),
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        child: ListView(
                          controller: _catScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 8),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: AppChip(
                                label: 'همه',
                                selected: state.selectedCategory == null,
                                onTap: () => ref
                                    .read(notesProvider.notifier)
                                    .setCategory(null),
                              ),
                            ),
                            ...ref.watch(categoriesProvider).categories.map((c) {
                              final sel = state.selectedCategory == c;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: AppChip(
                                  label: c,
                                  selected: sel,
                                  onTap: () => ref
                                      .read(notesProvider.notifier)
                                      .setCategory(sel ? null : c),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'ایجاد / مدیریت دسته‌بندی',
                      icon: const Icon(Icons.playlist_add_rounded, size: 22),
                      onPressed: () => _manageCategories(context, ref),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_toPersian(state.filtered.length)} یادداشت',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _listView ? 'نمای جدولی/کارتی' : 'نمای لیستی',
                    icon: Icon(
                      _listView
                          ? Icons.grid_view_rounded
                          : Icons.view_agenda_rounded,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _listView = !_listView),
                    visualDensity: VisualDensity.compact,
                  ),
                  PopupMenuButton<NotesSort>(
                    tooltip: 'مرتب‌سازی',
                    icon: Icon(
                      Icons.sort_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                    initialValue: state.sort,
                    onSelected: (s) =>
                        ref.read(notesProvider.notifier).setSort(s),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: NotesSort.newest, child: Text('جدیدترین')),
                      PopupMenuItem(
                          value: NotesSort.oldest, child: Text('قدیمی‌ترین')),
                      PopupMenuItem(
                          value: NotesSort.pinned, child: Text('سنجاق‌شده‌ها اول')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // لیست / کارتی
        Expanded(
          child: state.filtered.isEmpty
              ? AppEmptyState(
                  icon: Icons.note_alt_outlined,
                  message: state.searchQuery.isNotEmpty
                      ? 'نتیجه‌ای پیدا نشد'
                      : 'هنوز یادداشتی نداری\nبا دکمه + یکی بساز',
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(notesProvider.notifier).load(),
                  color: AppColors.brand3,
                  child: _listView
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                          itemCount: state.filtered.length,
                          itemBuilder: (_, i) {
                            final n = state.filtered[i];
                            return NoteCard(
                              note: n,
                              onTap: () => _openEditor(n.id),
                              onPin: () => ref
                                  .read(notesProvider.notifier)
                                  .togglePin(n.id),
                              onDelete: () => _confirmDelete(n.id),
                              onDuplicate: () async {
                                await ref
                                    .read(notesProvider.notifier)
                                    .duplicateNote(n.id);
                              },
                            );
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            // بلندتر تا overflow نشود
                            childAspectRatio: 0.72,
                          ),
                          itemCount: state.filtered.length,
                          itemBuilder: (_, i) {
                            final n = state.filtered[i];
                            return NoteCard(
                              note: n,
                              compact: true,
                              onTap: () => _openEditor(n.id),
                              onPin: () => ref
                                  .read(notesProvider.notifier)
                                  .togglePin(n.id),
                              onDelete: () => _confirmDelete(n.id),
                              onDuplicate: () async {
                                await ref
                                    .read(notesProvider.notifier)
                                    .duplicateNote(n.id);
                              },
                            );
                          },
                        ),
                ),
        ),

      ],
    ),
    );
  }


  Future<void> _manageCategories(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final cats = ref.watch(categoriesProvider).categories;
              final notes = ref.watch(notesProvider).notes;
              final theme = Theme.of(context);
              int countFor(String c) =>
                  notes.where((n) => n.category == c).length;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('دسته‌بندی‌ها',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'روی هر دسته تعداد یادداشت‌ها را می‌بینی. همه دسته‌ها قابل حذف‌اند (حداقل یکی باید بماند). «همه» فیلتر ثابت است و حذف نمی‌شود.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                hintText: 'نام دسته جدید...',
                                isDense: true,
                              ),
                              onSubmitted: (v) async {
                                final ok = await ref
                                    .read(categoriesProvider.notifier)
                                    .add(v);
                                if (ok) ctrl.clear();
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('نام نامعتبر یا تکراری است'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              final ok = await ref
                                  .read(categoriesProvider.notifier)
                                  .add(ctrl.text);
                              if (ok) {
                                ctrl.clear();
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('نام نامعتبر یا تکراری است'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brand3,
                            ),
                            child: const Text('ایجاد'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: cats.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = cats[i];
                            final cnt = countFor(c);
                            return ListTile(
                              dense: true,
                              title: Text(c),
                              subtitle: Text(
                                cnt == 0
                                    ? 'بدون یادداشت'
                                    : '$cnt یادداشت',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                tooltip: cats.length <= 1
                                    ? 'حداقل یک دسته لازم است'
                                    : 'حذف دسته',
                                onPressed: cats.length <= 1
                                    ? null
                                    : () async {
                                        final ok = await ref
                                            .read(categoriesProvider.notifier)
                                            .remove(c);
                                        if (ok) {
                                          final st = ref.read(notesProvider);
                                          if (st.selectedCategory == c) {
                                            ref
                                                .read(notesProvider.notifier)
                                                .setCategory(null);
                                          }
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'حداقل یک دسته‌بندی باید بماند'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _toPersian(int n) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var s = n.toString();
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], fa[i]);
    }
    return s;
  }
}

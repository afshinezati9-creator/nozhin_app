import 'package:flutter/material.dart';
import '../../../core/constants/growth_catalog.dart';
import '../../../core/constants/growth_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/growth_visuals.dart';
import '../../../domain/entities/growth/growth_program_def.dart';
import 'program_learn_flow.dart';

class ProgramLibraryScreen extends StatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  State<ProgramLibraryScreen> createState() => _ProgramLibraryScreenState();
}

class _ProgramLibraryScreenState extends State<ProgramLibraryScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var list = GrowthCatalog.all;
    if (_category != null) {
      list = list.where((p) => p.categoryId == _category).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim();
      list = list
          .where((p) =>
              p.nameFa.contains(q) ||
              p.oneLiner.contains(q) ||
              p.suitableFor.any((s) => s.contains(q)))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text(GrowthStrings.libraryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'جستجوی نام یا موضوع…',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('همه'),
                    selected: _category == null,
                    selectedColor: AppColors.brand3.withOpacity(0.2),
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                ...GrowthCategories.labels.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: _category == e.key,
                      selectedColor: AppColors.brand3.withOpacity(0.2),
                      onSelected: (_) =>
                          setState(() => _category = e.key),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'چیزی پیدا نشد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _LibCard(program: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LibCard extends StatelessWidget {
  final GrowthProgramDef program;
  const _LibCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = GrowthCategories.labels[program.categoryId] ?? '';
    final v = GrowthVisuals.of(program.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: v.accent.withOpacity(0.18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProgramEntryScreen(programId: program.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: v.gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: v.accent.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(v.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.nameFa,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (cat.isNotEmpty)
                          Text(
                            cat,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: v.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(program.oneLiner,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
                    const SizedBox(height: 8),
                    Text(
                      '≈ ${program.approxMinutes} دقیقه · ${program.difficulty}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

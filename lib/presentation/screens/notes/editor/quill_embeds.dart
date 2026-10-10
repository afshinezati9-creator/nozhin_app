import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/theme/app_colors.dart';
import 'table_dialog.dart';

class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'image';

  /// جلوگیری از پر کردن عرض و پرش اسکرول هنگام فوکوس/تایپ
  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final maxW = MediaQuery.sizeOf(context).width - 48;
    Widget image;
    try {
      if (data is String && data.startsWith('data:image')) {
        final b64 = data.split(',').last;
        final bytes = base64Decode(b64);
        image = Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          // کش رزولوشن نمایش — کمتر ری‌بیلد و پرش
          cacheWidth: (maxW * MediaQuery.devicePixelRatioOf(context))
              .round()
              .clamp(200, 1600),
        );
      } else if (data is String &&
          (data.startsWith('http') || data.startsWith('blob:'))) {
        image = Image.network(
          data,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              const _EmbedError(label: 'تصویر بار نشد'),
        );
      } else {
        image = const _EmbedError(label: 'تصویر نامعتبر');
      }
    } catch (_) {
      image = const _EmbedError(label: 'خطا در نمایش تصویر');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxW,
            maxHeight: 240,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // اسکرول عمودی ادیتور را نگیرد
            child: IgnorePointer(
              ignoring: false,
              child: RepaintBoundary(child: image),
            ),
          ),
        ),
      ),
    );
  }
}

class AudioEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'audio';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    Map<String, dynamic> meta = {};
    try {
      final raw = embedContext.node.value.data;
      if (raw is String) meta = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    final duration = (meta['duration'] as num?)?.toInt() ?? 0;
    return _AudioPlayerCard(
        durationSec: duration, label: meta['label'] as String?);
  }
}

class _AudioPlayerCard extends StatefulWidget {
  final int durationSec;
  final String? label;
  const _AudioPlayerCard({required this.durationSec, this.label});

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  bool _playing = false;
  double _speed = 1.0;
  int _pos = 0;

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.durationSec.clamp(1, 9999);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.brand3.withOpacity(0.12),
          AppColors.brand2.withOpacity(0.08),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand3.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: AppColors.brand3,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() {
                      _playing = !_playing;
                      if (_playing && _pos >= total) _pos = 0;
                    });
                    if (_playing) {
                      Future.doWhile(() async {
                        await Future.delayed(
                            Duration(milliseconds: (1000 / _speed).round()));
                        if (!_playing || !mounted) return false;
                        setState(() {
                          _pos++;
                          if (_pos >= total) {
                            _playing = false;
                            _pos = total;
                          }
                        });
                        return _playing;
                      });
                    }
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label ?? 'ضبط صوتی',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${_fmt(_pos)} / ${_fmt(total)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        )),
                  ],
                ),
              ),
              PopupMenuButton<double>(
                initialValue: _speed,
                onSelected: (v) => setState(() => _speed = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0.5, child: Text('۰.۵×')),
                  PopupMenuItem(value: 0.75, child: Text('۰.۷۵×')),
                  PopupMenuItem(value: 1.0, child: Text('۱×')),
                  PopupMenuItem(value: 1.5, child: Text('۱.۵×')),
                  PopupMenuItem(value: 2.0, child: Text('۲×')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_speed}×',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _pos / total,
              minHeight: 5,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
              color: AppColors.brand3,
            ),
          ),
        ],
      ),
    );
  }
}

class TableEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'table';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    Map<String, dynamic> meta = {};
    String rawData = '';
    try {
      final raw = embedContext.node.value.data;
      if (raw is String) {
        rawData = raw;
        meta = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}

    final data = (meta['data'] as List?)
            ?.map((r) => (r as List).map((c) => '$c').toList())
            .toList() ??
        <List<String>>[];
    final excel = meta['excel'] == true;
    final colW = (meta['colWidth'] as num?)?.toDouble() ?? 96.0;
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const _EmbedError(label: 'جدول خالی');
    }

    Future<void> openEdit() async {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => TableInsertDialog(
          excelStyle: true,
          initialData: meta,
        ),
      );
      if (result == null || result.isEmpty) return;

      // پیدا کردن و جایگزینی embed در سند
      final controller = embedContext.controller;
      final delta = controller.document.toDelta();
      var offset = 0;
      for (final op in delta.toList()) {
        final d = op.data;
        if (d is Map && d['table'] == rawData) {
          controller.replaceText(
            offset,
            1,
            BlockEmbed('table', result),
            TextSelection.collapsed(offset: offset + 1),
          );
          return;
        }
        offset += op.length ?? 1;
      }
      // fallback: اگر پیدا نشد، در انتها درج کن
      final end = controller.document.length - 1;
      controller.document.insert(end, BlockEmbed('table', result));
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand3.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // نوار ابزار کوچک جدول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppColors.brand3.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.grid_on_rounded,
                    size: 14, color: AppColors.brand3),
                const SizedBox(width: 6),
                Text(
                  excel ? 'جدول اکسل' : 'جدول',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand3,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: openEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 14, color: AppColors.brand3),
                        const SizedBox(width: 4),
                        Text('ویرایش',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand3,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(24),
              minScale: 0.5,
              maxScale: 2.5,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: theme.colorScheme.outline),
                ),
                defaultColumnWidth: FixedColumnWidth(colW),
                children: List.generate(data.length, (r) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: (excel && r == 0)
                          ? AppColors.brand3.withOpacity(0.14)
                          : (r.isEven
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.4)
                              : theme.colorScheme.surface),
                    ),
                    children: data[r]
                        .map((cell) => ConstrainedBox(
                              constraints:
                                  BoxConstraints(minWidth: colW, minHeight: 40),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Text(
                                  cell.trim().isEmpty ? ' ' : cell,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: (excel && r == 0)
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ))
                        .toList(),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbedError extends StatelessWidget {
  final String label;
  const _EmbedError({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.danger)),
        ],
      ),
    );
  }
}

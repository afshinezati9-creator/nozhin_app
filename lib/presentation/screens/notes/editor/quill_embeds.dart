import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    Map<String, dynamic> meta = {};
    try {
      final raw = embedContext.node.value.data;
      if (raw is String) meta = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    return _AudioPlayerCard(
      durationSec: (meta['duration'] as num?)?.toInt() ?? 0,
      label: meta['label'] as String? ?? 'صوت',
      path: meta['path'] as String?,
      dataUrl: meta['data'] as String?,
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  final int durationSec;
  final String label;
  final String? path;
  final String? dataUrl;

  const _AudioPlayerCard({
    required this.durationSec,
    required this.label,
    this.path,
    this.dataUrl,
  });

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  Duration _pos = Duration.zero;
  Duration _total = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.durationSec > 0) {
      _total = Duration(seconds: widget.durationSec);
    }
    _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _pos = d);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _total = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _playing = false;
        _pos = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_pos == Duration.zero ||
          _player.state == PlayerState.completed ||
          _player.state == PlayerState.stopped) {
        final source = await _resolveSource();
        if (source == null) {
          setState(() {
            _error = 'فایل صوتی پیدا نشد';
            _loading = false;
          });
          return;
        }
        await _player.play(source);
      } else {
        await _player.resume();
      }
      setState(() {
        _playing = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'پخش ممکن نیست';
        _loading = false;
        _playing = false;
      });
    }
  }

  Future<Source?> _resolveSource() async {
    final data = widget.dataUrl;
    if (data != null && data.startsWith('data:')) {
      try {
        final b64 = data.split(',').last;
        final bytes = base64Decode(b64);
        return BytesSource(bytes);
      } catch (_) {}
    }
    final path = widget.path;
    if (path != null && path.isNotEmpty && !kIsWeb) {
      final f = File(path);
      if (await f.exists()) return DeviceFileSource(path);
    }
    return null;
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMs = _total.inMilliseconds <= 0 ? 1 : _total.inMilliseconds;
    final progress = (_pos.inMilliseconds / totalMs).clamp(0.0, 1.0);

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
                  onTap: _toggle,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
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
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(_pos)} / ${_fmt(_total.inMilliseconds > 0 ? _total : Duration(seconds: widget.durationSec.clamp(0, 9999)))}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.outline.withOpacity(0.25),
              color: AppColors.brand3,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
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

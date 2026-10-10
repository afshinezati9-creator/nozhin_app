import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../domain/entities/note_entity.dart';

const _colorMap = {
  'blue': Color(0xFF3B82F6),
  'green': Color(0xFF10B981),
  'yellow': Color(0xFFF59E0B),
  'red': Color(0xFFEF4444),
  'purple': Color(0xFF8B5CF6),
  'pink': Color(0xFFEC4899),
  'indigo': Color(0xFF6366F1),
};

class NoteCard extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final bool compact;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onPin,
    this.onDelete,
    this.onDuplicate,
    this.compact = false,
  });

  /// پیش‌نمایش خوانا از Delta/JSON/HTML بدون نشان دادن insert و کد خام
  static String plainPreview(String raw, {int maxLen = 120}) {
    if (raw.trim().isEmpty) return '';
    var s = raw.trim();

    // Quill Delta JSON
    if (s.startsWith('[') || s.startsWith('{')) {
      try {
        final decoded = jsonDecode(s);
        final buf = StringBuffer();
        void walk(dynamic node) {
          if (node is List) {
            for (final e in node) {
              walk(e);
            }
          } else if (node is Map) {
            final ins = node['insert'];
            if (ins is String) {
              buf.write(ins);
            } else if (ins is Map) {
              if (ins.containsKey('image')) {
                buf.write('🖼 ');
              } else if (ins.containsKey('audio') || ins.containsKey('video')) {
                buf.write('🎵 ');
              } else if (ins.containsKey('table') || ins.containsKey('excel')) {
                buf.write('جدول ');
              } else {
                buf.write('• ');
              }
            }
          }
        }
        walk(decoded is Map && decoded.containsKey('ops')
            ? decoded['ops']
            : decoded);
        s = buf.toString();
      } catch (_) {
        // ادامه با strip ساده
      }
    }

    s = s
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\{[^}]*"insert"[^}]*\}'), ' ')
        .replaceAll(RegExp(r'"insert"\s*:\s*'), ' ')
        .replaceAll(RegExp(r'[{}\[\]"]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (s.length > maxLen) s = '${s.substring(0, maxLen)}…';
    return s;
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'همین الان';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    if (diff.inDays < 7) return '${diff.inDays} روز پیش';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stripColor = _colorMap[note.color] ?? AppColors.brand3;
    final preview = plainPreview(note.body, maxLen: compact ? 60 : 120);

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 0 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: stripColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppRadius.md),
                      bottomRight: Radius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 14,
                  compact ? 10 : 14,
                  compact ? 12 : 18,
                  compact ? 8 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (note.pinned) ...[
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.push_pin_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'بدون عنوان' : note.title,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 13 : 15,
                              color: note.title.isEmpty
                                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                                  : null,
                            ),
                          ),
                        ),
                        if (!compact)
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                            onSelected: (v) {
                              if (v == 'pin') onPin?.call();
                              if (v == 'dup') onDuplicate?.call();
                              if (v == 'del') onDelete?.call();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(note.pinned ? 'برداشتن سنجاق' : 'سنجاق'),
                              ),
                              const PopupMenuItem(
                                  value: 'dup', child: Text('تکثیر')),
                              const PopupMenuItem(
                                  value: 'del', child: Text('حذف')),
                            ],
                          ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        preview,
                        maxLines: compact ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                          height: 1.35,
                          fontSize: compact ? 11.5 : 13,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 6 : 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: stripColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: stripColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _relativeTime(note.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
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

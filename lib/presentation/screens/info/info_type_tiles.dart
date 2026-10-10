import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/info_item_entity.dart';

Future<void> copyText(BuildContext context, String text, VoidCallback? onDone) async {
  if (text.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text.trim()));
  onDone?.call();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('کپی شد'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// لینک — استایل خاص + باز کردن
class LinkInfoTile extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback onCopied;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LinkInfoTile({
    super.key,
    required this.item,
    required this.onCopied,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _open() async {
    var url = item.value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Shell(
      color: const Color(0xFF3B82F6),
      icon: Icons.link_rounded,
      title: item.title.isEmpty ? 'لینک' : item.title,
      badge: 'لینک',
      uses: item.uses,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.25)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      copyText(context, item.value, onCopied),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('کپی لینک'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _open,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('باز کردن'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// کد — شماره خط + رنگ
class CodeInfoTile extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback onCopied;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CodeInfoTile({
    super.key,
    required this.item,
    required this.onCopied,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lines = item.value.split('\n');
    if (lines.isEmpty) lines.add('');
    return _Shell(
      color: const Color(0xFF0F172A),
      icon: Icons.code_rounded,
      title: item.title.isEmpty ? 'کد' : item.title,
      badge: 'کد',
      uses: item.uses,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: List.generate(lines.length, (i) {
                  final alt = i.isOdd;
                  return Container(
                    color: alt
                        ? Colors.white.withOpacity(0.04)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            MoneyFormat.toPersianDigits('${i + 1}'),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lines[i].isEmpty ? ' ' : lines[i],
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              color: Color(0xFFA5F3FC),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => copyText(context, item.value, onCopied),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF334155)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('کپی کل کد'),
          ),
        ],
      ),
    );
  }
}

/// آدرس
class AddressInfoTile extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback onCopied;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressInfoTile({
    super.key,
    required this.item,
    required this.onCopied,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _Shell(
      color: const Color(0xFF10B981),
      icon: Icons.location_on_rounded,
      title: item.title.isEmpty ? 'آدرس' : item.title,
      badge: 'آدرس',
      uses: item.uses,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map_outlined,
                    color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.value, style: const TextStyle(height: 1.45)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => copyText(context, item.value, onCopied),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('کپی آدرس'),
          ),
        ],
      ),
    );
  }
}

/// متن / یادداشت
class TextNoteInfoTile extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback onCopied;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TextNoteInfoTile({
    super.key,
    required this.item,
    required this.onCopied,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isNote = item.type == InfoItemType.note;
    final isPrompt = item.type == InfoItemType.prompt;
    final color = isPrompt
        ? const Color(0xFF8B5CF6)
        : isNote
            ? const Color(0xFFF59E0B)
            : AppColors.brand3;
    return _Shell(
      color: color,
      icon: isPrompt
          ? Icons.auto_awesome
          : isNote
              ? Icons.sticky_note_2_rounded
              : Icons.notes_rounded,
      title: item.title.isEmpty ? item.typeLabel : item.title,
      badge: item.typeLabel,
      uses: item.uses,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.value,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => copyText(context, item.value, onCopied),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('کپی متن'),
          ),
        ],
      ),
    );
  }
}

/// تصویر (data url یا مسیر)
class ImageInfoTile extends StatelessWidget {
  final InfoItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ImageInfoTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget preview;
    if (item.value.startsWith('data:image')) {
      try {
        final b64 = item.value.split(',').last;
        final bytes = Uri.parse('data:;base64,$b64').data?.contentAsBytes();
        // simpler: MemoryImage via base64Decode
        preview = const Text('پیش‌نمایش تصویر');
      } catch (_) {
        preview = const Text('تصویر');
      }
    } else if (item.value.isNotEmpty) {
      preview = Text(item.value,
          maxLines: 2, overflow: TextOverflow.ellipsis);
    } else {
      preview = Text('بدون تصویر',
          style: theme.textTheme.bodySmall);
    }

    // Use Image.memory if base64
    Widget imageWidget;
    if (item.value.startsWith('data:image') && item.value.contains(',')) {
      try {
        final data = Uri.parse(item.value).data;
        if (data != null) {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              data.contentAsBytes(),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        } else {
          imageWidget = preview;
        }
      } catch (_) {
        imageWidget = preview;
      }
    } else {
      imageWidget = Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, size: 40),
      );
    }

    return _Shell(
      color: const Color(0xFFEC4899),
      icon: Icons.image_rounded,
      title: item.title.isEmpty ? 'تصویر' : item.title,
      badge: 'تصویر',
      uses: item.uses,
      onEdit: onEdit,
      onDelete: onDelete,
      child: imageWidget,
    );
  }
}

class _Shell extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String badge;
  final int uses;
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Shell({
    required this.color,
    required this.icon,
    required this.title,
    required this.badge,
    required this.uses,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${MoneyFormat.toPersianDigits('$uses')} بار استفاده',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

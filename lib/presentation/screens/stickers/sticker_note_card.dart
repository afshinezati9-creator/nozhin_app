import 'package:flutter/material.dart';
import '../../../core/utils/money_format.dart';
import '../../../domain/entities/sticker_entities.dart';

class StickerNoteCard extends StatelessWidget {
  final StickerNote note;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  const StickerNoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onMenu,
  });

  Color get _bg {
    final hex = stickerNoteColors[note.color] ?? 0xFFFEF3C7;
    return Color(hex);
  }

  IconData get _icon {
    switch (note.icon) {
      case 'cart':
        return Icons.shopping_cart_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'calendar':
        return Icons.calendar_today_outlined;
      case 'star':
        return Icons.star_outline;
      case 'heart':
        return Icons.favorite_border;
      case 'briefcase':
        return Icons.work_outline;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'plane':
        return Icons.flight_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'code':
        return Icons.code;
      case 'brush':
        return Icons.brush_outlined;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'lock':
        return Icons.lock_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = note.tasks.take(3).toList();
    final extra = note.tasks.length - tasks.length;

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // نوار چسب
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: CustomPaint(painter: _TapePainter()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(_icon, size: 14, color: Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? 'بدون عنوان' : note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (onMenu != null)
                            InkWell(
                              onTap: onMenu,
                              child: const Icon(Icons.more_vert, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (tasks.isEmpty)
                        Text(
                          'هنوز تسکی نیست',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        )
                      else
                        ...tasks.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    t.done
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 12,
                                    color: t.done
                                        ? const Color(0xFF059669)
                                        : Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      t.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        decoration: t.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      if (extra > 0)
                        Text(
                          '+${MoneyFormat.toPersianDigits('$extra')} مورد دیگر',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black.withOpacity(0.45),
                          ),
                        ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: note.progress,
                          minHeight: 4,
                          backgroundColor: Colors.black.withOpacity(0.08),
                          color: note.progress >= 1
                              ? const Color(0xFF059669)
                              : const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormat.toPersianDigits('${note.doneCount}')}/${MoneyFormat.toPersianDigits('${note.totalCount}')} کار',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
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

class _TapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1;
    // خطوط افقی ملایم — بدون حس کج بودن
    for (double y = 3; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// جای خالی افزودن برچسب
class StickerAddSlot extends StatelessWidget {
  final VoidCallback onTap;
  const StickerAddSlot({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'برچسب جدید',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

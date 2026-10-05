import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/entities/sticker_entities.dart';

/// تم‌های عمدتاً تیره + چوب + کاغذ سفید
class SurfaceBackground extends StatelessWidget {
  final SurfaceType type;
  final Widget child;

  const SurfaceBackground({
    super.key,
    required this.type,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _gradient(type)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: CustomPaint(painter: _Painter(type))),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(_light(type)),
                    Colors.transparent,
                    Colors.black.withOpacity(_shade(type)),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  double _light(SurfaceType t) {
    switch (t) {
      case SurfaceType.board:
      case SurfaceType.fridge:
        return 0.2;
      case SurfaceType.desk:
        return 0.1;
      default:
        return 0.04;
    }
  }

  double _shade(SurfaceType t) {
    switch (t) {
      case SurfaceType.board:
      case SurfaceType.fridge:
        return 0.05;
      default:
        return 0.25;
    }
  }

  LinearGradient _gradient(SurfaceType t) {
    switch (t) {
      case SurfaceType.wall: // کاغذ دیواری تیره
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3340), Color(0xFF1A1F2A), Color(0xFF12151C)],
        );
      case SurfaceType.desk: // چوب
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC9956C), Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
        );
      case SurfaceType.fridge: // سفید
        return const LinearGradient(
          colors: [Color(0xFFFAFBFC), Color(0xFFEEF1F4), Color(0xFFE4E8EC)],
        );
      case SurfaceType.board: // کاغذ سفید
        return const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
        );
      case SurfaceType.door: // چوب تیره
        return const LinearGradient(
          colors: [Color(0xFF5C3A1E), Color(0xFF3B2412), Color(0xFF1F140A)],
        );
      case SurfaceType.car: // تیره مات
        return const LinearGradient(
          colors: [Color(0xFF1E2430), Color(0xFF12161E), Color(0xFF0A0C10)],
        );
      case SurfaceType.cabinet: // چوب متوسط تیره
        return const LinearGradient(
          colors: [Color(0xFF6B4423), Color(0xFF4A2F18), Color(0xFF2E1C0E)],
        );
      case SurfaceType.mirror: // خاکستری تیره
        return const LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF1F2937), Color(0xFF111827)],
        );
    }
  }
}

class _Painter extends CustomPainter {
  final SurfaceType type;
  _Painter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case SurfaceType.wall:
      case SurfaceType.mirror:
      case SurfaceType.car:
        _darkPattern(canvas, size);
        break;
      case SurfaceType.desk:
      case SurfaceType.door:
      case SurfaceType.cabinet:
        _wood(canvas, size);
        break;
      case SurfaceType.fridge:
      case SurfaceType.board:
        _paper(canvas, size);
        break;
    }
  }

  void _darkPattern(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.03);
    for (double y = 12; y < size.height; y += 28) {
      for (double x = 12; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 2.5, p);
      }
    }
  }

  void _wood(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 30; i++) {
      p
        ..color = Colors.black.withOpacity(0.06 + (i % 3) * 0.02)
        ..strokeWidth = 1;
      final path = Path();
      final y = i * size.height / 26;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 18) {
        path.quadraticBezierTo(x + 9, y + (i.isEven ? 2 : -2), x + 18, y);
      }
      canvas.drawPath(path, p);
    }
  }

  void _paper(Canvas canvas, Size size) {
    final rnd = math.Random(5);
    final p = Paint()..color = Colors.black.withOpacity(0.025);
    for (var i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

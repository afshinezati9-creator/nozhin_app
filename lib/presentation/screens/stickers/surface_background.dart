import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/entities/sticker_entities.dart';

/// پس‌زمینه سطح استیکی‌نت — مینیمال
/// تم روشن → پس‌زمینه روشن/کاغذی | تم تاریک → پس‌زمینه تیره
class SurfaceBackground extends StatelessWidget {
  final SurfaceType type;
  final Widget child;

  const SurfaceBackground({
    super.key,
    required this.type,
    required this.child,
  });

  /// آیا این سطح در تم روشن «روشن» محسوب می‌شود؟
  static bool isLightSurface(SurfaceType t, Brightness brightness) {
    if (brightness == Brightness.dark) return false;
    switch (t) {
      case SurfaceType.fridge:
      case SurfaceType.board:
        return true;
      case SurfaceType.desk:
        return true; // چوب روشن
      default:
        return brightness == Brightness.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final light = brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(gradient: _gradient(type, light)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _Painter(type, light)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: light
                      ? [
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                          Colors.black.withOpacity(0.03),
                        ]
                      : [
                          Colors.white.withOpacity(0.04),
                          Colors.transparent,
                          Colors.black.withOpacity(0.28),
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

  LinearGradient _gradient(SurfaceType t, bool light) {
    if (light) {
      switch (t) {
        case SurfaceType.board:
        case SurfaceType.fridge:
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFEFB), Color(0xFFF4F6F8), Color(0xFFEEF1F4)],
          );
        case SurfaceType.desk:
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8D5C4), Color(0xFFD4B59A), Color(0xFFC4A484)],
          );
        case SurfaceType.wall:
          return const LinearGradient(
            colors: [Color(0xFFF7F8FA), Color(0xFFEEF0F4), Color(0xFFE6E9EF)],
          );
        case SurfaceType.door:
        case SurfaceType.cabinet:
          return const LinearGradient(
            colors: [Color(0xFFE0C3A8), Color(0xFFC9A882), Color(0xFFB8956F)],
          );
        case SurfaceType.car:
        case SurfaceType.mirror:
          return const LinearGradient(
            colors: [Color(0xFFF0F2F5), Color(0xFFE4E7EC), Color(0xFFD8DCE3)],
          );
      }
    }
    // تاریک
    switch (t) {
      case SurfaceType.wall:
        return const LinearGradient(
          colors: [Color(0xFF2C3340), Color(0xFF1A1F2A), Color(0xFF12151C)],
        );
      case SurfaceType.desk:
        return const LinearGradient(
          colors: [Color(0xFF5C4030), Color(0xFF3B2A1E), Color(0xFF241810)],
        );
      case SurfaceType.fridge:
      case SurfaceType.board:
        return const LinearGradient(
          colors: [Color(0xFF2A2E35), Color(0xFF1C1F26), Color(0xFF14161B)],
        );
      case SurfaceType.door:
      case SurfaceType.cabinet:
        return const LinearGradient(
          colors: [Color(0xFF4A2F18), Color(0xFF2E1C0E), Color(0xFF1A1008)],
        );
      case SurfaceType.car:
      case SurfaceType.mirror:
        return const LinearGradient(
          colors: [Color(0xFF1E2430), Color(0xFF12161E), Color(0xFF0A0C10)],
        );
    }
  }
}

class _Painter extends CustomPainter {
  final SurfaceType type;
  final bool light;
  _Painter(this.type, this.light);

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case SurfaceType.desk:
      case SurfaceType.door:
      case SurfaceType.cabinet:
        _wood(canvas, size);
        break;
      case SurfaceType.fridge:
      case SurfaceType.board:
        _paper(canvas, size);
        break;
      default:
        _dots(canvas, size);
    }
  }

  void _dots(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (light ? Colors.black : Colors.white).withOpacity(0.03);
    for (double y = 12; y < size.height; y += 28) {
      for (double x = 12; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 2, p);
      }
    }
  }

  void _wood(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 24; i++) {
      p
        ..color = Colors.black.withOpacity(light ? 0.04 : 0.08)
        ..strokeWidth = 1;
      final path = Path();
      final y = i * size.height / 22;
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 20) {
        path.quadraticBezierTo(x + 10, y + (i.isEven ? 1.5 : -1.5), x + 20, y);
      }
      canvas.drawPath(path, p);
    }
  }

  void _paper(Canvas canvas, Size size) {
    final rnd = math.Random(5);
    final p = Paint()
      ..color = Colors.black.withOpacity(light ? 0.02 : 0.04);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.2,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.light != light;
}

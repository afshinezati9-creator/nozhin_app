import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'main_shell.dart';
import '../widgets/nozhin_logo.dart';
import 'lock_screen.dart';
import '../../core/security/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _pulse;
  late final AnimationController _orbit;
  late final AnimationController _progress;

  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _slide;
  late final Animation<double> _titleFade;
  late final Animation<double> _tagFade;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _fade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _slide = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _tagFade = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _main.forward();
    Future.delayed(const Duration(milliseconds: 2800), _goHome);
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    final enabled = await SecureStorageService.instance.getAppLockEnabled();
    final pin = await SecureStorageService.instance.getAppLockPinHash();
    final needLock = enabled && pin != null && pin.isNotEmpty;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            needLock ? const LockScreen() : const MainShell(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    _orbit.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF0F172A),
              Color(0xFF134E4A),
              Color(0xFF0B1220),
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // حلقه‌های نوری چرخان
            AnimatedBuilder(
              animation: _orbit,
              builder: (_, __) {
                return CustomPaint(
                  size: size,
                  painter: _OrbitPainter(
                    progress: _orbit.value,
                    pulse: _pulse.value,
                  ),
                );
              },
            ),
            // نقاط نرم
            ...List.generate(12, (i) {
              final angle = (i / 12) * math.pi * 2;
              return AnimatedBuilder(
                animation: Listenable.merge([_orbit, _pulse]),
                builder: (_, __) {
                  final r = 90.0 + 40 * math.sin(_orbit.value * math.pi * 2 + i);
                  final cx = size.width / 2 + math.cos(angle + _orbit.value * 2) * r;
                  final cy = size.height / 2 - 40 + math.sin(angle + _orbit.value * 2) * r;
                  final o = 0.15 + 0.25 * _pulse.value;
                  return Positioned(
                    left: cx,
                    top: cy,
                    child: Opacity(
                      opacity: o.clamp(0.05, 0.5),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i.isEven
                              ? AppColors.brand3
                              : const Color(0xFF6366F1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand3.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            // محتوا
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_main, _pulse]),
                builder: (context, _) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: Transform.scale(
                        scale: _scale.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // هاله پشت لوگو
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 130 + 20 * _pulse.value,
                                  height: 130 + 20 * _pulse.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.brand3
                                            .withOpacity(0.35 * _pulse.value),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.brand3.withOpacity(0.9),
                                        const Color(0xFF6366F1),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brand3
                                            .withOpacity(0.45),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0F172A),
                                    ),
                                    alignment: Alignment.center,
                                    child: const NozhinLogo(
                                      size: 64,
                                      useThemeTint: false,
                                      color: Color(0xFF2DD4BF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Opacity(
                              opacity: _titleFade.value,
                              child: ShaderMask(
                                shaderCallback: (b) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF5EEAD4),
                                    Color(0xFFA5B4FC),
                                    Colors.white,
                                  ],
                                ).createShader(b),
                                child: const Text(
                                  'نوژین',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: _tagFade.value,
                              child: Text(
                                AppConstants.appTagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Opacity(
                              opacity: _tagFade.value,
                              child: SizedBox(
                                width: 160,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AnimatedBuilder(
                                        animation: _progress,
                                        builder: (_, __) {
                                          return LinearProgressIndicator(
                                            value: _progress.value,
                                            minHeight: 3,
                                            backgroundColor:
                                                Colors.white.withOpacity(0.08),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                              Color(0xFF2DD4BF),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'در حال آماده‌سازی…',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final double pulse;
  _OrbitPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 40);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 3; i++) {
      final r = 70.0 + i * 36 + 8 * pulse;
      paint.color = Color.lerp(
        const Color(0xFF14B8A6),
        const Color(0xFF6366F1),
        i / 2,
      )!
          .withOpacity(0.12 + 0.06 * pulse);
      canvas.drawCircle(c, r, paint);
      // نقطه روی مدار
      final a = progress * math.pi * 2 + i * 1.2;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.drawCircle(
        p,
        3,
        Paint()..color = const Color(0xFF2DD4BF).withOpacity(0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.progress != progress || old.pulse != pulse;
}

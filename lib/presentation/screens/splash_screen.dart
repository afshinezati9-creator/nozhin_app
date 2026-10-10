import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'main_shell.dart';
import '../widgets/nozhin_logo.dart';
import 'lock_screen.dart';
import '../../core/security/secure_storage_service.dart';

/// اسپلش مینیمال و مدرن — کوتاه، بدون انیمیشن سنگین
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _bar = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
    );

    _c.forward();
    // موازی با انیمیشن، قفل را چک کن — در مجموع ~1.1s
    Future.wait([
      Future.delayed(const Duration(milliseconds: 1000)),
      _readLock(),
    ]).then((results) {
      final needLock = results[1] as bool;
      _goHome(needLock);
    });
  }

  Future<bool> _readLock() async {
    try {
      final enabled = await SecureStorageService.instance.getAppLockEnabled();
      final pin = await SecureStorageService.instance.getAppLockPinHash();
      return enabled && pin != null && pin.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _goHome(bool needLock) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            needLock ? const LockScreen() : const MainShell(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Opacity(
              opacity: _fade.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HawzhinLogo(
                        size: 200,
                        variant: HawzhinLogoVariant.petals,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _bar.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.brand3.withOpacity(0.9),
                            ),
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
    );
  }
}

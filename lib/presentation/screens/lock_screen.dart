import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/security/biometric_service.dart';
import 'main_shell.dart';

/// صفحه قفل با PIN چهار تا شش رقمی
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  static String hashPin(String pin) {
    var h = 0x811c9dc5;
    final data = 'nozhin_v1_$pin'.codeUnits;
    for (final c in data) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _bioAvailable = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _prepareBiometric();
  }

  Future<void> _prepareBiometric() async {
    final enabled =
        await SecureStorageService.instance.getBiometricLockEnabled();
    final can = await BiometricService.instance.canCheck;
    if (!mounted) return;
    setState(() {
      _bioEnabled = enabled;
      _bioAvailable = can;
    });
    if (enabled && can) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _busy = true);
    final ok = await BiometricService.instance.authenticate(
      reason: 'باز کردن نوژین با اثر انگشت یا تشخیص چهره',
    );
    if (!mounted) return;
    if (ok) {
      _goMain();
    } else {
      setState(() => _busy = false);
    }
  }

  void _goMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pin.length < 4) {
      setState(() => _error = 'حداقل ۴ رقم وارد کن');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final stored = await SecureStorageService.instance.getAppLockPinHash();
    final ok = stored != null && stored == LockScreen.hashPin(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      setState(() {
        _busy = false;
        _pin = '';
        _error = 'رمز اشتباه است';
      });
    }
  }

  void _onDigit(String d) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length >= 4) {
      // auto-try when reaches stored length — try at 4,5,6
      _tryAuto();
    }
  }

  Future<void> _tryAuto() async {
    final stored = await SecureStorageService.instance.getAppLockPinHash();
    if (stored == null) return;
    if (LockScreen.hashPin(_pin) == stored) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else if (_pin.length >= 6) {
      setState(() {
        _pin = '';
        _error = 'رمز اشتباه است';
      });
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.lock_rounded, size: 48, color: AppColors.brand3),
              const SizedBox(height: 16),
              Text(
                'قفل نوژین',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'رمز عبور را وارد کن',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? AppColors.brand3
                          : theme.colorScheme.outline.withOpacity(0.35),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w700)),
              ],
              const Spacer(),
              _pad(theme),
              const SizedBox(height: 12),
              if (_busy) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pad(ThemeData theme) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 72);
              return SizedBox(
                width: 72,
                height: 72,
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (k == '⌫') {
                        _backspace();
                      } else {
                        _onDigit(k);
                      }
                    },
                    child: Center(
                      child: Text(
                        k,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

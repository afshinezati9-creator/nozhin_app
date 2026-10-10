import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:permission_handler/permission_handler.dart';

/// اثرانگشت / Face ID — فقط اندروید/iOS
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isSupported async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> get canCheck async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canBio = await _auth.canCheckBiometrics;
      if (canBio) return true;
      return supported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> get availableTypes async {
    if (kIsWeb) return const [];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// باز کردن صفحهٔ دسترسی/جزئیات برنامه در تنظیمات سیستم
  Future<bool> openSystemAppSettings() async {
    if (kIsWeb) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'برای باز کردن هاوژین تأیید هویت کن',
    bool biometricOnly = false,
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Biometric PlatformException: ${e.code} ${e.message}');
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return false;
      }
      if (biometricOnly) {
        try {
          return await _auth.authenticate(
            localizedReason: reason,
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
              useErrorDialogs: true,
              sensitiveTransaction: false,
            ),
          );
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Biometric auth error: $e');
      return false;
    }
  }
}

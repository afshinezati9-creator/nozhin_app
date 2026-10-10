import 'package:flutter/material.dart';
import '../security/secure_storage_service.dart';
import '../../domain/entities/settings_entity.dart';

/// سرویس مدیریت تنظیمات کاربر با ذخیره‌سازی امن
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  final _secure = SecureStorageService.instance;

  Future<SettingsEntity> load() async {
    final themeStr = await _secure.getThemeMode();
    final fontStr = await _secure.getFontSize();
    final family = await _secure.getFontFamily() ?? 'Vazirmatn';
    final name = await _secure.getUserName() ?? '';
    final lockEnabled = await _secure.getAppLockEnabled();
    final pinHash = await _secure.getAppLockPinHash();

    return SettingsEntity(
      userName: name,
      themeMode: _parseThemeMode(themeStr),
      fontSize: _parseFontSize(fontStr),
      fontFamily: 'Vazirmatn',
      appLockEnabled: lockEnabled,
      appLockPinHash: pinHash,
    );
  }

  Future<void> save(SettingsEntity settings) async {
    await _secure.saveThemeMode(_themeModeToString(settings.themeMode));
    await _secure.saveFontSize(_fontSizeToString(settings.fontSize));
    await _secure.saveFontFamily(settings.fontFamily);
    await _secure.saveUserName(settings.userName);
    await _secure.saveAppLockEnabled(settings.appLockEnabled);
    if (settings.appLockPinHash != null) {
      await _secure.saveAppLockPinHash(settings.appLockPinHash!);
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _secure.saveThemeMode(_themeModeToString(mode));
  }

  Future<void> saveFontSize(AppFontSizeOption size) async {
    await _secure.saveFontSize(_fontSizeToString(size));
  }

  Future<void> saveFontFamily(String family) async {
    await _secure.saveFontFamily(family);
  }

  Future<void> saveUserName(String name) async {
    await _secure.saveUserName(name);
  }

  // ---------- helpers ----------
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  AppFontSizeOption _parseFontSize(String? value) {
    switch (value) {
      case 'small':
        return AppFontSizeOption.small;
      case 'large':
        return AppFontSizeOption.large;
      default:
        return AppFontSizeOption.medium;
    }
  }

  String _fontSizeToString(AppFontSizeOption size) {
    switch (size) {
      case AppFontSizeOption.small:
        return 'small';
      case AppFontSizeOption.medium:
        return 'medium';
      case AppFontSizeOption.large:
        return 'large';
    }
  }
}

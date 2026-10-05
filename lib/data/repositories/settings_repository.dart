import '../../core/services/settings_service.dart';
import '../../domain/entities/settings_entity.dart';
import 'package:flutter/material.dart';

class SettingsRepository {
  final _service = SettingsService.instance;

  Future<SettingsEntity> load() => _service.load();

  Future<void> save(SettingsEntity settings) => _service.save(settings);

  Future<void> updateThemeMode(ThemeMode mode) => _service.saveThemeMode(mode);

  Future<void> updateFontSize(AppFontSizeOption size) =>
      _service.saveFontSize(size);

  Future<void> updateUserName(String name) => _service.saveUserName(name);
}

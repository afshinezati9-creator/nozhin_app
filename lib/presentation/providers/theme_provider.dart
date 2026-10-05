import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/settings_service.dart';
import '../../domain/entities/settings_entity.dart';

enum AppFontSize { small, medium, large }

class ThemeState {
  final ThemeMode themeMode;
  final AppFontSize fontSize;
  final String fontFamily;
  final String userName;
  final bool isLoaded;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.fontSize = AppFontSize.medium,
    this.fontFamily = 'Vazirmatn',
    this.userName = '',
    this.isLoaded = false,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppFontSize? fontSize,
    String? fontFamily,
    String? userName,
    bool? isLoaded,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      userName: userName ?? this.userName,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  double get fontSizeFactor {
    switch (fontSize) {
      case AppFontSize.small:
        return AppConstants.fontSizeSmall;
      case AppFontSize.medium:
        return AppConstants.fontSizeMedium;
      case AppFontSize.large:
        return AppConstants.fontSizeLarge;
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadFromStorage();
  }

  final _settings = SettingsService.instance;

  Future<void> _loadFromStorage() async {
    try {
      final s = await _settings.load();
      state = ThemeState(
        themeMode: s.themeMode,
        fontSize: _mapFont(s.fontSize),
        fontFamily: s.fontFamily,
        userName: s.userName,
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  AppFontSize _mapFont(AppFontSizeOption o) {
    switch (o) {
      case AppFontSizeOption.small:
        return AppFontSize.small;
      case AppFontSizeOption.medium:
        return AppFontSize.medium;
      case AppFontSizeOption.large:
        return AppFontSize.large;
    }
  }

  AppFontSizeOption _mapFontBack(AppFontSize f) {
    switch (f) {
      case AppFontSize.small:
        return AppFontSizeOption.small;
      case AppFontSize.medium:
        return AppFontSizeOption.medium;
      case AppFontSize.large:
        return AppFontSizeOption.large;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _settings.saveThemeMode(mode);
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _settings.saveFontFamily(family);
  }

  Future<void> setFontSize(AppFontSize size) async {
    state = state.copyWith(fontSize: size);
    await _settings.saveFontSize(_mapFontBack(size));
  }

  Future<void> setUserName(String name) async {
    state = state.copyWith(userName: name);
    await _settings.saveUserName(name);
  }

  void toggleDarkLight() {
    if (state.themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

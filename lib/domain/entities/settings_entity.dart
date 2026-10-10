import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppFontSizeOption { small, medium, large }

class SettingsEntity extends Equatable {
  final String userName;
  final ThemeMode themeMode;
  final AppFontSizeOption fontSize;
  final String fontFamily;
  final bool appLockEnabled;
  final String? appLockPinHash; // هش پین – هرگز پین خام ذخیره نمی‌شود

  const SettingsEntity({
    this.userName = '',
    this.themeMode = ThemeMode.system,
    this.fontSize = AppFontSizeOption.medium,
    this.fontFamily = 'Vazirmatn',
    this.appLockEnabled = false,
    this.appLockPinHash,
  });

  SettingsEntity copyWith({
    String? userName,
    ThemeMode? themeMode,
    AppFontSizeOption? fontSize,
    String? fontFamily,
    bool? appLockEnabled,
    String? appLockPinHash,
  }) {
    return SettingsEntity(
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: appLockPinHash ?? this.appLockPinHash,
    );
  }

  double get fontSizeFactor {
    switch (fontSize) {
      case AppFontSizeOption.small:
        return 0.9;
      case AppFontSizeOption.medium:
        return 1.0;
      case AppFontSizeOption.large:
        return 1.15;
    }
  }

  @override
  List<Object?> get props => [
        userName, themeMode, fontSize, fontFamily, appLockEnabled, appLockPinHash,
      ];
}

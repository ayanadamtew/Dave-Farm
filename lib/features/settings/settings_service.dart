import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'dave_farm_theme_mode';
  static const _languageKey = 'dave_farm_language_code';
  static const _farmNameKey = 'dave_farm_name';

  Future<ThemeMode> themeMode() async {
    final value = await _storage.read(key: _themeKey);
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    await _storage.write(key: _themeKey, value: theme.name);
  }

  Future<String?> languageCode() async {
    return await _storage.read(key: _languageKey);
  }

  Future<void> updateLanguageCode(String code) async {
    await _storage.write(key: _languageKey, value: code);
  }

  Future<String?> farmName() async {
    return await _storage.read(key: _farmNameKey);
  }

  Future<void> updateFarmName(String name) async {
    await _storage.write(key: _farmNameKey, value: name);
  }
}

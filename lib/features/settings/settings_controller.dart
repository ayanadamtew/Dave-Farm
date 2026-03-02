import 'package:flutter/material.dart';
import 'settings_service.dart';

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  late Locale? _locale;
  String? _farmName;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  String? get farmName => _farmName;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    final langCode = await _settingsService.languageCode();
    _locale = langCode != null ? Locale(langCode) : null;
    _farmName = await _settingsService.farmName() ?? 'Dave Farm';
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) return;

    _locale = newLocale;
    notifyListeners();
    if (newLocale != null) {
      await _settingsService.updateLanguageCode(newLocale.languageCode);
    }
  }

  Future<void> updateFarmName(String newName) async {
    if (newName == _farmName) return;

    _farmName = newName;
    notifyListeners();
    await _settingsService.updateFarmName(newName);
  }
}

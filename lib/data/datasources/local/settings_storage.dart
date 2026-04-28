import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsStorage {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  Future<Locale?> loadLocale();
  Future<void> saveLocale(Locale? locale);
  Future<bool> loadNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);
}

class SharedPrefsSettingsStorage implements SettingsStorage {
  SharedPrefsSettingsStorage(this._prefs);

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _localeKey = 'settings.locale';
  static const String _notificationsEnabledKey = 'settings.notifications_enabled';

  final SharedPreferences _prefs;

  @override
  Future<ThemeMode> loadThemeMode() async {
    final raw = _prefs.getString(_themeModeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  @override
  Future<Locale?> loadLocale() async {
    final code = _prefs.getString(_localeKey);
    if (code == null || code.isEmpty) {
      return null;
    }
    return Locale(code);
  }

  @override
  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_localeKey);
      return;
    }
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  @override
  Future<bool> loadNotificationsEnabled() async {
    return _prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }
}

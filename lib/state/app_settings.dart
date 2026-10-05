import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide UI preferences (language + theme), persisted locally.
class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _kTheme = 'ui_theme_mode';
  static const String _kLocale = 'ui_locale';

  /// Arabic is the default language on first launch.
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    Intl.defaultLocale = 'ar';
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocale) ?? 'ar';
      locale.value = Locale(code);
      Intl.defaultLocale = code;
      final themeIndex = prefs.getInt(_kTheme) ?? ThemeMode.system.index;
      themeMode.value = ThemeMode.values[themeIndex];
    } catch (_) {
      // Preferences unavailable — keep the defaults above.
    }
  }

  Future<void> setLocale(Locale value) async {
    locale.value = value;
    Intl.defaultLocale = value.languageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocale, value.languageCode);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTheme, value.index);
    } catch (_) {}
  }
}

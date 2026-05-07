import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  ENUMS & EXTENSIONS
// ─────────────────────────────────────────────
enum AppThemeMode { light, dark, auto }

enum AccentColor {
  softGold,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  lavenderPurple,
  rosePink,
}

extension AccentColorExt on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.softGold:
        return const Color(0xFFE0C58F);
      case AccentColor.oceanBlue:
        return const Color(0xFF4A90D9);
      case AccentColor.forestGreen:
        return const Color(0xFF3DB87A);
      case AccentColor.sunsetOrange:
        return const Color(0xFFFF7043);
      case AccentColor.lavenderPurple:
        return const Color(0xFF9B72CF);
      case AccentColor.rosePink:
        return const Color(0xFFE91E8C);
    }
  }

  String get label {
    switch (this) {
      case AccentColor.softGold:
        return 'Soft Gold';
      case AccentColor.oceanBlue:
        return 'Ocean Blue';
      case AccentColor.forestGreen:
        return 'Forest Green';
      case AccentColor.sunsetOrange:
        return 'Sunset Orange';
      case AccentColor.lavenderPurple:
        return 'Lavender Purple';
      case AccentColor.rosePink:
        return 'Rose Pink';
    }
  }
}

// ─────────────────────────────────────────────
//  THEME PROVIDER
// ─────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'appThemeMode';
  static const String _accentColorKey = 'accentColor';

  late SharedPreferences _prefs;
  AppThemeMode _themeMode = AppThemeMode.light;
  AccentColor _accentColor = AccentColor.softGold;
  bool _isInitialized = false;

  ThemeProvider() {
    _initPreferences();
  }

  AppThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  bool get isInitialized => _isInitialized;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.auto:
        return ThemeMode.system;
    }
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final savedTheme = _prefs.getString(_themeModeKey);
    final savedAccent = _prefs.getString(_accentColorKey);

    if (savedTheme != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => AppThemeMode.light,
      );
    }

    if (savedAccent != null) {
      _accentColor = AccentColor.values.firstWhere(
        (color) => color.toString() == savedAccent,
        orElse: () => AccentColor.softGold,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  Future<void> setAccentColor(AccentColor color) async {
    _accentColor = color;
    await _prefs.setString(_accentColorKey, color.toString());
    notifyListeners();
  }
}

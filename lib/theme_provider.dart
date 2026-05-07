import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  ENUMS & EXTENSIONS
// ─────────────────────────────────────────────
enum AppThemeMode { light, dark, auto }

enum PrimaryColor {
  navyBlue,
  deepTeal,
  darkPurple,
  forestGreen,
  charcoal,
  pinkRose,
  coralRed,
  sunflowerYellow,
  skyBlue,
  mintGreen,
  coralOrange,
  violet,
}

extension PrimaryColorExt on PrimaryColor {
  Color get color {
    switch (this) {
      case PrimaryColor.navyBlue:
        return const Color(0xFF243A6E);
      case PrimaryColor.deepTeal:
        return const Color(0xFF1B5E6D);
      case PrimaryColor.darkPurple:
        return const Color(0xFF5B2CA0);
      case PrimaryColor.forestGreen:
        return const Color(0xFF2D5F3F);
      case PrimaryColor.charcoal:
        return const Color(0xFF2C2C2C);
      case PrimaryColor.pinkRose:
        return const Color(0xFFFFB3D9);
      case PrimaryColor.coralRed:
        return const Color(0xFFD32F2F);
      case PrimaryColor.sunflowerYellow:
        return const Color(0xFFFFF9C4);
      case PrimaryColor.skyBlue:
        return const Color(0xFFB3E5FC);
      case PrimaryColor.mintGreen:
        return const Color(0xFFB8E6D1);
      case PrimaryColor.coralOrange:
        return const Color(0xFFFFCCB3);
      case PrimaryColor.violet:
        return const Color(0xFF7C4DFF);
    }
  }

  String get label {
    switch (this) {
      case PrimaryColor.navyBlue:
        return 'Navy Blue';
      case PrimaryColor.deepTeal:
        return 'Deep Teal';
      case PrimaryColor.darkPurple:
        return 'Dark Purple';
      case PrimaryColor.forestGreen:
        return 'Forest Green';
      case PrimaryColor.charcoal:
        return 'Charcoal';
      case PrimaryColor.pinkRose:
        return 'Pink Rose';
      case PrimaryColor.coralRed:
        return 'Coral Red';
      case PrimaryColor.sunflowerYellow:
        return 'Sunflower Yellow';
      case PrimaryColor.skyBlue:
        return 'Sky Blue';
      case PrimaryColor.mintGreen:
        return 'Mint Green';
      case PrimaryColor.coralOrange:
        return 'Coral Orange';
      case PrimaryColor.violet:
        return 'Violet';
    }
  }
}

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
  static const String _primaryColorKey = 'primaryColor';

  late SharedPreferences _prefs;
  AppThemeMode _themeMode = AppThemeMode.light;
  AccentColor _accentColor = AccentColor.softGold;
  PrimaryColor _primaryColor = PrimaryColor.navyBlue;
  bool _isInitialized = false;

  ThemeProvider() {
    _initPreferences();
  }

  AppThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  PrimaryColor get primaryColor => _primaryColor;
  bool get isInitialized => _isInitialized;

  Color get primaryColorValue => _primaryColor.color;

  Color get primaryForegroundColor {
    final color = _primaryColor.color;

    if (color.computeLuminance() < 0.6) {
      return color;
    }

    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness * 0.55).clamp(0.0, 1.0))
        .toColor();
  }

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
    final savedPrimary = _prefs.getString(_primaryColorKey);

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

    if (savedPrimary != null) {
      _primaryColor = PrimaryColor.values.firstWhere(
        (color) => color.toString() == savedPrimary,
        orElse: () => PrimaryColor.navyBlue,
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

  Future<void> setPrimaryColor(PrimaryColor color) async {
    _primaryColor = color;
    await _prefs.setString(_primaryColorKey, color.toString());
    notifyListeners();
  }
}

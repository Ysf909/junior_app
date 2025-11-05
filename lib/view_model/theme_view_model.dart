import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode'; // we store: 'light' or 'dark'

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  ThemeViewModel() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);

    if (saved == 'dark') {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> toggle() async {
    if (_mode == ThemeMode.light) {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      _mode == ThemeMode.dark ? 'dark' : 'light',
    );

    notifyListeners();
  }

  // optional, if you want to access ThemeData directly
  ThemeData get lightTheme => ThemeData.light();
  ThemeData get darkTheme => ThemeData.dark();
}

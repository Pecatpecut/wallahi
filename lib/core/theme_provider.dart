import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDarkMode => _isDark;

  /// THEME MODE
  ThemeMode get currentTheme =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  /// TOGGLE
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final _isDark = true.obs;

  bool get isDarkMode => _isDark.value;

  ThemeMode get currentTheme =>
      _isDark.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark.value = !_isDark.value;
  }
}

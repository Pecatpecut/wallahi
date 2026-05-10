import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ✅ GetX replacement untuk ThemeProvider
/// Gunakan Get.find<ThemeController>() untuk akses dari mana saja
class ThemeController extends GetxController {
  final _isDark = true.obs; // observable bool, default dark

  bool get isDarkMode => _isDark.value;

  ThemeMode get currentTheme =>
      _isDark.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark.value = !_isDark.value;
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  /// DARK MODE (utama)
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D18),

          colorScheme: const ColorScheme.dark(
        primary: Color(0xFFACA3FF),
        secondary: Color(0xFF5AF9F3),
        surface: Color(0xFF0D0D18), 
      onSurface: Colors.white,    
        
      ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE9E6F7)),
    ),
  );

  /// LIGHT MODE
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,

        colorScheme: const ColorScheme.light(
        primary: Color(0xFF6F5FEA),
        secondary: Color(0xFF00BFA6),
        surface: Colors.white,
        onSurface: Colors.black,

      ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );
}

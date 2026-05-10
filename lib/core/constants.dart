import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
class AppConstants {
  /// APP
  static const String appName = "Arnn Apprem";

  /// PADDING
  static const double padding = 16.0;
  static const double paddingH = 24.0;



  /// RADIUS
  static const double radius = 16.0;
  static const double cardRadius = 24.0;    // ← glassmorphism cards
  static const double chipRadius = 20.0;    // ← chips & badges
  static const double dialogRadius = 28.0;  

    // DARK BG — dipakai di semua halaman
  static const Color darkBg1 = Color(0xFF0A0A14);
  static const Color darkBg2 = Color(0xFF111124);

  /// API
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  /// DEFAULT IMAGE
  static const String defaultImage =
      "https://via.placeholder.com/150";
}
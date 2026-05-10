import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Edge-to-edge: hilangkan putih di navigation bar bawah
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ✅ Portrait only — kalau mau landscape juga, hapus baris ini
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('id_ID', null);

  // Load .env
  await dotenv.load(fileName: ".env");

  // Init Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Cek sesi user + role
  String initialRoute = '/login';
  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = data['role'] ?? 'customer';
      initialRoute = role == 'admin' ? '/admin' : '/home';
    } catch (_) {
      initialRoute = '/login';
    }
  }

  // ✅ Daftarkan ThemeController ke GetX
  Get.put(ThemeController());

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return Obx(() {
      // ✅ Obx rebuild otomatis saat theme berubah
      final isDark = themeCtrl.isDarkMode;

      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      );

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeCtrl.currentTheme,
        initialRoute: initialRoute,
        routes: AppRoutes.routes,
      );
    });
  }
}
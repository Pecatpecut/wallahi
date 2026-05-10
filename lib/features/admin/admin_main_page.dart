import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_market_page.dart';
import 'admin_garansi_page.dart';
import 'admin_setting_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int currentIndex = 0;

  final pages = const [
    AdminDashboardPage(),
    AdminGaransiPage(),
    AdminMarketPage(),
    AdminSettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Garansi"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Market"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
        ],
      ),
    );
  }
}
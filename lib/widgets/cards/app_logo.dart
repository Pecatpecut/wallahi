import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final String path;

  const AppLogo({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white.withOpacity(0.05),
        child: Image.asset(
          path,
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../widgets/shared/spacing.dart';
import '../../core/constants.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0A0A14),
                    const Color(0xFF111124),
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                  ]
                : [
                    Colors.white,
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              /// 🔥 CUSTOM APPBAR (CONSISTENT)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Social Media",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ],
                ),
              ),

              /// 🔥 CONTENT
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [

                    /// HEADER
                    Text(
                      "Connect With Us",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    Space.h10,

                    Text(
                      "Hubungi kami melalui platform berikut untuk bantuan atau informasi lebih lanjut.",
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),

                    Space.h20,

                    /// ITEMS
                    _item(
                      context,
                      icon: Icons.chat,
                      title: "WhatsApp",
                      subtitle: "+62 852-4703-4305",
                      color: const Color(0xFF25D366),
                    ),

                    _item(
                      context,
                      icon: Icons.camera_alt,
                      title: "Instagram",
                      subtitle: "@arnn.apprem",
                      color: const Color(0xFFE1306C),
                    ),

                    _item(
                      context,
                      icon: Icons.alternate_email,
                      title: "X (Twitter)",
                      subtitle: "@pisceslif",
                      color: const Color(0xFF1DA1F2),
                    ),

                    Space.h30,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 ITEM UPGRADE (INI YANG PALING BERUBAH)
  /// 🔥 ITEM TANPA URL LAUNCHER
Widget _item(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        /// ICON
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),

        const SizedBox(width: 16),

        /// TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        /// ARROW (tetap ditampilkan biar konsisten tampilan)
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.open_in_new,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
  
}
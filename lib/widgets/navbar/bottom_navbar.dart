import 'package:flutter/material.dart';

class CustomBottomNavbar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavbar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return; // ✅ Hindari push halaman yang sama
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (r) => false);
        break;
      case 1:
        Navigator.pushNamed(context, '/products');
        break;
      case 2:
        Navigator.pushNamed(context, '/orders');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // ✅ Gradient card konsisten dengan halaman lain
        color: isDark
            ? const Color(0xFF111124).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: "Home",
                theme: theme,
                isDark: isDark,
              ),
              _navItem(
                context: context,
                index: 1,
                icon: Icons.apps_outlined,
                activeIcon: Icons.apps_rounded,
                label: "Produk",
                theme: theme,
                isDark: isDark,
              ),
              _navItem(
                context: context,
                index: 2,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: "Order",
                theme: theme,
                isDark: isDark,
              ),
              _navItem(
                context: context,
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: "Profil",
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive
                  ? (isDark ? Colors.black : Colors.white)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            // ✅ Label hanya muncul saat aktif (animated expand)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
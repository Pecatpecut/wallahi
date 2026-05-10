import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ✅ Label dengan garis aksen kiri
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),

        // ✅ Action link
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
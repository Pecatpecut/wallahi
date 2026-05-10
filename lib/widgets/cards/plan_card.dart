import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.surface.withValues(alpha: 0.6),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔥 TITLE + CHECK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary),
                ],
              ),

              const SizedBox(height: 10),

              /// 🔥 FEATURES
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• $f",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  )),

              const SizedBox(height: 10),

              /// 🔥 PRICE
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
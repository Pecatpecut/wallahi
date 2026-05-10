import 'package:flutter/material.dart';

class CheckoutItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String image;

  const CheckoutItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          /// 🔥 IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),

          const SizedBox(width: 12),

          /// 🔥 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 PRICE
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
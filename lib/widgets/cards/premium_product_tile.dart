import 'package:flutter/material.dart';

class PremiumProductTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? price;
  final String? category;
  final VoidCallback? onTap;

  const PremiumProductTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.price,
    this.category,
    this.onTap,
  });

  // Format harga: 150000 → 150.000
  String _formatPrice(String raw) {
    final num = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final str = num.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedPrice =
        price != null ? _formatPrice(price!) : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.02),
                  ]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── LOGO ──
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.grey.shade100,
              ),
              clipBehavior: Clip.hardEdge,
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 14),

            // ── TEXT ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama produk
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Subtitle (durasi • tipe)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Badge kategori (opsional)
                  if (category != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        category!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── HARGA + ARROW ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (formattedPrice != null) ...[
                  Text(
                    "Mulai dari",
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Rp $formattedPrice",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
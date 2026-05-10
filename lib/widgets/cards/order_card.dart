import 'package:flutter/material.dart';
import '../../core/constants.dart';

class PremiumOrderCard extends StatelessWidget {
  final Map data;
  final VoidCallback? onTap;

  const PremiumOrderCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final createdAt =
        DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now();
    final duration = data['duration_days'] ?? 30;
    final status = (data['status'] ?? 'pending').toString();
    final imageUrl = data['products']?['image'];

    final endDate = createdAt.add(Duration(days: duration));
    final now = DateTime.now();

    int remaining = endDate.difference(now).inDays;
    if (remaining < 0) remaining = 0;

    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected'; // ✅ Tambah rejected
    final isExpired = isApproved && remaining == 0;
    final isActive = isApproved && remaining > 0;

    double progress = duration > 0 ? (remaining / duration) : 0;
    if (progress < 0) progress = 0;

    // ✅ Warna & label dinamis per status termasuk rejected
    final Color statusColor = isActive
        ? Colors.green
        : isPending
            ? Colors.orange
            : isRejected
                ? Colors.grey
                : Colors.redAccent;

    final String statusLabel = isActive
        ? "AKTIF"
        : isPending
            ? "PENDING"
            : isRejected
                ? "DITOLAK"
                : "EXPIRED";

    final IconData statusIcon = isActive
        ? Icons.check_circle_outline
        : isPending
            ? Icons.hourglass_empty_outlined
            : isRejected
                ? Icons.block_outlined
                : Icons.cancel_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.02),
                  ]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            // ✅ Border merah tipis jika rejected agar mencolok
            color: isRejected
                ? Colors.grey.withValues(alpha: 0.3)
                : isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ✅ Banner merah di atas card jika rejected
            if (isRejected)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Order ini ditolak oleh admin. Hubungi support untuk info lebih lanjut.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Baris atas: thumbnail + info + badge
                  Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isRejected
                                ? Colors.grey.withValues(alpha: 0.2)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: imageUrl != null &&
                                imageUrl.toString().isNotEmpty
                            ? ColorFiltered(
                                // ✅ Grayscale thumbnail jika rejected
                                colorFilter: isRejected
                                    ? const ColorFilter.matrix([
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0, 0, 0, 1, 0,
                                      ])
                                    : const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.multiply),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 22,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.inventory_2_outlined,
                                size: 22,
                                color: isRejected
                                    ? Colors.grey.withValues(alpha: 0.4)
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.4),
                              ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['product_name'] ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                // ✅ Teks sedikit redup jika rejected
                                color: isRejected
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                _infoChip(
                                  Icons.layers_outlined,
                                  data['variant_type'] ?? '-',
                                  theme,
                                  isDark,
                                  muted: isRejected,
                                ),
                                const SizedBox(width: 6),
                                _infoChip(
                                  Icons.timelapse_outlined,
                                  "$duration hari",
                                  theme,
                                  isDark,
                                  muted: isRejected,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: statusColor.withValues(alpha: 0.12),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Sembunyikan progress bar jika rejected
                  if (!isRejected) ...[
                    const SizedBox(height: 14),

                    Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.06),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Subscription Progress",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          isPending
                              ? "Menunggu aktivasi"
                              : isExpired
                                  ? "Berakhir"
                                  : "$remaining hari tersisa",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExpired
                                ? Colors.redAccent
                                : isPending
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 7,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: isPending ? 0 : progress,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isExpired
                                      ? [Colors.redAccent, Colors.red]
                                      : progress < 0.25
                                          ? [Colors.orange, Colors.amber]
                                          : [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary,
                                            ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isActive && progress < 0.25 && progress > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 13, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            "Segera perpanjang langgananmu",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // ✅ Tombol hubungi support jika rejected
                  if (isRejected) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/order-detail',
                              arguments: data),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radius),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          color: Colors.grey.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.support_agent_outlined,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              "Lihat Detail & Hubungi Support",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label,
    ThemeData theme,
    bool isDark, {
    bool muted = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: muted
              ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: muted
                ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/product_service.dart';

class AdminProductDetailPage extends StatefulWidget {
  const AdminProductDetailPage({super.key});

  @override
  State<AdminProductDetailPage> createState() =>
      _AdminProductDetailPageState();
}

class _AdminProductDetailPageState extends State<AdminProductDetailPage>
    with SingleTickerProviderStateMixin {
  final service = ProductService();

  late Map product;
  bool _isDeletingProduct = false;

  // ✅ Animasi konsisten dengan seluruh halaman
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)!.settings.arguments as Map;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────
  // FORMAT HARGA: 150000 → 150.000
  // ─────────────────────────────────
  String _formatPrice(dynamic price) {
    if (price == null) return '-';
    final num = int.tryParse(price.toString()) ?? 0;
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

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ────────────────────────────────────────────
  // DELETE PRODUCT — dengan konfirmasi dialog
  // ────────────────────────────────────────────
  Future<void> _deleteProduct() async {
    final confirmed = await _showConfirmDialog(
      title: "Hapus Produk?",
      subtitle:
          "Semua variant dari produk ini juga akan ikut terhapus. Tindakan ini tidak bisa dibatalkan.",
      confirmLabel: "Hapus",
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.redAccent,
    );
    if (confirmed != true) return;

    setState(() => _isDeletingProduct = true);
    try {
      await service.deleteProduct(product['id']);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingProduct = false);
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ────────────────────────────────────────────
  // DELETE VARIANT — dengan konfirmasi dialog
  // ────────────────────────────────────────────
  Future<void> _deleteVariant(String id) async {
    final confirmed = await _showConfirmDialog(
      title: "Hapus Variant?",
      subtitle: "Variant ini akan dihapus permanen.",
      confirmLabel: "Hapus",
      icon: Icons.remove_circle_outline_rounded,
      iconColor: Colors.redAccent,
    );
    if (confirmed != true) return;

    try {
      await service.deleteVariant(id);
      if (!mounted) return;
      setState(() {
        (product['product_variants'] as List)
            .removeWhere((v) => v['id'] == id);
      });
      _showSnackBar('Variant berhasil dihapus', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ────────────────────────────────────────────
  // REUSABLE CONFIRM DIALOG — glassmorphism
  // ────────────────────────────────────────────
  Future<bool?> _showConfirmDialog({
    required String title,
    required String subtitle,
    required String confirmLabel,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF111124), const Color(0xFF0A0A14)]
                  : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: iconColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            confirmLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variants =
        List<Map>.from(product['product_variants'] ?? []);

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0A0A14),
                    const Color(0xFF111124),
                    theme.colorScheme.primary.withValues(alpha: 0.18),
                  ]
                : [
                    Colors.white,
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // ──────────────────────────────
                  // CUSTOM APPBAR
                  // ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
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
                          "Detail Produk",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        // Tombol hapus produk
                        GestureDetector(
                          onTap:
                              _isDeletingProduct ? null : _deleteProduct,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent
                                  .withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: _isDeletingProduct
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ──────────────────────────────
                  // SCROLLABLE CONTENT
                  // ──────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─────────────────────
                          // HERO PRODUK
                          // ─────────────────────
                          _buildHeroCard(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // SECTION VARIANT
                          // ─────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _sectionLabel(
                                    "SUBSCRIPTION TIERS", theme),
                              ),
                              // Hint longpress
                              Text(
                                "tahan untuk hapus",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ─────────────────────
                          // VARIANT LIST
                          // ─────────────────────
                          if (variants.isEmpty)
                            _buildEmptyVariant(theme, isDark)
                          else
                            ...variants.map((v) =>
                                _buildVariantCard(context, v, theme, isDark)),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // INFO BOX
                          // ─────────────────────
                          _buildInfoBox(theme, isDark),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM — TAMBAH VARIANT
                  // ──────────────────────────────
                  _buildBottomBar(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // HERO PRODUCT CARD
  // ────────────────────────────────────────────
  Widget _buildHeroCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo produk
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.grey.shade100,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              product['image'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            product['name'] ?? '-',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            product['description'] ?? '-',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats: jumlah variant
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 15,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                "${(product['product_variants'] as List?)?.length ?? 0} Variant tersedia",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/admin-edit-product',
                  arguments: product,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                    border: Border.all(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Edit Produk",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // VARIANT CARD — tap edit, long press delete
  // ────────────────────────────────────────────
  Widget _buildVariantCard(
      BuildContext context, Map v, ThemeData theme, bool isDark) {
    final price = _formatPrice(v['price']);
    final days = v['duration_days']?.toString() ?? '-';
    final type = v['type']?.toString() ?? '-';

    final badgeColor = _getBadgeColor(v['duration_days'], theme);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/admin-add-variant',
        arguments: {...product, "variant": v},
      ),
      onLongPress: () => _deleteVariant(v['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon tier
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: badgeColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 22,
                color: badgeColor,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "$days Hari",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: badgeColor.withValues(alpha: 0.12),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap untuk edit • Tahan untuk hapus",
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),

            // Harga
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rp $price",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(dynamic days, ThemeData theme) {
    final d = int.tryParse(days?.toString() ?? '0') ?? 0;
    if (d >= 365) return Colors.amber;
    if (d >= 30) return theme.colorScheme.primary;
    return Colors.green;
  }

  // ────────────────────────────────────────────
  // EMPTY STATE VARIANT
  // ────────────────────────────────────────────
  Widget _buildEmptyVariant(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            "Belum ada variant",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tambahkan variant pertama di bawah",
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // INFO BOX
  // ────────────────────────────────────────────
  Widget _buildInfoBox(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Semua subscription diverifikasi untuk stabilitas.\nDukungan 24/7 tersedia untuk semua tier.",
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM BAR — tambah variant
  // ────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0A0A14).withValues(alpha: 0.0),
                  const Color(0xFF0A0A14),
                ]
              : [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white,
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/admin-add-variant',
          arguments: product,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: isDark ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                "Tambah Variant",
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // SECTION LABEL — uppercase konsisten
  // ────────────────────────────────────────────
  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: theme.colorScheme.primary.withValues(alpha: 0.75),
      ),
    );
  }
}
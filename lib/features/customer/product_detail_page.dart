import 'package:flutter/material.dart';
import '../../core/constants.dart';


class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> variants;
  int selectedIndex = 0;
  late Map product;

  // ✅ Animasi konsisten dengan EditProfilePage
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Map;
    variants = List<Map<String, dynamic>>.from(
      product['product_variants'] ?? [],
    );
    // Animasi mulai setelah data siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = product['name'] ?? '-';
    final image = product['image'];
    final description = product['description'] ?? '-';

    final selectedVariant =
        variants.isNotEmpty ? variants[selectedIndex] : null;
    final selectedPrice = selectedVariant != null
        ? 'Rp ${_formatPrice(selectedVariant['price'])}'
        : '-';

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
                      horizontal: 24,
                      vertical: 16,
                    ),
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
                        // Bookmark button
                        Container(
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
                            Icons.bookmark_border_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─────────────────────
                          // HERO SECTION
                          // ─────────────────────
                          _buildHeroSection(
                              context, image, title, description, isDark, theme),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // TAGS
                          // ─────────────────────
                          _buildTags(context, theme),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // STATS ROW
                          // ─────────────────────
                          _buildStatsRow(context, theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // SECTION LABEL
                          // ─────────────────────
                          _sectionLabel("PILIH PAKET", theme),
                          const SizedBox(height: 12),

                          // ─────────────────────
                          // VARIANT CARDS
                          // ─────────────────────
                          ...List.generate(variants.length, (index) {
                            return _buildVariantCard(
                                context, index, theme, isDark);
                          }),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM ORDER SECTION
                  // ──────────────────────────────
                  _buildBottomBar(
                      context, theme, isDark, selectedPrice, selectedVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // HERO SECTION — logo besar + info produk
  // ────────────────────────────────────────────
  Widget _buildHeroSection(
    BuildContext context,
    dynamic image,
    String title,
    String description,
    bool isDark,
    ThemeData theme,
  ) {
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
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
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
          // Aura + Logo
          Stack(
            alignment: Alignment.center,
            children: [
              // Aura luar (pulse animation)
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Logo container
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
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white,
                ),
                clipBehavior: Clip.hardEdge,
                child: image != null
                    ? Image.network(image, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Judul produk
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 8),

          // Deskripsi
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // TAGS
  // ────────────────────────────────────────────
  Widget _buildTags(BuildContext context, ThemeData theme) {
    final tags = [
      (Icons.verified_outlined, "Premium"),
      (Icons.bolt_outlined, "Fast Delivery"),
      (Icons.shield_outlined, "Warranty"),
    ];

    return Row(
      children: tags.map((tag) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: tags.indexOf(tag) < tags.length - 1 ? 8 : 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  tag.$1,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  tag.$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ────────────────────────────────────────────
  // STATS ROW — rating, users, uptime
  // ────────────────────────────────────────────
  Widget _buildStatsRow(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(context, theme, "4.9", "Rating", Icons.star_rounded,
              Colors.amber),
          _dividerV(theme),
          _statItem(context, theme, "12K+", "Users",
              Icons.people_outline_rounded, theme.colorScheme.primary),
          _dividerV(theme),
          _statItem(context, theme, "99.9%", "Uptime",
              Icons.cloud_done_outlined, Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, ThemeData theme, String value,
      String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _dividerV(ThemeData theme) {
    return Container(
      height: 40,
      width: 0.5,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
    );
  }

  // ────────────────────────────────────────────
  // VARIANT CARD — glassmorphism + selected glow
  // ────────────────────────────────────────────
  Widget _buildVariantCard(
      BuildContext context, int index, ThemeData theme, bool isDark) {
    final v = variants[index];
    final isSelected = selectedIndex == index;
    final price = _formatPrice(v['price']);
    final days = v['duration_days']?.toString() ?? '-';
    final type = v['type'] ?? '-';

    // Badge warna berdasarkan durasi
    final badgeColor = _getBadgeColor(v['duration_days'], theme);

    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isSelected
                ? isDark
                    ? [
                        theme.colorScheme.primary.withValues(alpha: 0.22),
                        theme.colorScheme.secondary.withValues(alpha: 0.12),
                      ]
                    : [
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                        theme.colorScheme.secondary.withValues(alpha: 0.05),
                      ]
                : isDark
                    ? [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.6)
                : isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Lingkaran pilih ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  width: 2,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 14),

            // ── Keterangan durasi & tipe ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "$days Hari",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge tipe
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: badgeColor.withValues(alpha: 0.15),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 10,
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
                    "Akses penuh · Garansi aktif",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            // ── Harga ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rp $price",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "/ periode",
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
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
  // BOTTOM ORDER BAR
  // ────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String price,
    Map<String, dynamic>? selectedVariant,
  ) {
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
      child: Row(
        children: [
          // Harga selected
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TOTAL HARGA",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    price,
                    key: ValueKey(price),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Tombol order
          GestureDetector(
            onTap: () {
              if (selectedVariant == null) return;
              Navigator.pushNamed(
                context,
                '/checkout',
                arguments: {
                  "product": product,
                  "variant": selectedVariant,
                },
              );
            },
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 28),
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
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Order Now",
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // SECTION LABEL — uppercase, konsisten Edit
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
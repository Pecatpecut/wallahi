import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../core/constants.dart';

class AdminMarketPage extends StatefulWidget {
  const AdminMarketPage({super.key});

  @override
  State<AdminMarketPage> createState() => _AdminMarketPageState();
}

class _AdminMarketPageState extends State<AdminMarketPage>
    with SingleTickerProviderStateMixin {
  final productService = ProductService();

  List products = [];
  bool isLoading = true;
  String selectedCategory = "All";
  String searchQuery = "";

  final categories = ["All", "Streaming", "Music", "Study", "Editing"];

  // ✅ Warna per kategori — konsisten di chip + card badge
  final Map<String, Color> _catColor = {
    "Streaming": const Color(0xFFAFA9EC),
    "Music": const Color(0xFF5DCAA5),
    "Study": const Color(0xFFEF9F27),
    "Editing": const Color(0xFFF09595),
  };

  // ✅ Animasi fade+slide — identik dengan halaman lain
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _fetch();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ✅ Backend tidak diubah — sama seperti aslinya
  Future<void> _fetch() async {
    final data = await productService.getProducts();
    if (!mounted) return;
    setState(() {
      products = data;
      isLoading = false;
    });
    _animController.forward();
  }

  // ✅ Logic filter tidak diubah
  List get filteredProducts {
    return products.where((p) {
      final matchCategory =
          selectedCategory == "All" || p['category'] == selectedCategory;
      final matchSearch = (p['name'] ?? "")
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      // ✅ FAB tetap ada — hanya style dipercantik
      floatingActionButton: _fab(theme, isDark),
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
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _topBar(theme),
                          const SizedBox(height: 18),
                          _pageHeader(theme),
                          const SizedBox(height: 16),
                          _searchBox(theme, isDark),
                          const SizedBox(height: 14),
                          _filterChips(theme),
                          const SizedBox(height: 20),
                          _sectionLabel(theme),
                          const SizedBox(height: 12),
                          ...filteredProducts.map((p) => _card(p, theme, isDark)),
                          if (filteredProducts.isEmpty) _emptyState(theme),
                          const SizedBox(height: 80), // ruang FAB
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────

  Widget _fab(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/admin-add-product');
        // ✅ FIX: refresh list produk setelah kembali dari halaman tambah produk
        _fetch();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
        child: Icon(
          Icons.add_rounded,
          color: isDark ? Colors.black : Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _topBar(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "ARNN.APPREM",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.person_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _pageHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ADMIN PANEL",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Kelola Produk",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "${products.length} item tersedia di katalog",
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ✅ Search — style identik dengan GaransiPage
  Widget _searchBox(ThemeData theme, bool isDark) {
    return TextField(
      onChanged: (v) => setState(() => searchQuery = v),
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Cari produk...",
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ✅ Chips — dengan warna per kategori
  Widget _filterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((c) {
          final isActive = selectedCategory == c;
          final catCol = _catColor[c] ?? theme.colorScheme.primary;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isActive
                    ? (c == "All"
                        ? theme.colorScheme.primary
                        : catCol.withValues(alpha: 0.85))
                    : catCol.withValues(alpha: 0.1),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : catCol.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : catCol,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme) {
    final label = selectedCategory == "All" ? "Semua Produk" : selectedCategory;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: theme.colorScheme.primary.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Text(
            "${filteredProducts.length} item",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  // PRODUCT CARD — glass card konsisten
  // ─────────────────────────────────────
  Widget _card(Map p, ThemeData theme, bool isDark) {
    final catCol = _catColor[p['category']] ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/admin-product-detail',
        arguments: p,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ROW ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar produk
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: catCol.withValues(alpha: 0.2),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    p['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      size: 26,
                      color: catCol.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: catCol.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          (p['category'] ?? "").toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                            color: catCol,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        p['name'] ?? '–',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p['description'] ?? '–',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 12),

            // ── FOOTER ROW ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Harga — jika tersedia di data
                if (p['price'] != null)
                  Text(
                    p['price'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  const SizedBox(),

                Row(
                  children: [

                    // ✅ Tombol detail — gradient button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Detail",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "Tidak ada produk ditemukan",
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
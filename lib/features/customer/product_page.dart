import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/navbar/bottom_navbar.dart';
import '../../widgets/cards/premium_product_tile.dart';
import '../../services/product_service.dart';


class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  final productService = ProductService();

  String _searchQuery = "";
  String _selectedCategory = "All";
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  // ✅ Animasi konsisten
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _categories = [
    "All",
    "Streaming",
    "Music",
    "Study",
    "Editing",
  ];

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
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fetchProducts();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final data = await productService.getProducts(
        category:
            _selectedCategory == "All" ? null : _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        products = data;
        isLoading = false;
      });
      _animController
        ..reset()
        ..forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _fetchProducts();
  }

  // Ambil harga terendah dari semua variant
  String? _getLowestPrice(Map product) {
    final variants =
        List<Map>.from(product['product_variants'] ?? []);
    if (variants.isEmpty) return null;
    final prices = variants
        .map((v) => int.tryParse(v['price']?.toString() ?? '') ?? 0)
        .where((p) => p > 0)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first.toString();
  }

  String _getSubtitle(Map product) {
    final variants =
        List<Map>.from(product['product_variants'] ?? []);
    if (variants.isEmpty) return "Tidak ada paket";
    final v = variants[0];
    return "${v['duration_days']} Hari • ${v['type'] ?? '-'}";
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      final name = (p['name'] ?? '').toLowerCase();
      final category = (p['category'] ?? '').toLowerCase();
      return name.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ──────────────────────────────
              // HEADER SECTION
              // ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branding row
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.blur_on,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "INIARNN.APPREM",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        // Jumlah produk
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: !isLoading
                              ? Container(
                                  key: ValueKey(
                                      _filteredProducts.length),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    "${_filteredProducts.length} produk",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      "Premium\nModules",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Pilih subscription premium favoritmu",
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Search bar
                    _buildSearchBar(theme, isDark),

                    const SizedBox(height: 16),

                    // Category chips
                    _buildCategoryChips(theme, isDark),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ──────────────────────────────
              // PRODUCT LIST
              // ──────────────────────────────
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    24, 0, 24, 16),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product =
                                      _filteredProducts[index];
                                  return PremiumProductTile(
                                    title: product['name'] ?? '-',
                                    subtitle: _getSubtitle(product),
                                    imageUrl: product['image'],
                                    price: _getLowestPrice(product),
                                    category: product['category'],
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/detail',
                                      arguments: product,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // SEARCH BAR — konsisten EditProfilePage
  // ────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (val) =>
          setState(() => _searchQuery = val.toLowerCase()),
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: "Cari subscription...",
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.4),
                ),
              )
            : null,
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
          vertical: 14,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // CATEGORY CHIPS
  // ────────────────────────────────────────────
  Widget _buildCategoryChips(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isActive = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => _onCategoryChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      )
                    : null,
                color: isActive
                    ? null
                    : isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.grey.shade100,
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────────────────
  // EMPTY STATE
  // ────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    final isSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 32,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? "Produk tidak ditemukan"
                : "Belum ada produk",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? "Coba kata kunci yang berbeda"
                : "Produk akan muncul di sini",
            style: TextStyle(
              fontSize: 12,
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          if (isSearch) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  "Hapus pencarian",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
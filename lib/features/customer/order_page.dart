import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/navbar/bottom_navbar.dart';
import '../../widgets/cards/order_card.dart';
import '../../services/order_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  final _orderService = OrderService();

  List _orders = [];
  List _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedFilter = 'all';
  final _searchController = TextEditingController();

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
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetchOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _orderService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = data;
        _filteredOrders = data;
        _isLoading = false;
      });
      _applyFilter();
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final query = _searchController.text.toLowerCase();

    final temp = _orders.where((order) {
      final status = (order['status'] ?? 'pending').toString();
      final createdAt =
          DateTime.tryParse(order['created_at'] ?? '') ?? now;
      final duration = order['duration_days'] ?? 30;
      final endDate = createdAt.add(Duration(days: duration));
      int remaining = endDate.difference(now).inDays;
      if (remaining < 0) remaining = 0;

      final isActive = status == 'approved' && remaining > 0;
      final isPending = status == 'pending';
      final isExpired = status == 'approved' && remaining == 0;
      // ✅ Tambah rejected
      final isRejected = status == 'rejected';

      final matchFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && isActive) ||
          (_selectedFilter == 'pending' && isPending) ||
          (_selectedFilter == 'expired' && isExpired) ||
          (_selectedFilter == 'rejected' && isRejected);

      final name =
          (order['product_name'] ?? '').toString().toLowerCase();
      final matchSearch = query.isEmpty || name.contains(query);

      return matchFilter && matchSearch;
    }).toList();

    setState(() => _filteredOrders = temp);
  }

  int _countByFilter(String filter) {
    if (filter == 'all') return _orders.length;
    final now = DateTime.now();
    return _orders.where((order) {
      final status = (order['status'] ?? 'pending').toString();
      final createdAt =
          DateTime.tryParse(order['created_at'] ?? '') ?? now;
      final duration = order['duration_days'] ?? 30;
      final endDate = createdAt.add(Duration(days: duration));
      int remaining = endDate.difference(now).inDays;
      if (remaining < 0) remaining = 0;
      if (filter == 'active') return status == 'approved' && remaining > 0;
      if (filter == 'pending') return status == 'pending';
      if (filter == 'expired') return status == 'approved' && remaining == 0;
      if (filter == 'rejected') return status == 'rejected';
      return false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavbar(currentIndex: 2),
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
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header (fixed, tidak scroll)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Navbar row
                    Row(
                      children: [
                        Icon(Icons.blur_on,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          "INIARNN.APPREM",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isLoading ? null : _fetchOrders,
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
                            child: _isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(Icons.refresh_rounded,
                                    size: 18, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Judul + count
                    Row(
                      children: [
                        Text(
                          "Riwayat Order",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_orders.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                            ),
                            child: Text(
                              "${_orders.length}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Search bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _applyFilter(),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: "Cari order...",
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _applyFilter();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.close_rounded,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4)),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ✅ Filter chips — SingleChildScrollView agar tidak overflow
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _filterChip('all', 'Semua', null, theme, isDark),
                          const SizedBox(width: 8),
                          _filterChip('active', 'Aktif', Colors.green,
                              theme, isDark),
                          const SizedBox(width: 8),
                          _filterChip('pending', 'Pending', Colors.orange,
                              theme, isDark),
                          const SizedBox(width: 8),
                          _filterChip('expired', 'Expired', Colors.redAccent,
                              theme, isDark),
                          const SizedBox(width: 8),
                          // ✅ Tab Rejected untuk user
                          _filterChip('rejected', 'Ditolak',
                              Colors.grey, theme, isDark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ── List content (scrollable)
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _errorMessage != null
                        ? _errorState(theme, isDark)
                        : _orders.isEmpty
                            ? _emptyState(theme, isDark)
                            : _filteredOrders.isEmpty
                                ? _noResultState(theme)
                                : FadeTransition(
                                    opacity: _fadeAnim,
                                    child: SlideTransition(
                                      position: _slideAnim,
                                      child: ListView.builder(
                                        physics:
                                            const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 100),
                                        itemCount: _filteredOrders.length,
                                        itemBuilder: (_, i) =>
                                            PremiumOrderCard(
                                          data: _filteredOrders[i],
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/order-detail',
                                            arguments: _filteredOrders[i],
                                          ),
                                        ),
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

  // ── Widget helpers ────────────────────────────────────────────────

  Widget _filterChip(
    String value,
    String label,
    Color? color,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == value;
    final count = _countByFilter(value);
    final chipColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: color != null
                      ? [color, color.withValues(alpha: 0.7)]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (count > 0 && !isSelected) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: chipColor.withValues(alpha: 0.15),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 40,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              "Belum Ada Order",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              "Kamu belum melakukan pembelian.\nYuk beli produk premium sekarang!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/products'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius),
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Lihat Produk →",
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResultState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            "Tidak ada hasil",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 4),
          Text(
            "Coba ubah filter atau kata kunci",
            style: TextStyle(
                fontSize: 12,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.wifi_off_outlined,
                  size: 36, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Order",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? "Terjadi kesalahan",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchOrders,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius),
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Coba Lagi",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
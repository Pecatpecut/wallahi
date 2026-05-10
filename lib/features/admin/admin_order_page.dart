import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/order_service.dart';

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage>
    with TickerProviderStateMixin {
  final OrderService _service = OrderService();

  List _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _sortOrder = 'newest';

  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getAllOrders();
      if (!mounted) return;
      setState(() {
        _orders = data;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List _getByStatus(String status) {
    final filtered =
        _orders.where((o) => o['status'] == status).toList();
    filtered.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final dateB =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return _sortOrder == 'newest'
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });
    return filtered;
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
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _approveDialog(Map order) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              // ✅ insetPadding agar dialog tidak terlalu lebar di HP besar
              insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppConstants.darkBg2,
                            const Color(0xFF23233A),
                          ]
                        : [Colors.white, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            Icons.key_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // ✅ Flexible agar teks tidak overflow
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Input Akun",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                order['product_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _dialogLabel("EMAIL AKUN", theme),
                    _dialogInput(
                      "email@example.com",
                      controller: emailController,
                      icon: Icons.mail_outline,
                      theme: theme,
                      isDark: isDark,
                      inputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _dialogLabel("PASSWORD AKUN", theme),
                    _dialogInput(
                      "••••••••",
                      controller: passwordController,
                      icon: Icons.lock_outline,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isSaving
                                ? null
                                : () => Navigator.pop(ctx),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radius),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Batal",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: isSaving
                                ? null
                                : () async {
                                    if (emailController.text
                                            .trim()
                                            .isEmpty ||
                                        passwordController.text
                                            .trim()
                                            .isEmpty) {
                                      _showSnackBar(
                                          "Email & password wajib diisi",
                                          isError: true);
                                      return;
                                    }
                                    setDialogState(
                                        () => isSaving = true);
                                    try {
                                      await _service.approveOrderManual(
                                        orderId: order['id'],
                                        email:
                                            emailController.text.trim(),
                                        password: passwordController.text
                                            .trim(),
                                      );
                                      if (!mounted) return;
                                      Navigator.pop(ctx);
                                      _showSnackBar(
                                          "Order berhasil di-approve!",
                                          isError: false);
                                      _fetch();
                                    } catch (e) {
                                      if (!mounted) return;
                                      setDialogState(
                                          () => isSaving = false);
                                      _showSnackBar(
                                          e.toString().replaceAll(
                                              'Exception: ', ''),
                                          isError: true);
                                    }
                                  },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radius),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Approve",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
            );
          },
        );
      },
    );
  }

  void _rejectDialog(Map order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppConstants.darkBg2, const Color(0xFF23233A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.cancel_outlined,
                    size: 28, color: Colors.redAccent),
              ),
              const SizedBox(height: 14),
              Text(
                "Tolak Order?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              // ✅ Flexible teks panjang
              Text(
                "Order ${order['product_name']} akan ditolak.\nTindakan ini tidak bisa dibatalkan.",
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radius),
                          border: Border.all(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _service.updateOrderStatus(
                              order['id'], 'rejected');
                          if (!mounted) return;
                          _showSnackBar("Order ditolak",
                              isError: false);
                          _fetch();
                        } catch (e) {
                          if (!mounted) return;
                          _showSnackBar(
                              e.toString().replaceAll('Exception: ', ''),
                              isError: true);
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radius),
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Tolak",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

    final pendingCount = _getByStatus('pending').length;
    final approvedCount = _getByStatus('approved').length;
    final rejectedCount = _getByStatus('rejected').length;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    AppConstants.darkBg1,
                    AppConstants.darkBg2,
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
          child: Column(
            children: [
              // ── APPBAR ──
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
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 16,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Order Management",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isLoading ? null : _fetch,
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
                                size: 18,
                                color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── STATS ──
              if (!_isLoading && _errorMessage == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _statChip(
                          label: "Pending",
                          count: pendingCount,
                          color: Colors.orange,
                          isDark: isDark),
                      const SizedBox(width: 8),
                      _statChip(
                          label: "Approved",
                          count: approvedCount,
                          color: Colors.green,
                          isDark: isDark),
                      const SizedBox(width: 8),
                      _statChip(
                          label: "Rejected",
                          count: rejectedCount,
                          color: Colors.redAccent,
                          isDark: isDark),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ── TAB BAR ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: isDark ? Colors.black : Colors.white,
                    unselectedLabelColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    tabs: [
                      _tabItem("Pending", pendingCount, Colors.orange),
                      _tabItem(
                          "Approved", approvedCount, Colors.green),
                      _tabItem(
                          "Rejected", rejectedCount, Colors.redAccent),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── SORT TOGGLE ──
              if (!_isLoading && _errorMessage == null)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 6),
                      Text(
                        "Urutkan:",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _sortChip(
                        label: "Terbaru",
                        value: "newest",
                        icon: Icons.arrow_downward_rounded,
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _sortChip(
                        label: "Terlama",
                        value: "oldest",
                        icon: Icons.arrow_upward_rounded,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── CONTENT ──
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
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildList(
                                      _getByStatus('pending'),
                                      'pending',
                                      theme,
                                      isDark),
                                  _buildList(
                                      _getByStatus('approved'),
                                      'approved',
                                      theme,
                                      isDark),
                                  _buildList(
                                      _getByStatus('rejected'),
                                      'rejected',
                                      theme,
                                      isDark),
                                ],
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

  // ─────────────────────────────────────
  // BUILD LIST — ✅ SingleChildScrollView wrapping ListView
  // ─────────────────────────────────────
  Widget _buildList(
      List data, String status, ThemeData theme, bool isDark) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.hourglass_empty_outlined
                  : status == 'approved'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 44,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              "Tidak ada order $status",
              style: TextStyle(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ ListView dengan physics bouncing + shrinkWrap false
    // Tidak perlu SingleChildScrollView karena ListView sudah scrollable
    // Key: pastikan padding bawah cukup agar card terakhir tidak terpotong
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      itemCount: data.length,
      itemBuilder: (_, i) => _orderCard(data[i], theme, isDark),
    );
  }

  // ─────────────────────────────────────
  // ORDER CARD — semua Row di-fix overflow
  // ─────────────────────────────────────
  Widget _orderCard(Map order, ThemeData theme, bool isDark) {
    final status = order['status'] ?? 'pending';
    final isApproved = status == 'approved';
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
          color: isDark
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
      // ✅ GestureDetector di luar container agar tap area full
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.pushNamed(
          context,
          '/admin-order-detail',
          arguments: order,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ min agar tidak expand berlebihan
          children: [

            // ── Baris atas: icon + nama + badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                // ✅ Expanded agar nama produk tidak push badge keluar
                Expanded(
                  child: Text(
                    order['product_name'] ?? '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ Badge tidak di-Expanded — ukurannya intrinsic
                _statusBadge(status, theme),
              ],
            ),

            const SizedBox(height: 12),

            // ── Info chips: variant + harga ──
            // ✅ Wrap agar tidak overflow jika teks panjang
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip(
                  Icons.layers_outlined,
                  order['variant_type'] ?? '-',
                  theme,
                  isDark,
                ),
                _infoChip(
                  Icons.payments_outlined,
                  "Rp ${order['price'] ?? 0}",
                  theme,
                  isDark,
                  isHighlight: true,
                ),
              ],
            ),

            // ── Tanggal ──
            if (order['created_at'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 4),
                  // ✅ Flexible agar tanggal tidak overflow
                  Flexible(
                    child: Text(
                      _formatOrderDate(order['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // ── Account email (approved) ──
            if (isApproved && order['account_email'] != null) ...[
              const SizedBox(height: 12),
              Divider(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.07),
                height: 1,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.mail_outline,
                      size: 13,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  // ✅ Flexible agar email panjang tidak overflow
                  Flexible(
                    child: Text(
                      order['account_email'],
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // ── Action buttons (pending only) ──
            if (isPending) ...[
              const SizedBox(height: 14),
              Divider(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.07),
                height: 1,
              ),
              const SizedBox(height: 10),
              // ✅ Row dengan MainAxisAlignment.end — tombol tidak perlu Expanded
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Reject
                  GestureDetector(
                    onTap: () => _rejectDialog(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radius),
                        border: Border.all(
                          color:
                              Colors.redAccent.withValues(alpha: 0.4),
                        ),
                        color: Colors.redAccent.withValues(alpha: 0.07),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.close,
                              size: 14, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(
                            "Tolak",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Approve
                  GestureDetector(
                    onTap: () => _approveDialog(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radius),
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
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "Approve",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────

  Widget _tabItem(String label, int count, Color dotColor) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: dotColor.withValues(alpha: 0.25),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: dotColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: isDark ? 0.1 : 0.07),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _sortOrder == value;
    return GestureDetector(
      onTap: () => setState(() => _sortOrder = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ])
              : null,
          color: isSelected
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade100,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
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
              "Gagal Memuat Data",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? "Terjadi kesalahan",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetch,
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

  String _formatOrderDate(String? raw) {
    if (raw == null) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return '-';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return "${date.day} ${months[date.month - 1]} ${date.year}, $h:$m";
  }

  Widget _statusBadge(String status, ThemeData theme) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = "Approved";
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = "Rejected";
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.orange;
        label = "Pending";
        icon = Icons.hourglass_empty_outlined;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label,
    ThemeData theme,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        border: Border.all(
          color: isHighlight
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ✅ intrinsic width
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 5),
          // ✅ ConstrainedBox agar chip tidak terlalu lebar
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isHighlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: theme.colorScheme.primary.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _dialogInput(
    String hint, {
    required TextEditingController controller,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style:
          TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color:
              theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(icon,
            size: 18,
            color:
                theme.colorScheme.primary.withValues(alpha: 0.6)),
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.radius),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}
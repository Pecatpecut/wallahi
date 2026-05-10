import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/claims_service.dart';

class AdminGaransiPage extends StatefulWidget {
  const AdminGaransiPage({super.key});

  @override
  State<AdminGaransiPage> createState() => _AdminGaransiPageState();
}

class _AdminGaransiPageState extends State<AdminGaransiPage>
    with SingleTickerProviderStateMixin {
  final ClaimsService _service = ClaimsService();

  List claims = [];
  bool isLoading = true;
  String selectedFilter = "all";
  String searchQuery = "";

  // ✅ Warna status konsisten di seluruh halaman
  final Map<String, Color> _statusColor = {
    "pending":     const Color(0xFFEF9F27),
    "in_progress": const Color(0xFFAFA9EC),
    "approved":    const Color(0xFF5DCAA5),
    "rejected":    const Color(0xFFF09595),
  };
  final Map<String, String> _statusLabel = {
    "pending":     "Pending",
    "in_progress": "In Progress",
    "approved":    "Approved",
    "rejected":    "Rejected",
  };

  // ✅ Animasi fade+slide identik dengan semua halaman lain
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

  // ✅ Backend tidak diubah
  Future<void> _fetch() async {
    try {
      final data = await _service.getClaims();
      if (!mounted) return;
      setState(() {
        claims = data;
        isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      debugPrint("ERROR GARANSI: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ✅ Logic filter tidak diubah — tambah search by title
  List get filteredClaims {
    return claims.where((c) {
      final statusMatch =
          selectedFilter == "all" || c['status'] == selectedFilter;
      final searchMatch =
          (c['orders']?['product_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          (c['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
  }

  // ── Stat helpers ──
  int get _totalPending  => claims.where((c) => c['status'] == 'pending').length;
  int get _totalApproved => claims.where((c) => c['status'] == 'approved').length;
  int get _totalRejected => claims.where((c) => c['status'] == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                          _statStrip(theme, isDark),
                          const SizedBox(height: 16),
                          _searchBox(theme, isDark),
                          const SizedBox(height: 14),
                          _filterChips(theme),
                          const SizedBox(height: 20),
                          _sectionLabel(theme),
                          const SizedBox(height: 12),
                          if (filteredClaims.isEmpty)
                            _emptyState(theme)
                          else
                            ...filteredClaims.map((c) => _card(c, theme, isDark)),
                          const SizedBox(height: 30),
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

  Widget _sectionLabel(ThemeData theme) {
    final lbl = selectedFilter == "all"
        ? "Semua Klaim"
        : _statusLabel[selectedFilter] ?? selectedFilter;
    return Row(
      children: [
        Text(
          lbl.toUpperCase(),
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
            "${filteredClaims.length} item",
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

  BoxDecoration _glassCard(ThemeData theme, bool isDark) => BoxDecoration(
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
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 8))],
      );

  // ── TOPBAR ──
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
              child: Icon(Icons.grid_view_rounded,
                  color: theme.colorScheme.primary, size: 20),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.person_outline,
              size: 20, color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  // ── PAGE HEADER ──
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
          "Warranty Claims",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "${claims.length} klaim masuk",
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── STAT STRIP ──
  Widget _statStrip(ThemeData theme, bool isDark) {
    final stats = [
      {"label": "Total",    "value": "${claims.length}", "color": theme.colorScheme.onSurface},
      {"label": "Pending",  "value": "$_totalPending",   "color": const Color(0xFFEF9F27)},
      {"label": "Approved", "value": "$_totalApproved",  "color": const Color(0xFF5DCAA5)},
      {"label": "Rejected", "value": "$_totalRejected",  "color": const Color(0xFFF09595)},
    ];

    return Row(
      children: stats.map((s) {
        final color = s["color"] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stats.last == s ? 0 : 8,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              border: Border.all(
                color: color.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Text(
                  s["value"] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (s["label"] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── SEARCH ──
  Widget _searchBox(ThemeData theme, bool isDark) {
    return TextField(
      onChanged: (v) => setState(() => searchQuery = v),
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Cari produk atau user...",
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(Icons.search, size: 18,
            color: theme.colorScheme.primary.withValues(alpha: 0.6)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ── FILTER CHIPS ──
  Widget _filterChips(ThemeData theme) {
    final filters = [
      {"label": "Semua",       "value": "all",         "color": theme.colorScheme.primary},
      {"label": "Pending",     "value": "pending",     "color": const Color(0xFFEF9F27)},
      {"label": "In Progress", "value": "in_progress", "color": const Color(0xFFAFA9EC)},
      {"label": "Approved",    "value": "approved",    "color": const Color(0xFF5DCAA5)},
      {"label": "Rejected",    "value": "rejected",    "color": const Color(0xFFF09595)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isActive = selectedFilter == f["value"];
          final col = f["color"] as Color;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = f["value"] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isActive ? col.withValues(alpha: 0.85) : col.withValues(alpha: 0.1),
                border: Border.all(
                  color: isActive ? Colors.transparent : col.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                f["label"] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : col,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CLAIM CARD ──
  Widget _card(Map c, ThemeData theme, bool isDark) {
    final status = c['status'] ?? 'pending';
    final order  = c['orders'] ?? {};
    final statusCol = _statusColor[status] ?? Colors.grey;
    final userName  = c['users']?['name'] ?? 'User';
    // Ambil inisial dari nama user
    final initials  = userName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .substring(0, userName.split(' ').length >= 2 ? 2 : 1)
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _glassCard(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER ROW ──
          Row(
            children: [
              // Avatar inisial user
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['product_name'] ?? 'Unknown Product',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${order['variant_type'] ?? '–'} · $userName",
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── STATUS BADGE ── (diperbarui, bukan _statusBadge lama)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: statusCol.withValues(alpha: 0.15),
                ),
                child: Text(
                  _statusLabel[status] ?? status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusCol,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── JUDUL KLAIM ──
          Text(
            c['title'] ?? '–',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          // ── PROBLEM BOX ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
              ),
            ),
            child: Text(
              c['problem_description'] ?? '–',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),

          // ── BUKTI FOTO ──
          if (c['proof_image'] != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                c['proof_image'],
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(
                        "Bukti foto tersedia",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
          const SizedBox(height: 12),

          // ── FOOTER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User info + tanggal
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(Icons.person_outline,
                        size: 14, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$userName · ${c['created_at']?.toString().substring(0, 10) ?? '–'}",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ✅ Action button — gradient konsisten
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/admin-garansi-detail',
                  arguments: c,
                ),
                child: Container(
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
                        "Tindakan",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
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

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              "Tidak ada klaim ditemukan",
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
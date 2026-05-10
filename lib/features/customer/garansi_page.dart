import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../services/claims_service.dart';
import '../../widgets/shared/status_badge.dart';

class GaransiPage extends StatefulWidget {
  const GaransiPage({super.key});

  @override
  State<GaransiPage> createState() => _GaransiPageState();
}

class _GaransiPageState extends State<GaransiPage>
    with SingleTickerProviderStateMixin {
  final ClaimsService service = ClaimsService();

  List claims = [];
  List filteredClaims = [];
  bool isLoading = true;
  String search = "";
  String selectedFilter = "all";

  // ✅ Animasi fade + slide — konsisten dengan EditProfilePage
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
    _fetchClaims();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaims() async {
    final data = await service.getUserClaims();
    if (!mounted) return;
    setState(() {
      claims = data;
      filteredClaims = data;
      isLoading = false;
    });
    _animController.forward(); // ✅ animasi mulai setelah data masuk
  }

  void _applyFilter() {
    List temp = claims;
    if (selectedFilter != "all") {
      temp = temp.where((c) => c['status'] == selectedFilter).toList();
    }
    if (search.isNotEmpty) {
      temp = temp
          .where((c) =>
              (c['problem_description'] ?? '')
                  .toLowerCase()
                  .contains(search.toLowerCase()) ||
              (c['title'] ?? '')
                  .toLowerCase()
                  .contains(search.toLowerCase()))
          .toList();
    }
    setState(() => filteredClaims = temp);
  }

  int get total => claims.length;
  int get inProgress =>
      claims.where((c) => c['status'] == 'pending').length;
  int get resolved =>
      claims.where((c) => c['status'] == 'approved').length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // ✅ Gradient background — sama persis dengan EditProfilePage
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
                    child: Column(
                      children: [
                        // ─────────────────────────────
                        // APPBAR CUSTOM — sama dengan EditProfilePage
                        // ─────────────────────────────
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
                                "Garansi Saya",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 38),
                            ],
                          ),
                        ),

                        // ─────────────────────────────
                        // CONTENT
                        // ─────────────────────────────
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel("Ringkasan"),
                                const SizedBox(height: 12),
                                _statsSection(theme),
                                const SizedBox(height: 24),
                                _searchSection(theme, isDark),
                                const SizedBox(height: 14),
                                _filterChipsRow(theme),
                                const SizedBox(height: 22),
                                _sectionLabel("Daftar Klaim"),
                                const SizedBox(height: 12),
                                ...filteredClaims.map((c) => _claimCard(c, theme, isDark)),
                                if (filteredClaims.isEmpty)
                                  _emptyState(theme),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // SECTION LABEL — style konsisten
  // ─────────────────────────────────────
  Widget _sectionLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: theme.colorScheme.primary.withValues(alpha: 0.75),
      ),
    );
  }

  // ─────────────────────────────────────
  // STATS — menggunakan glassmorphism card
  // ─────────────────────────────────────
  Widget _statsSection(ThemeData theme) {
    return Column(
      children: [
        _statCard("TOTAL CLAIMS", total.toString(), Icons.bar_chart, theme),
        const SizedBox(height: 12),
        _statCard("IN PROGRESS", inProgress.toString(), Icons.access_time, theme),
        const SizedBox(height: 12),
        _statCard("RESOLVED", resolved.toString(), Icons.verified, theme),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Glass card — sama dengan form card di EditProfilePage
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.06),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  // SEARCH — style input konsisten
  // ─────────────────────────────────────
  Widget _searchSection(ThemeData theme, bool isDark) {
    return TextField(
      onChanged: (v) {
        search = v;
        _applyFilter();
      },
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Cari klaim...",
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

  // ─────────────────────────────────────
  // FILTER CHIPS
  // ─────────────────────────────────────
  Widget _filterChipsRow(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip("Semua", "all", theme),
          _chip("Pending", "pending", theme),
          _chip("In Progress", "in_progress", theme),
          _chip("Approved", "approved", theme),
          _chip("Rejected", "rejected", theme),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, ThemeData theme) {
    final isActive = selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.white
                : theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // CLAIM CARD — glass card konsisten
  // ─────────────────────────────────────
  Widget _claimCard(Map c, ThemeData theme, bool isDark) {
    final product = c['orders']?['product_name'] ?? "Premium";
    final variant = c['orders']?['variant_type'] ?? "";
    final imageUrl = c['orders']?['products']?['image'];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/garansi-detail', arguments: c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // ✅ Glass card identik dengan form card EditProfilePage
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: imageUrl != null && imageUrl.toString().isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : Icon(Icons.inventory_2_outlined,
                          size: 22,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        variant,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: c['status']),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 12),
            Text(
              c['title'] ?? "-",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              c['problem_description'] ?? "-",
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                child: Text(
                  "Klaim ID: #${c['id']}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.35),
                  ),
                ),
                ),

              const SizedBox(width: 8),

                // ✅ Detail button — style dari _button() EditProfilePage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
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
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward,
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
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
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
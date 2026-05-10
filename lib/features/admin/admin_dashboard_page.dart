import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../services/admin_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();

  int _totalOrders = 0;
  int _totalUsers = 0;
  int _totalIncome = 0;
  int _pendingOrders = 0;
  List<int> _monthlyIncome = [];

  bool _isLoading = true;
  String? _errorMessage;
  int _touchedBarIndex = -1;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _adminService.getTotalOrders();
      final users = await _adminService.getTotalUsers();
      final income = await _adminService.getTotalIncome();
      final monthly = await _adminService.getMonthlyIncome();
      // ✅ Fetch pending orders untuk notif badge
      final pending = await _adminService.getPendingOrders();

      if (!mounted) return;
      setState(() {
        _totalOrders = orders;
        _totalUsers = users;
        _totalIncome = income;
        _monthlyIncome = monthly;
        _pendingOrders = pending;
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

  String _formatRupiah(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // ✅ Format ringkas untuk chart tooltip
  String _formatRupiahShort(int value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $value';
  }

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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : _errorMessage != null
                  ? _errorState(theme)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          children: [
                            // ─────────────────────────────
                            // NAVBAR
                            // ─────────────────────────────
                            _buildNavbar(theme, isDark),

                            const SizedBox(height: 24),

                            // ─────────────────────────────
                            // GREETING + SUBTITLE
                            // ─────────────────────────────
                            Text(
                              "SYSTEM OVERVIEW",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Admin Dashboard",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _greetingText(),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ─────────────────────────────
                            // QUICK ACTIONS
                            // ─────────────────────────────
                            _buildQuickActions(theme, isDark),

                            const SizedBox(height: 22),

                            // ─────────────────────────────
                            // STAT CARDS
                            // ─────────────────────────────
                            _buildStatCard(
                              title: "Total Transaksi",
                              value: "$_totalOrders",
                              icon: Icons.receipt_long_outlined,
                              growth: "+14%",
                              isNegative: false,
                              theme: theme,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 12),

                            _buildStatCard(
                              title: "Total Pendapatan",
                              value: _formatRupiah(_totalIncome),
                              icon: Icons.account_balance_wallet_outlined,
                              growth: "+8%",
                              isNegative: false,
                              theme: theme,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 12),

                            // ✅ 2 kolom kecil
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMiniCard(
                                    title: "Pengguna",
                                    value: "$_totalUsers",
                                    icon: Icons.people_outline,
                                    color: Colors.blue,
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMiniCard(
                                    title: "Perlu Diproses",
                                    value: "$_pendingOrders",
                                    icon: Icons.hourglass_empty_outlined,
                                    color: Colors.orange,
                                    theme: theme,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ─────────────────────────────
                            // CHART HEADER
                            // ─────────────────────────────
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PENDAPATAN BULANAN",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.4,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.65),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Tahun ${DateTime.now().year}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                // Total tahun ini
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    _monthlyIncome.isNotEmpty
                                        ? _formatRupiahShort(
                                            _monthlyIncome.reduce(
                                                (a, b) => a + b))
                                        : 'Rp 0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ─────────────────────────────
                            // CHART
                            // ─────────────────────────────
                            _buildChart(theme, isDark),

                            const SizedBox(height: 24),

                            // ─────────────────────────────
                            // RECENT ACTIVITY PLACEHOLDER
                            // ─────────────────────────────
                            _buildRecentSection(theme, isDark),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET BUILDERS
  // ─────────────────────────────────────

  Widget _buildNavbar(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Brand
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: const Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          "ARNN.APPREM",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        // ✅ Refresh button
        GestureDetector(
          onTap: _fetchData,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(Icons.refresh_rounded,
                size: 18, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: Icon(
            Icons.person_outline,
            color: isDark ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // ✅ Manage Orders — dengan badge pending
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/admin-order'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_outlined,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  const Text(
                    "Kelola Order",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  if (_pendingOrders > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      child: Text(
                        "$_pendingOrders",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String growth,
    required bool isNegative,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1B1B2F),
                  const Color(0xFF1F1F3A),
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
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,
                color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Growth badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (isNegative ? Colors.redAccent : Colors.green)
                  .withValues(alpha: 0.12),
              border: Border.all(
                color: (isNegative ? Colors.redAccent : Colors.green)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNegative
                      ? Icons.trending_down
                      : Icons.trending_up,
                  size: 12,
                  color: isNegative ? Colors.redAccent : Colors.green,
                ),
                const SizedBox(width: 3),
                Text(
                  growth,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        isNegative ? Colors.redAccent : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme, bool isDark) {
    final months = [
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];

    final maxVal = _monthlyIncome.isEmpty
        ? 1.0
        : _monthlyIncome.reduce((a, b) => a > b ? a : b).toDouble() * 1.25;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1B1B2F),
                  const Color(0xFF1F1F3A),
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
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _monthlyIncome.isEmpty
          ? Center(
              child: Text(
                "Belum ada data",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            )
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot != null &&
                          event is! FlTapUpEvent) {
                        _touchedBarIndex =
                            response!.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedBarIndex = -1;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${months[groupIndex]}\n",
                        TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: _formatRupiahShort(
                                _monthlyIncome[groupIndex]),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= _monthlyIncome.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[index % 12],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: _touchedBarIndex == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.06),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _monthlyIncome.length,
                  (index) {
                    final isTouched = _touchedBarIndex == index;
                    final value = _monthlyIncome[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.toDouble(),
                          width: isTouched ? 16 : 12,
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: isTouched
                                ? [
                                    theme.colorScheme.secondary,
                                    theme.colorScheme.primary,
                                  ]
                                : [
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0.9),
                                    theme.colorScheme.secondary
                                        .withValues(alpha: 0.7),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  // ✅ Recent activity section baru
  Widget _buildRecentSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "AKTIVITAS TERKINI",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: theme.colorScheme.primary.withValues(alpha: 0.65),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/admin-order'),
              child: Text(
                "Lihat semua →",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Column(
            children: [
              _activityItem(
                icon: Icons.receipt_outlined,
                color: Colors.orange,
                title: "$_pendingOrders order menunggu approval",
                subtitle: "Butuh tindakan segera",
                theme: theme,
                isDark: isDark,
                onTap: () =>
                    Navigator.pushNamed(context, '/admin-order'),
              ),
              if (_pendingOrders > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.07),
                    height: 1,
                  ),
                ),
              _activityItem(
                icon: Icons.people_outline,
                color: Colors.blue,
                title: "$_totalUsers pengguna terdaftar",
                subtitle: "Total semua pengguna aktif",
                theme: theme,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.07),
                  height: 1,
                ),
              ),
              _activityItem(
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.green,
                title: _formatRupiah(_totalIncome),
                subtitle: "Total pendapatan keseluruhan",
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(ThemeData theme) {
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
              "Gagal Memuat Dashboard",
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
              onTap: _fetchData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
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
                    color: Colors.white,
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

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat pagi, Admin 👋";
    if (hour < 15) return "Selamat siang, Admin 👋";
    if (hour < 18) return "Selamat sore, Admin 👋";
    return "Selamat malam, Admin 👋";
  }
}
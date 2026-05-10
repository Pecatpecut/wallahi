import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/order_service.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({super.key});

  @override
  State<AdminOrderDetailPage> createState() =>
      _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage>
    with SingleTickerProviderStateMixin {
  final OrderService _service = OrderService();

  bool _isProcessing = false;

  // ✅ Animasi konsisten
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
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ✅ SnackBar konsisten
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

  // ✅ Approve dialog — konsisten dengan AdminOrderPage
  void _approveDialog(Map data) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
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
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1B1B2F),
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
                    // Header
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
                        Text(
                          "Input Akun",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['product_name'] ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
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
                      controller: passController,
                      icon: Icons.lock_outline,
                      theme: theme,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                isSaving ? null : () => Navigator.pop(ctx),
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
                                    if (emailController.text.trim().isEmpty ||
                                        passController.text.trim().isEmpty) {
                                      _showSnackBar(
                                        "Email & password wajib diisi",
                                        isError: true,
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);

                                    try {
                                      await _service.approveOrderManual(
                                        orderId: data['id'],
                                        email: emailController.text.trim(),
                                        password: passController.text.trim(),
                                      );

                                      if (!mounted) return;
                                      Navigator.pop(ctx);
                                      _showSnackBar(
                                        "Order berhasil di-approve!",
                                        isError: false,
                                      );
                                      // Kembali ke list setelah approve
                                      Navigator.pop(context);
                                    } catch (e) {
                                      if (!mounted) return;
                                      setDialogState(
                                          () => isSaving = false);
                                      _showSnackBar(
                                        e.toString().replaceAll(
                                            'Exception: ', ''),
                                        isError: true,
                                      );
                                    }
                                  },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radius),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
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

  // ✅ Reject dengan konfirmasi dialog
  void _rejectDialog(Map data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1B1B2F), const Color(0xFF23233A)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.25),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 28,
                  color: Colors.redAccent,
                ),
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
              Text(
                "Order ${data['product_name']} akan ditolak.\nTindakan ini tidak bisa dibatalkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                          borderRadius:
                              BorderRadius.circular(AppConstants.radius),
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
                        setState(() => _isProcessing = true);
                        try {
                          await _service.updateOrderStatus(
                              data['id'], 'rejected');
                          if (!mounted) return;
                          _showSnackBar("Order ditolak", isError: false);
                          Navigator.pop(context);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isProcessing = false);
                          _showSnackBar(
                            e.toString().replaceAll('Exception: ', ''),
                            isError: true,
                          );
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radius),
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.redAccent.withValues(alpha: 0.35),
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

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return '-';
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final data = ModalRoute.of(context)?.settings.arguments as Map?;

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text("No Data")),
      );
    }

    final status = data['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isApproved = status == 'approved';

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
          child: Column(
            children: [

              // ─────────────────────────────
              // APPBAR CUSTOM
              // ─────────────────────────────
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
                      "Detail Order",
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
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      children: [

                        // ─────────────────────
                        // HEADER CARD — status + produk
                        // ─────────────────────
                        _sectionCard(
                          isDark: isDark,
                          theme: theme,
                          child: Column(
                            children: [
                              // Thumbnail / icon produk
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data['product_name'] ?? '-',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              _statusBadge(status, theme),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─────────────────────
                        // INFO PRODUK (2 kolom)
                        // ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                title: "PLAN TYPE",
                                value: data['variant_type'] ?? '-',
                                icon: Icons.layers_outlined,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoCard(
                                title: "HARGA",
                                value: "Rp ${data['price'] ?? 0}",
                                icon: Icons.payments_outlined,
                                isDark: isDark,
                                theme: theme,
                                isHighlight: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                title: "DURASI",
                                value:
                                    "${data['duration_days'] ?? '-'} hari",
                                icon: Icons.timelapse_outlined,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoCard(
                                title: "TGL ORDER",
                                value: _formatDate(data['created_at']),
                                icon: Icons.calendar_today_outlined,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ─────────────────────
                        // BUKTI PEMBAYARAN
                        // ─────────────────────
                        if (data['payment_proof'] != null &&
                            data['payment_proof']
                                .toString()
                                .isNotEmpty) ...[
                          _sectionCard(
                            isDark: isDark,
                            theme: theme,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                      ),
                                      child: Icon(
                                        Icons.receipt_outlined,
                                        size: 15,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "BUKTI PEMBAYARAN",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.4,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  child: Image.network(
                                    data['payment_proof'],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    // ✅ Error builder yang lebih baik
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.grey.shade100,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons
                                                  .broken_image_outlined,
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withValues(alpha: 0.3),
                                              size: 32,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Gambar tidak dapat dimuat",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ─────────────────────
                        // ACCOUNT INFO (jika sudah approved)
                        // ─────────────────────
                        if (isApproved &&
                            data['account_email'] != null) ...[
                          _sectionCard(
                            isDark: isDark,
                            theme: theme,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                      ),
                                      child: Icon(
                                        Icons.key_outlined,
                                        size: 15,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "INFO AKUN",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.4,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _accountRow(
                                  Icons.mail_outline,
                                  "Email",
                                  data['account_email'] ?? '-',
                                  theme,
                                  isDark,
                                ),
                                const SizedBox(height: 10),
                                _accountRow(
                                  Icons.lock_outline,
                                  "Password",
                                  data['account_password'] ?? '-',
                                  theme,
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ─────────────────────
                        // ACTION BUTTONS (hanya pending)
                        // ─────────────────────
                        if (isPending) ...[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isProcessing
                                ? Center(
                                    key: const ValueKey('processing'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color:
                                                  theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "Memproses...",
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('actions'),
                                    children: [
                                      // Reject button
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _rejectDialog(data),
                                          child: Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppConstants.radius),
                                              border: Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.4),
                                              ),
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.07),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.close,
                                                    size: 16,
                                                    color: Colors.redAccent),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Tolak",
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Approve button
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              _approveDialog(data),
                                          child: Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppConstants.radius),
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme
                                                      .colorScheme.secondary,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 14,
                                                  offset:
                                                      const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.check,
                                                    size: 16,
                                                    color: Colors.white),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Approve",
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],

                        const SizedBox(height: 30),
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
  // WIDGET HELPERS
  // ─────────────────────────────────────

  Widget _sectionCard({
    required bool isDark,
    required ThemeData theme,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: (isHighlight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface)
                  .withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _accountRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.grey.shade100,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: color,
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
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          icon,
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
          vertical: 14,
        ),
      ),
    );
  }
}
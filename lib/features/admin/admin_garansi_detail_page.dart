import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/claims_service.dart';

class AdminGaransiDetailPage extends StatefulWidget {
  const AdminGaransiDetailPage({super.key});

  @override
  State<AdminGaransiDetailPage> createState() =>
      _AdminGaransiDetailPageState();
}

class _AdminGaransiDetailPageState extends State<AdminGaransiDetailPage>
    with SingleTickerProviderStateMixin {
  final ClaimsService service = ClaimsService();
  final TextEditingController _noteController = TextEditingController();

  bool _isApproving = false;
  bool _isRejecting = false;

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
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _noteController.dispose();
    super.dispose();
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
  // APPROVE
  // ────────────────────────────────────────────
  Future<void> _approve(String claimId) async {
    setState(() => _isApproving = true);
    try {
      await service.updateClaim(
        id: claimId,
        status: "approved",
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      _showResultDialog(isApproved: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  // ────────────────────────────────────────────
  // REJECT
  // ────────────────────────────────────────────
  Future<void> _reject(String claimId) async {
    setState(() => _isRejecting = true);
    try {
      await service.updateClaim(
        id: claimId,
        status: "rejected",
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      _showResultDialog(isApproved: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  // ────────────────────────────────────────────
  // RESULT DIALOG — glassmorphism konsisten
  // ────────────────────────────────────────────
  void _showResultDialog({required bool isApproved}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isApproved ? Colors.green : Colors.redAccent;
    final icon =
        isApproved ? Icons.check_circle_outline : Icons.cancel_outlined;
    final title = isApproved ? "Klaim Disetujui" : "Klaim Ditolak";
    final subtitle = isApproved
        ? "Klaim garansi telah berhasil disetujui."
        : "Klaim garansi telah ditolak.";

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
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
                color: color.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon aura
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
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

              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pop(context); // kembali ke list
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Kembali ke Daftar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final data = ModalRoute.of(context)?.settings.arguments as Map?;
    if (data == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    final order = data['orders'] as Map? ?? {};
    final claimId = data['id']?.toString() ?? '';
    final issue = data['problem_description']?.toString() ?? '-';
    final adminNote = data['admin_note']?.toString();
    final proofImage = data['proof_image']?.toString();
    final status = data['status']?.toString() ?? 'pending';

    // Sudah diproses sebelumnya
    final isAlreadyProcessed =
        status == 'approved' || status == 'rejected';

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
                          "Detail Garansi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        // Status badge di AppBar
                        _buildStatusBadge(status),
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
                          // CLAIM INFO CARD
                          // ─────────────────────
                          _buildClaimInfoCard(
                              theme, isDark, order, issue, status),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // BUKTI GAMBAR
                          // ─────────────────────
                          if (proofImage != null &&
                              proofImage.isNotEmpty) ...[
                            _sectionLabel("BUKTI MASALAH", theme),
                            const SizedBox(height: 12),
                            _buildProofImage(theme, isDark, proofImage),
                            const SizedBox(height: 20),
                          ],

                          // ─────────────────────
                          // ADMIN NOTE EXISTING
                          // ─────────────────────
                          if (adminNote != null &&
                              adminNote.isNotEmpty) ...[
                            _sectionLabel("CATATAN ADMIN SEBELUMNYA",
                                theme),
                            const SizedBox(height: 12),
                            _buildExistingNote(theme, isDark, adminNote),
                            const SizedBox(height: 20),
                          ],

                          // ─────────────────────
                          // INPUT ADMIN NOTE
                          // ─────────────────────
                          if (!isAlreadyProcessed) ...[
                            _sectionLabel("CATATAN ADMIN", theme),
                            const SizedBox(height: 12),
                            _buildNoteField(theme, isDark),
                            const SizedBox(height: 12),
                          ],

                          // ─────────────────────
                          // SUDAH DIPROSES
                          // ─────────────────────
                          if (isAlreadyProcessed)
                            _buildAlreadyProcessedBanner(
                                theme, isDark, status),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM ACTION BUTTONS
                  // ──────────────────────────────
                  if (!isAlreadyProcessed)
                    _buildBottomBar(
                        theme, isDark, claimId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // STATUS BADGE DI APPBAR
  // ────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = "APPROVED";
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = "REJECTED";
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.amber;
        label = "PENDING";
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // CLAIM INFO CARD
  // ────────────────────────────────────────────
  Widget _buildClaimInfoCard(ThemeData theme, bool isDark, Map order,
      String issue, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header produk
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['product_name']?.toString() ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Variant: ${order['variant_type']?.toString() ?? '-'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

          // Issue detail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KELUHAN",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // PROOF IMAGE
  // ────────────────────────────────────────────
  Widget _buildProofImage(
      ThemeData theme, bool isDark, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  "Gambar tidak tersedia",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // EXISTING ADMIN NOTE
  // ────────────────────────────────────────────
  Widget _buildExistingNote(
      ThemeData theme, bool isDark, String note) {
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              size: 15,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // NOTE FIELD — konsisten EditProfilePage
  // ────────────────────────────────────────────
  Widget _buildNoteField(ThemeData theme, bool isDark) {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: "Masukkan catatan atau alasan keputusan...",
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
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
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  // ────────────────────────────────────────────
  // ALREADY PROCESSED BANNER
  // ────────────────────────────────────────────
  Widget _buildAlreadyProcessedBanner(
      ThemeData theme, bool isDark, String status) {
    final isApproved = status == 'approved';
    final color = isApproved ? Colors.green : Colors.redAccent;
    final label = isApproved
        ? "Klaim ini sudah disetujui sebelumnya."
        : "Klaim ini sudah ditolak sebelumnya.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM ACTION BAR — Approve & Reject
  // ────────────────────────────────────────────
  Widget _buildBottomBar(
      ThemeData theme, bool isDark, String claimId) {
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
          // ── REJECT ──
          Expanded(
            child: GestureDetector(
              onTap: (_isRejecting || _isApproving)
                  ? null
                  : () => _reject(claimId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius),
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: _isRejecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.close_rounded,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Tolak",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── APPROVE ──
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: (_isApproving || _isRejecting)
                  ? null
                  : () => _approve(claimId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius),
                  gradient: (_isApproving || _isRejecting)
                      ? LinearGradient(colors: [
                          Colors.green.withValues(alpha: 0.4),
                          Colors.green.withValues(alpha: 0.3),
                        ])
                      : const LinearGradient(colors: [
                          Color(0xFF2ECC71),
                          Color(0xFF27AE60),
                        ]),
                  boxShadow: (_isApproving || _isRejecting)
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _isApproving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Setujui Klaim",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
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
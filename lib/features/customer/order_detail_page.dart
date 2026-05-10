import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

// TAMBAH INI
Uint8List? _newPaymentProofBytes;
String? _newPaymentProofName;


  Map? subscription;
  bool _isLoadingSubs = true;
  bool _isResubmitting = false;
  Map? _userData;

  bool _didInit = false;


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
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose(); 
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInit) return;
    _didInit = true;

    final data = ModalRoute.of(context)?.settings.arguments as Map?;
    if (data != null) {
      _fetchSubscription(data['id'].toString());
      _fetchUserData(data['user_id'].toString());

    }
  }

  Future<void> _fetchSubscription(String orderId) async {
    try {
      final data = await supabase
          .from('subscriptions')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        subscription = data;
        _isLoadingSubs = false;
      });
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSubs = false);
      _animController.forward();
    }
  }

  Future<void> _fetchUserData(String userId) async {
  try {
    final data = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (!mounted) return;
    setState(() => _userData = data);
  } catch (e) {
  }
}

  Future<void> _resubmitOrder(Map data) async {
  if (_newPaymentProofBytes == null) {
    _showSnackBar('Upload foto bukti bayar terlebih dahulu', isError: true);
    return;
  }

  setState(() => _isResubmitting = true);

  try {
    final userId = data['user_id'];
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
        .from('payment-proofs')
        .uploadBinary(fileName, _newPaymentProofBytes!);

    final newUrl = supabase.storage
        .from('payment-proofs')
        .getPublicUrl(fileName);

    // Update order
    await supabase.from('orders').update({
      'payment_proof': newUrl,
      'status': 'pending',
    }).eq('id', data['id']);

    if (!mounted) return;
    _showSnackBar('Order berhasil dikirim ulang!', isError: false);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;
    _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
  } finally {
    if (mounted) setState(() => _isResubmitting = false);
  }
}

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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

    final productName = data["product_name"] ?? "-";
    final variant = data["variant_type"] ?? "-";
    final price = data["price"] ?? 0;
    final status = data["status"] ?? "pending";
    final email = data["account_email"] ?? "-";
    final password = data["account_password"] ?? "-";
    final imageUrl =
        data['products'] != null ? data['products']['image'] : null;

    final duration = data['duration_days'] ?? 30;
    final now = DateTime.now();

    
    final subEndRaw = subscription?['end_date'];
    final subStartRaw = subscription?['start_date'];
    final endDate = subEndRaw != null
        ? (DateTime.tryParse(subEndRaw) ?? now.add(Duration(days: duration)))
        : DateTime.tryParse(data['created_at'] ?? '') != null
            ? DateTime.tryParse(data['created_at'])!.add(Duration(days: duration))
            : now.add(Duration(days: duration));
    final startDate = subStartRaw != null
        ? (DateTime.tryParse(subStartRaw) ?? DateTime.tryParse(data['created_at'] ?? '') ?? now)
        : (DateTime.tryParse(data['created_at'] ?? '') ?? now);
    final actualDuration = endDate.difference(startDate).inDays;
    final durationToUse = actualDuration > 0 ? actualDuration : duration;

    int remaining = endDate.difference(now).inDays;
    if (remaining < 0) remaining = 0;

    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final isExpired = isApproved && remaining == 0;
    final isActive = isApproved && remaining > 0;

    double progress = durationToUse > 0 ? (remaining / durationToUse) : 0;
    if (progress < 0) progress = 0;

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

              // ── AppBar ──
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
                            size: 16, color: theme.colorScheme.primary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Order Detail",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    _statusBadgeSmall(
                        isActive: isActive,
                        isPending: isPending,
                        isRejected: isRejected,
                        isExpired: isExpired),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: _isLoadingSubs
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
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                24, 4, 24, 30),
                            children: [

                              // Header produk
                              _buildProductHeader(theme, isDark,
                                  imageUrl, productName, isActive,
                                  isPending, isRejected, isExpired),

                              const SizedBox(height: 16),

                              // ── REJECTED ──
                              if (isRejected) ...[
                                _buildRejectedBanner(theme, isDark, data),
                                const SizedBox(height: 16),
                                _buildResubmitForm(theme, isDark, data),
                                const SizedBox(height: 16),
                              ],

                              // ── TIME REMAINING ──
                              if (!isRejected) ...[
                                _sectionCard(
                                  isDark: isDark,
                                  theme: theme,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionLabel(
                                          "TIME REMAINING", theme),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            isPending
                                                ? "Menunggu Aktivasi"
                                                : isExpired
                                                    ? "Expired"
                                                    : "$remaining",
                                            style: TextStyle(
                                              fontSize: isPending ||
                                                      isExpired
                                                  ? 16
                                                  : 28,
                                              fontWeight: FontWeight.bold,
                                              color: isExpired
                                                  ? Colors.redAccent
                                                  : theme.colorScheme
                                                      .onSurface,
                                            ),
                                          ),
                                          if (isActive) ...[
                                            const SizedBox(width: 4),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 4),
                                              child: Text(
                                                "hari tersisa",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(
                                                          alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: isPending ? 0 : progress,
                                          minHeight: 7,
                                          backgroundColor: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.08)
                                              : Colors.black
                                                  .withValues(alpha: 0.07),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            isExpired
                                                ? Colors.redAccent
                                                : progress < 0.25
                                                    ? Colors.orange
                                                    : theme.colorScheme
                                                        .primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Berakhir ${_formatDate(endDate.toIso8601String())}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Plan + Harga
                              Row(
                                children: [
                                  Expanded(
                                    child: _infoCard(
                                      title: "PLAN TYPE",
                                      value: variant,
                                      icon:
                                          Icons.workspace_premium_outlined,
                                      isDark: isDark,
                                      theme: theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _infoCard(
                                      title: "HARGA",
                                      value: "Rp $price",
                                      icon: Icons.payments_outlined,
                                      isDark: isDark,
                                      theme: theme,
                                      isHighlight: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              _infoCard(
                                title: "TANGGAL PEMBELIAN",
                                value: _formatDate(data['created_at']),
                                icon: Icons.calendar_today_outlined,
                                isDark: isDark,
                                theme: theme,
                              ),

                              // Account info
                              if (isActive) ...[
                                const SizedBox(height: 16),
                                _buildAccountInfo(
                                    theme, isDark, email, password),
                              ],

                              const SizedBox(height: 20),

                              // Klaim garansi
                              if (isExpired) ...[
                                _actionButton(
                                  label: "Klaim Garansi",
                                  icon: Icons.shield_outlined,
                                  isPrimary: true,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () => Navigator.pushNamed(
                                      context, '/garansi-form',
                                      arguments: data),
                                ),
                                const SizedBox(height: 12),
                                _lihatGaransiButton(theme, isDark, data),
                                const SizedBox(height: 12),
                              ],

                              // Hubungi support
                              if (!isRejected)
                                _actionButton(
                                  label: "Hubungi Support",
                                  icon: Icons.support_agent_outlined,
                                  isPrimary: false,
                                  theme: theme,
                                  isDark: isDark,
                                  onTap: () async {
                                    const phone = "6285349661585";   // tanpa tanda +
                                    final message = "Halo admin, saya butuh bantuan untuk order $productName";

                                    final url = Uri.parse(
                                      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
                                    );

                                    try {
                                      // Langsung launch tanpa pengecekan canLaunchUrl dulu
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        _showSnackBar("Gagal membuka WhatsApp. Pastikan WhatsApp terinstall.", isError: true);
                                      }
                                    }
                                  },
                                ),
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

  // ── Builders ─────────────────────────────────────────────────────

  Widget _buildProductHeader(
    ThemeData theme, bool isDark, dynamic imageUrl,
    String productName, bool isActive, bool isPending,
    bool isRejected, bool isExpired,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.07),
                 Colors.white.withValues(alpha: 0.02)]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isRejected
              ? Colors.redAccent.withValues(alpha: 0.25)
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: isRejected
                ? Colors.redAccent.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade100,
              border: Border.all(
                color: isRejected
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: imageUrl != null && imageUrl.toString().isNotEmpty
                ? ColorFiltered(
                    colorFilter: isRejected
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                    child: Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3))),
                  )
                : Icon(Icons.inventory_2_outlined,
                    color: isRejected
                        ? Colors.grey.withValues(alpha: 0.4)
                        : theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 14),
          Text(
            productName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isRejected
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _statusBadgeLarge(
              isActive: isActive,
              isPending: isPending,
              isRejected: isRejected,
              isExpired: isExpired),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(ThemeData theme, bool isDark, Map data) {
    final adminNote = data['admin_note']?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.redAccent.withValues(alpha: 0.07),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.redAccent, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Ditolak",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent.shade200),
                    ),
                    Text(
                      "Perbarui data di bawah lalu kirim ulang",
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.7),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Catatan Admin:",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          adminNote,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResubmitForm(ThemeData theme, bool isDark, Map data) {
  final userName = _userData?['name'] ?? '-';
  final userEmail = _userData?['email'] ?? '-';
  final userPhone = _userData?['phone'] ?? '-';

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: isDark
            ? [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.02)]
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Info User (read-only) ──
        _sectionLabel("INFORMASI PEMESAN", theme),
        const SizedBox(height: 12),
        _readOnlyRow(Icons.person_outline, "Nama", userName, theme, isDark),
        const SizedBox(height: 8),
        _readOnlyRow(Icons.mail_outline, "Email", userEmail, theme, isDark),
        const SizedBox(height: 8),
        _readOnlyRow(Icons.phone_outlined, "WhatsApp", userPhone, theme, isDark),

        const SizedBox(height: 20),
        Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 20),

        // ── QRIS ──
        _sectionLabel("CARA PEMBAYARAN", theme),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Image.asset(
              'assets/images/qris.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Scan QRIS untuk melakukan pembayaran",
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 20),

        // ── Upload Bukti Bayar ──
        _sectionLabel("UPLOAD BUKTI BAYAR BARU", theme),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _newPaymentProofBytes != null ? null : 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
              border: Border.all(
                color: _newPaymentProofBytes != null
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: _newPaymentProofBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Image.memory(_newPaymentProofBytes!, width: double.infinity, fit: BoxFit.cover),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _newPaymentProofBytes = null;
                              _newPaymentProofName = null;
                            }), 
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 32,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text("Tap untuk upload foto",
                          style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45))),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Submit Button ──
        GestureDetector(
          onTap: _isResubmitting ? null : () => _resubmitOrder(data),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radius),
              gradient: _isResubmitting
                  ? LinearGradient(colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                      theme.colorScheme.secondary.withValues(alpha: 0.5),
                    ])
                  : LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ]),
              boxShadow: _isResubmitting ? [] : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _isResubmitting
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 18,
                            color: isDark ? Colors.black : Colors.white),
                        const SizedBox(width: 8),
                        Text("Kirim Ulang Order",
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAccountInfo(
      ThemeData theme, bool isDark, String email, String password) {
    return _sectionCard(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.key_outlined,
                    size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text("INFO AKUN",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 14),
          _accountRow(Icons.mail_outline, "Email", email, theme, isDark),
          const SizedBox(height: 10),
          _accountRow(
              Icons.lock_outline, "Password", password, theme, isDark),
        ],
      ),
    );
  }

  Widget _lihatGaransiButton(ThemeData theme, bool isDark, Map data) {
    return GestureDetector(
      onTap: () async {
        try {
          final result = await supabase
              .from('claims')
              .select('''
                *,
                orders (
                  product_name,
                  variant_type,
                  products ( image )
                )
              ''')
              .eq('order_id', data['id'])
              .order('created_at', ascending: false)
              .limit(1);

          if (!mounted) return;
          if (result.isNotEmpty) {
            Navigator.pushNamed(context, '/garansi-detail',
                arguments: result.first as Map);
          } else {
            _showSnackBar('Belum ada klaim garansi', isError: false);
          }
        } catch (e) {
          if (!mounted) return;
          _showSnackBar('Gagal memuat garansi', isError: true);
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.shade100,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.verified_outlined,
                  size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text("Lihat Detail Garansi",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _statusBadgeSmall({
    required bool isActive, required bool isPending,
    required bool isRejected, required bool isExpired,
  }) {
    final Color color = isActive ? Colors.green
        : isPending ? Colors.orange
        : isRejected ? Colors.redAccent
        : Colors.redAccent;
    final String label = isActive ? "AKTIF"
        : isPending ? "PENDING"
        : isRejected ? "DITOLAK"
        : "EXPIRED";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: color)),
    );
  }

  // Tambah di bagian helpers
Widget _readOnlyRow(IconData icon, String label, String value,
    ThemeData theme, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.grey.shade100,
      border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.07)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
          ],
        ),
      ],
    ),
  );
}

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );
  if (picked != null) {
    final bytes = await picked.readAsBytes();
    setState(() {
      _newPaymentProofBytes = bytes;
      _newPaymentProofName = picked.name;
    });
  }
}

  Widget _statusBadgeLarge({
    required bool isActive, required bool isPending,
    required bool isRejected, required bool isExpired,
  }) {
    final Color fg = isActive ? Colors.green
        : isPending ? Colors.orange
        : isRejected ? Colors.redAccent
        : Colors.redAccent;
    final String label = isActive ? "AKTIF"
        : isPending ? "PENDING"
        : isRejected ? "DITOLAK"
        : "EXPIRED";
    final IconData icon = isActive
        ? Icons.check_circle_outline
        : isPending
            ? Icons.hourglass_empty_outlined
            : Icons.cancel_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: fg.withValues(alpha: 0.12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: fg)),
        ],
      ),
    );
  }

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
              ? [Colors.white.withValues(alpha: 0.06),
                 Colors.white.withValues(alpha: 0.02)]
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

  Widget _sectionLabel(String text, ThemeData theme) => Text(text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: theme.colorScheme.primary.withValues(alpha: 0.75)));


  Widget _infoCard({
    required String title, required String value,
    required IconData icon, required bool isDark,
    required ThemeData theme, bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.06),
                 Colors.white.withValues(alpha: 0.02)]
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: (isHighlight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface)
                  .withValues(alpha: 0.1),
            ),
            child: Icon(icon,
                size: 16,
                color: isHighlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45))),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHighlight
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value,
      ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.grey.shade100,
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label, required IconData icon,
    required bool isPrimary, required ThemeData theme,
    required bool isDark, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          gradient: isPrimary
              ? LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ])
              : null,
          color: isPrimary
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.grey.shade100,
          border: isPrimary
              ? null
              : Border.all(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.25)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isPrimary
                    ? (isDark ? Colors.black : Colors.white)
                    : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: isPrimary
                        ? (isDark ? Colors.black : Colors.white)
                        : theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../services/order_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  Duration timeLeft = const Duration(hours: 23, minutes: 59, seconds: 59);
  Timer? _timer;

  XFile? pickedFile;
  Uint8List? imageBytes;

  final orderService = OrderService();
  final supabase = Supabase.instance.client;

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
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (timeLeft.inSeconds > 0) {
        setState(() => timeLeft -= const Duration(seconds: 1));
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  // ─────────────────────────────────
  // FORMAT HARGA: 150000 → 150.000
  // ─────────────────────────────────
  String _formatPrice(dynamic price) {
    if (price == null) return '-';
    final num = int.tryParse(price.toString()) ?? 0;
    final str = num.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // ✅ FIX: validasi tipe file
      final ext = picked.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        if (mounted) {
          _showSnackBar('Hanya file JPG/JPEG/PNG yang diizinkan', isError: true);
        }
        return;
      }
      final bytes = await picked.readAsBytes();
      // ✅ FIX: validasi ukuran file (max 5MB)
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          _showSnackBar('Ukuran file maksimal 5MB', isError: true);
        }
        return;
      }
      setState(() {
        pickedFile = picked;
        imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadPaymentProof(String userId) async {
    if (pickedFile == null || imageBytes == null) return null;
    final fileName =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage
        .from('payment-proofs')
        .uploadBinary(fileName, imageBytes!);
    return supabase.storage
        .from('payment-proofs')
        .getPublicUrl(fileName);
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

  Future<void> _confirmPayment(
      Map product, Map variant, String email) async {
    if (isLoading) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (imageBytes == null) {
      _showSnackBar('Upload bukti pembayaran dulu', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final paymentProofUrl = await _uploadPaymentProof(user.id);

      await orderService.createOrder(
        userId: user.id,
        product: product,
        variant: variant,
        email: email,
        paymentProof: paymentProofUrl,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF111124),
                      const Color(0xFF0A0A14),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon sukses dengan aura
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.12),
                    ),
                  ),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                      size: 34,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "Pembayaran Berhasil!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Pesananmu sedang diproses.\nKami akan segera mengonfirmasi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),

              const SizedBox(height: 28),

              // Tombol lihat pesanan
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/orders');
                },
                child: Container(
                  height: 50,
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
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Lihat Pesanan",
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
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
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    final product = args["product"] as Map;
    final variant = args["variant"] as Map;
    final email = args["email"] as String? ?? '';

    final title = product["name"] ?? '-';
    final price = _formatPrice(variant["price"]);

    // Warna timer: merah kalau < 1 jam
    final isUrgent = timeLeft.inHours < 1;
    final timerColor =
        isUrgent ? Colors.redAccent : theme.colorScheme.primary;

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
                          "Payment",
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

                  // ──────────────────────────────
                  // STEP INDICATOR
                  // ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepIndicator(theme, isDark),
                  ),

                  const SizedBox(height: 20),

                  // ──────────────────────────────
                  // SCROLLABLE CONTENT
                  // ──────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─────────────────────
                          // TIMER CARD
                          // ─────────────────────
                          _buildTimerCard(
                              theme, isDark, timerColor, isUrgent),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // QRIS CARD
                          // ─────────────────────
                          _sectionLabel("METODE PEMBAYARAN", theme),
                          const SizedBox(height: 12),
                          _buildQrisCard(theme, isDark, price),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // TRANSACTION SUMMARY
                          // ─────────────────────
                          _sectionLabel("RINGKASAN TRANSAKSI", theme),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                              theme, isDark, title, price),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // UPLOAD BUKTI
                          // ─────────────────────
                          _sectionLabel("BUKTI PEMBAYARAN", theme),
                          const SizedBox(height: 12),
                          _buildUploadArea(theme, isDark),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM CONFIRM BUTTON
                  // ──────────────────────────────
                  _buildBottomBar(
                      context, theme, isDark, price, product, variant, email),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // STEP INDICATOR — identik CheckoutPage
  // ────────────────────────────────────────────
  Widget _buildStepIndicator(ThemeData theme, bool isDark) {
    final steps = [
      ("Selection", true),
      ("Checkout", true),
      ("Payment", true),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = steps[i].$2;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  steps[i].$1.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ────────────────────────────────────────────
  // TIMER CARD — dengan urgency color
  // ────────────────────────────────────────────
  Widget _buildTimerCard(
      ThemeData theme, bool isDark, Color timerColor, bool isUrgent) {
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
          color: isUrgent
              ? Colors.redAccent.withValues(alpha: 0.4)
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: timerColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikon jam
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: timerColor.withValues(alpha: 0.12),
              border: Border.all(
                color: timerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.timer_outlined,
              color: timerColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: timerColor.withValues(alpha: 0.12),
                    border: Border.all(
                        color: timerColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isUrgent ? "SEGERA BAYAR" : "MENUNGGU PEMBAYARAN",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: timerColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Selesaikan sebelum timer habis",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Timer display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(timeLeft),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                "HH:MM:SS",
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // QRIS CARD
  // ────────────────────────────────────────────
  Widget _buildQrisCard(ThemeData theme, bool isDark, String price) {
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
          // Header QRIS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "QRIS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.green.withValues(alpha: 0.12),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "SECURE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // QR image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/qris.png',
              height: 180,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "Scan dengan mobile banking atau e-wallet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Merchant: ARNN.APPREM",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          // Divider tipis
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

          const SizedBox(height: 12),

          // Harga besar
          Text(
            "Rp $price",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "ID: SECURE_99281X",
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // SUMMARY CARD — konsisten CheckoutPage
  // ────────────────────────────────────────────
  Widget _buildSummaryCard(
      ThemeData theme, bool isDark, String title, String price) {
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
      ),
      child: Column(
        children: [
          _summaryRow(theme, "Produk", title),
          const SizedBox(height: 10),
          _summaryRow(theme, "Subtotal", "Rp $price"),
          const SizedBox(height: 10),
          _summaryRow(theme, "Biaya Layanan", "GRATIS",
              valueColor: Colors.green),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _summaryRow(
            theme,
            "Total Amount",
            "Rp $price",
            isBold: true,
            valueColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────
  // UPLOAD BUKTI — dashed border + preview
  // ────────────────────────────────────────────
  Widget _buildUploadArea(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: imageBytes != null ? 180 : 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : theme.colorScheme.primary.withValues(alpha: 0.03),
          border: Border.all(
            color: imageBytes != null
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
            width: 1.0,
            // Dashed border via custom painter diganti border solid tipis
            // untuk kompatibilitas — tetap bersih
          ),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                    ),
                    // Overlay edit
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "Ganti",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Upload Bukti Pembayaran",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "JPG, PNG • Maks 5MB",
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM BAR — konsisten ProductDetail & Checkout
  // ────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String price,
    Map product,
    Map variant,
    String email,
  ) {
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
          // Info total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TOTAL BAYAR",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: theme.colorScheme.primary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp $price",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Tombol confirm
          GestureDetector(
            onTap: () => _confirmPayment(product, variant, email),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radius),
                gradient: isLoading
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.5),
                          theme.colorScheme.secondary.withValues(alpha: 0.5),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                boxShadow: isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Konfirmasi",
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ],
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
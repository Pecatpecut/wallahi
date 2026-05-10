import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = true;

  // ✅ Animasi konsisten dengan EditProfilePage & ProductDetailPage
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
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

  void _proceed(Map product, Map variant) {
    FocusScope.of(context).unfocus();

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (_emailController.text.trim().isEmpty ||
        !emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() => _isEmailValid = false);
      _showSnackBar('Masukkan email yang valid', isError: true);
      return;
    }

    setState(() => _isEmailValid = true);

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        "product": product,
        "variant": variant,
        "email": _emailController.text.trim(),
      },
    );
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

    final title = product["name"] ?? '-';
    final image = product["image"];
    final price = _formatPrice(variant["price"]);
    final days = variant["duration_days"]?.toString() ?? '-';
    final type = variant["type"]?.toString() ?? '-';

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
                          "Checkout",
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
                          // ORDER SUMMARY CARD
                          // ─────────────────────
                          _buildOrderCard(
                              context, theme, isDark, image, title,
                              type, days, price),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // ACCOUNT DETAIL
                          // ─────────────────────
                          _sectionLabel("DETAIL AKUN", theme),
                          const SizedBox(height: 12),
                          _buildEmailField(theme, isDark),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // SUMMARY MATRIX
                          // ─────────────────────
                          _sectionLabel("RINGKASAN PEMBAYARAN", theme),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                              context, theme, isDark, price),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM BAR
                  // ──────────────────────────────
                  _buildBottomBar(
                      context, theme, isDark, price, product, variant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // STEP INDICATOR
  // ────────────────────────────────────────────
  Widget _buildStepIndicator(ThemeData theme, bool isDark) {
    final steps = [
      ("Selection", true),
      ("Checkout", true),
      ("Payment", false),
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
          final step = steps[i];
          final isActive = step.$2;
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
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  step.$1.toUpperCase(),
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
  // ORDER SUMMARY CARD
  // ────────────────────────────────────────────
  Widget _buildOrderCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic image,
    String title,
    String type,
    String days,
    String price,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          // Thumbnail produk
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.shade100,
            ),
            clipBehavior: Clip.hardEdge,
            child: image != null
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      size: 28,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    size: 28,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
          ),

          const SizedBox(width: 16),

          // Info produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge type
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  "$days hari aktif",
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Harga
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Rp",
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // EMAIL FIELD — konsisten dengan EditProfilePage
  // ────────────────────────────────────────────
  Widget _buildEmailField(ThemeData theme, bool isDark) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      onChanged: (_) {
        if (!_isEmailValid) setState(() => _isEmailValid = true);
      },
      decoration: InputDecoration(
        hintText: "you@example.com",
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          Icons.mail_outline,
          size: 18,
          color: _isEmailValid
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : Colors.redAccent.withValues(alpha: 0.7),
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
            color: _isEmailValid
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : Colors.redAccent,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          borderSide: _isEmailValid
              ? BorderSide.none
              : const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // SUMMARY CARD
  // ────────────────────────────────────────────
  Widget _buildSummaryCard(
      BuildContext context, ThemeData theme, bool isDark, String price) {
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
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(theme, "Subtotal", "Rp $price"),
          const SizedBox(height: 10),
          _summaryRow(theme, "Pajak Sistem (0%)", "Rp 0"),
          const SizedBox(height: 10),
          _summaryRow(theme, "Diskon Voucher", "- Rp 0",
              valueColor: Colors.green),
          const SizedBox(height: 14),
          // Divider bergaya
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
            "Total Pembayaran",
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
  // BOTTOM BAR — konsisten dengan ProductDetailPage
  // ────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String price,
    Map product,
    Map variant,
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

          // Tombol proceed
          GestureDetector(
            onTap: () => _proceed(product, variant),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bayar Sekarang",
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ],
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
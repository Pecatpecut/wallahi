import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../services/product_service.dart';

class AdminAddVariantPage extends StatefulWidget {
  const AdminAddVariantPage({super.key});

  @override
  State<AdminAddVariantPage> createState() => _AdminAddVariantPageState();
}

class _AdminAddVariantPageState extends State<AdminAddVariantPage>
    with SingleTickerProviderStateMixin {
  final service = ProductService();

  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _modalPriceController = TextEditingController();
  final _durationController = TextEditingController();

  Map? variant;
  late Map product;

  String _durationUnit = "Days";
  bool _isSubmitting = false;
  bool _isDeleting = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    product = args;
    variant = args['variant'];

    if (variant != null) {
      _typeController.text = variant!['type'] ?? '';
      _priceController.text = variant!['price']?.toString() ?? '';
      _durationController.text =
          variant!['duration_days']?.toString() ?? '';
      _modalPriceController.text =
          (variant!['modal_price'] ?? '').toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _modalPriceController.dispose();
    _durationController.dispose();
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
  // VALIDASI & SUBMIT
  // ────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_typeController.text.trim().isEmpty) {
      _showSnackBar('Nama variant wajib diisi', isError: true);
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      _showSnackBar('Harga wajib diisi', isError: true);
      return;
    }
    if (_durationController.text.trim().isEmpty) {
      _showSnackBar('Durasi wajib diisi', isError: true);
      return;
    }

    final price = int.tryParse(_priceController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (price == null || price <= 0) {
      _showSnackBar('Harga tidak valid', isError: true);
      return;
    }
    if (duration == null || duration <= 0) {
      _showSnackBar('Durasi tidak valid', isError: true);
      return;
    }

    final modal = _modalPriceController.text.trim().isEmpty
        ? null
        : int.tryParse(_modalPriceController.text.trim());

    // Konversi unit durasi ke hari
    final durationInDays =
        _durationUnit == "Months" ? duration * 30 : duration;

    setState(() => _isSubmitting = true);

    try {
      if (variant == null) {
        // ✅ INSERT variant baru
        await service.supabase.from('product_variants').insert({
          "product_id": product['id'],
          "type": _typeController.text.trim(),
          "price": price,
          "modal_price": modal,
          "duration_days": durationInDays,
          "is_active": true,
        });
      } else {
        // ✅ UPDATE variant existing
        await service.updateVariant(variant!['id'], {
          "type": _typeController.text.trim(),
          "price": price,
          "modal_price": modal,
          "duration_days": durationInDays,
        });
      }

      if (!mounted) return;
      _showSnackBar(
        variant == null
            ? 'Variant berhasil ditambahkan!'
            : 'Variant berhasil diperbarui!',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ────────────────────────────────────────────
  // DELETE VARIANT
  // ────────────────────────────────────────────
  Future<void> _delete() async {
    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await service.deleteVariant(variant!['id']);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<bool?> _showConfirmDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
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
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Hapus Variant?",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Variant ini akan dihapus permanen dan tidak bisa dikembalikan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Hapus",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
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
    final isEdit = variant != null;

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
                          isEdit ? "Edit Variant" : "Tambah Variant",
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
                          // HEADER TEXT
                          // ─────────────────────
                          Text(
                            isEdit
                                ? "Edit Subscription\nTier"
                                : "Tambah Subscription\nTier Baru",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Atur harga, durasi, dan tipe subscription.",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // BANNER GRADIENT
                          // ─────────────────────
                          _buildBanner(theme, isDark, isEdit),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // FORM CARD
                          // ─────────────────────
                          _sectionLabel("INFORMASI VARIANT", theme),
                          const SizedBox(height: 12),
                          _buildFormCard(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // PREVIEW CARD
                          // ─────────────────────
                          _sectionLabel("PREVIEW VARIANT", theme),
                          const SizedBox(height: 12),
                          _buildPreviewCard(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // DELETE BUTTON (edit only)
                          // ─────────────────────
                          if (isEdit) ...[
                            _buildDeleteButton(theme, isDark),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM SAVE BUTTON
                  // ──────────────────────────────
                  _buildBottomBar(theme, isDark, isEdit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // BANNER GRADIENT
  // ────────────────────────────────────────────
  Widget _buildBanner(ThemeData theme, bool isDark, bool isEdit) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isEdit
              ? [
                  const Color(0xFF6F5FEA),
                  const Color(0xFF5AF9F3),
                ]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isEdit ? "MODE EDIT" : "MODE TAMBAH",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEdit
                      ? "Perbarui data variant yang ada"
                      : "Buat tier subscription baru",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(
              isEdit
                  ? Icons.edit_note_rounded
                  : Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // FORM CARD — glassmorphism konsisten
  // ────────────────────────────────────────────
  Widget _buildFormCard(ThemeData theme, bool isDark) {
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
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant Name
          _fieldLabel("NAMA VARIANT", theme),
          _inputField(
            hint: "Contoh: Standard, Premium, VIP",
            controller: _typeController,
            icon: Icons.label_outline_rounded,
            theme: theme,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          // Price
          _fieldLabel("HARGA JUAL", theme),
          _inputField(
            hint: "Contoh: 150000",
            controller: _priceController,
            icon: Icons.payments_outlined,
            theme: theme,
            isDark: isDark,
            isNumber: true,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          // Modal Price
          _fieldLabel("HARGA MODAL (OPSIONAL)", theme),
          _inputField(
            hint: "Kosongkan jika tidak ada",
            controller: _modalPriceController,
            icon: Icons.account_balance_wallet_outlined,
            theme: theme,
            isDark: isDark,
            isNumber: true,
          ),

          const SizedBox(height: 16),

          // Duration + unit
          _fieldLabel("DURASI", theme),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _inputField(
                  hint: "Contoh: 30",
                  controller: _durationController,
                  icon: Icons.timer_outlined,
                  theme: theme,
                  isDark: isDark,
                  isNumber: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildDropdown(theme, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, ThemeData theme) {
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

  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
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
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _durationUnit,
          isExpanded: true,
          dropdownColor: isDark
              ? const Color(0xFF111124)
              : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            size: 20,
          ),
          items: ["Days", "Months"].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (v) => setState(() => _durationUnit = v!),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // PREVIEW CARD — live update saat ketik
  // ────────────────────────────────────────────
  Widget _buildPreviewCard(ThemeData theme, bool isDark) {
    final typeName = _typeController.text.isNotEmpty
        ? _typeController.text
        : 'Nama Variant';
    final priceVal = _priceController.text.isNotEmpty
        ? _formatPreviewPrice(_priceController.text)
        : '-';
    final durasiVal = _durationController.text.isNotEmpty
        ? '${_durationController.text} $_durationUnit'
        : '-';

    final badgeColor = _getBadgeColorFromUnit(_durationUnit, theme);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.secondary.withValues(alpha: 0.08),
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.06),
                  theme.colorScheme.secondary.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: badgeColor.withValues(alpha: 0.15),
              border:
                  Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 22,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  durasiVal,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              "Rp $priceVal",
              key: ValueKey(priceVal),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPreviewPrice(String raw) {
    final num = int.tryParse(raw) ?? 0;
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

  Color _getBadgeColorFromUnit(String unit, ThemeData theme) {
    if (unit == "Months") return Colors.amber;
    return theme.colorScheme.primary;
  }

  // ────────────────────────────────────────────
  // DELETE BUTTON
  // ────────────────────────────────────────────
  Widget _buildDeleteButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _isDeleting ? null : _delete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          color: Colors.redAccent.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.35),
          ),
        ),
        child: Center(
          child: _isDeleting
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
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Hapus Variant Ini",
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
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM SAVE BAR
  // ────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme, bool isDark, bool isEdit) {
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
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            gradient: _isSubmitting
                ? LinearGradient(colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.5),
                    theme.colorScheme.secondary.withValues(alpha: 0.5),
                  ])
                : LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
            boxShadow: _isSubmitting
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
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEdit
                            ? Icons.save_outlined
                            : Icons.add_circle_outline_rounded,
                        size: 18,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? "Simpan Perubahan" : "Tambah Variant",
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
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
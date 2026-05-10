import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../widgets/inputs/no_emoji_formatter.dart';
import '../../services/claims_service.dart';

class GaransiFormPage extends StatefulWidget {
  const GaransiFormPage({super.key});

  @override
  State<GaransiFormPage> createState() => _GaransiFormPageState();
}

class _GaransiFormPageState extends State<GaransiFormPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final service = ClaimsService();

  final _descController = TextEditingController();

  String selectedReason = "Cannot login";
  XFile? pickedFile;
  Uint8List? imageBytes;
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final reasons = [
    ("Cannot login", Icons.lock_outline),
    ("Account expired early", Icons.timer_off_outlined),
    ("Wrong account", Icons.person_off_outlined),
    ("Other problem", Icons.help_outline_rounded),
  ];

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
    _descController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────
  // SNACKBAR
  // ─────────────────────────────────
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      _showSnackBar('Hanya file JPG, JPEG, PNG yang diperbolehkan',
          isError: true);
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      _showSnackBar('Ukuran file maksimal 5MB', isError: true);
      return;
    }

    setState(() {
      pickedFile = picked;
      imageBytes = bytes;
    });
  }

  Future<void> _submitClaim(Map order) async {
    FocusScope.of(context).unfocus();

    if (_descController.text.trim().isEmpty) {
      _showSnackBar('Deskripsi masalah wajib diisi', isError: true);
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      String? uploadedUrl;

      if (imageBytes != null && pickedFile != null) {
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage
            .from('claim-proofs')
            .uploadBinary(fileName, imageBytes!);
        uploadedUrl = supabase.storage
            .from('claim-proofs')
            .getPublicUrl(fileName);
      }

      await service.createClaim(
        orderId: order['id'],
        userId: user.id,
        title: selectedReason,                    
        description: _descController.text.trim(), 
        imageUrl: uploadedUrl,
      );

      if (!mounted) return;

      _showSnackBar('Laporan berhasil dikirim!', isError: false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final order = ModalRoute.of(context)?.settings.arguments as Map;
    final imageUrl = order['products']?['image'];

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
                          "Ajukan Garansi",
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─────────────────────
                          // HEADER PRODUK
                          // ─────────────────────
                          _buildProductCard(
                              context, theme, isDark, order, imageUrl),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // PILIH KENDALA
                          // ─────────────────────
                          _sectionLabel("PILIH KENDALA", theme),
                          const SizedBox(height: 6),
                          Text(
                            "Beritahu kami masalah yang kamu alami",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildReasonList(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // DETAIL MASALAH
                          // ─────────────────────
                          _sectionLabel("DETAIL MASALAH", theme),
                          const SizedBox(height: 12),
                          _buildDescriptionField(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // UNGGAH BUKTI
                          // ─────────────────────
                          _sectionLabel("UNGGAH BUKTI", theme),
                          const SizedBox(height: 12),
                          _buildUploadArea(theme, isDark),

                          const SizedBox(height: 20),

                          // ─────────────────────
                          // WARNING BANNER
                          // ─────────────────────
                          _buildWarningBanner(theme),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM SUBMIT BUTTON
                  // ──────────────────────────────
                  _buildBottomBar(context, theme, isDark, order),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // PRODUCT HEADER CARD
  // ────────────────────────────────────────────
  Widget _buildProductCard(BuildContext context, ThemeData theme, bool isDark,
      Map order, dynamic imageUrl) {
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
          // Thumbnail
          Container(
            width: 64,
            height: 64,
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
            child: (imageUrl != null && imageUrl.toString().isNotEmpty)
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      size: 26,
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    size: 26,
                  ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "PREMIUM SUBSCRIPTION",
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
                  order['product_name'] ?? '-',
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
                  "Variant: ${order['variant_type'] ?? '-'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Shield icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.green,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // REASON LIST
  // ────────────────────────────────────────────
  Widget _buildReasonList(ThemeData theme, bool isDark) {
    return Column(
      children: reasons.map((r) {
        final isSelected = selectedReason == r.$1;

        return GestureDetector(
          onTap: () => setState(() => selectedReason = r.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: isSelected
                    ? isDark
                        ? [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.secondary
                                .withValues(alpha: 0.1),
                          ]
                        : [
                            theme.colorScheme.primary.withValues(alpha: 0.07),
                            theme.colorScheme.secondary
                                .withValues(alpha: 0.04),
                          ]
                    : isDark
                        ? [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.02),
                          ]
                        : [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                width: isSelected ? 1.5 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Ikon alasan
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    r.$2,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    r.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // Checkmark
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Container(
                          key: const ValueKey('check'),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        )
                      : Container(
                          key: const ValueKey('empty'),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ────────────────────────────────────────────
  // DESCRIPTION FIELD
  // ────────────────────────────────────────────
  Widget _buildDescriptionField(ThemeData theme, bool isDark) {
    return TextField(
      controller: _descController,
      maxLines: 4,
      inputFormatters: [NoEmojiFormatter()], // ✅ FIX: block emoji
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: "Deskripsikan kejadian yang kamu alami...",
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
  // UPLOAD AREA
  // ────────────────────────────────────────────
  Widget _buildUploadArea(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: imageBytes != null ? 180 : 130,
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
          ),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes!, fit: BoxFit.cover),
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.25),
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
                    "Upload Screenshot",
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
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // WARNING BANNER
  // ────────────────────────────────────────────
  Widget _buildWarningBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.amber,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Perhatian",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Klaim akan diproses dalam 1×24 jam. Pastikan semua data yang kamu isi sudah benar.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM BAR
  // ────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context, ThemeData theme, bool isDark, Map order) {
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
        onTap: _isSubmitting ? null : () => _submitClaim(order),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            gradient: _isSubmitting
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
            boxShadow: _isSubmitting
                ? []
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
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
                      Text(
                        "Kirim Laporan Klaim",
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // SECTION LABEL 
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
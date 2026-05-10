import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';

class AdminAddProductPage extends StatefulWidget {
  const AdminAddProductPage({super.key});

  @override
  State<AdminAddProductPage> createState() => _AdminAddProductPageState();
}

class _AdminAddProductPageState extends State<AdminAddProductPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedCategory = "Streaming";
  XFile? pickedFile;
  Uint8List? imageBytes;
  bool _isSaving = false;

  // ✅ Animasi konsisten dengan seluruh halaman
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<(String, IconData)> _categories = [
    ("Streaming", Icons.play_circle_outline_rounded),
    ("Music", Icons.music_note_outlined),
    ("Study", Icons.school_outlined),
    ("Editing", Icons.edit_outlined),
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
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
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
  // PICK IMAGE
  // ────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'svg'].contains(ext)) {
      _showSnackBar('Hanya JPG, PNG, SVG yang diperbolehkan',
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

  // ────────────────────────────────────────────
  // UPLOAD IMAGE
  // ────────────────────────────────────────────
  Future<String?> _uploadImage() async {
    if (pickedFile == null) return null;
    final fileName =
        'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await pickedFile!.readAsBytes();
    await supabase.storage
        .from('netflix')
        .uploadBinary(fileName, bytes);
    return supabase.storage
        .from('netflix')
        .getPublicUrl(fileName);
  }

  // ────────────────────────────────────────────
  // VALIDASI & SAVE
  // ────────────────────────────────────────────
  Future<void> _saveProduct() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama produk wajib diisi', isError: true);
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

    setState(() => _isSaving = true);

    try {
      final imageUrl = await _uploadImage();

      // INSERT produk
      final product = await supabase.from('products').insert({
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "image": imageUrl,
        "category": _selectedCategory,
        "is_active": true,
      }).select().single();

      // INSERT variant default
      await supabase.from('product_variants').insert({
        "product_id": product['id'],
        "type": "Default",
        "price": price,
        "duration_days": duration,
        "is_active": true,
      });

      if (!mounted) return;
      _showSnackBar('Produk berhasil ditambahkan!', isError: false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                    AppConstants.darkBg1,
                    AppConstants.darkBg2,
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
                        horizontal: AppConstants.paddingH, vertical: 16),
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
                          "Tambah Produk",
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─────────────────────
                          // HEADER TEXT
                          // ─────────────────────
                          Text(
                            "Produk\nBaru",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Isi data produk dan variant defaultnya.",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // IMAGE UPLOAD
                          // ─────────────────────
                          _sectionLabel("GAMBAR PRODUK", theme),
                          const SizedBox(height: 12),
                          _buildImageUpload(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // FORM CARD
                          // ─────────────────────
                          _sectionLabel("INFORMASI PRODUK", theme),
                          const SizedBox(height: 12),
                          _buildFormCard(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // CATEGORY PICKER
                          // ─────────────────────
                          _sectionLabel("KATEGORI", theme),
                          const SizedBox(height: 12),
                          _buildCategoryPicker(theme, isDark),

                          const SizedBox(height: 24),

                          // ─────────────────────
                          // VARIANT DEFAULT
                          // ─────────────────────
                          _sectionLabel("VARIANT DEFAULT", theme),
                          const SizedBox(height: 6),
                          Text(
                            "Variant tambahan bisa ditambah setelah produk disimpan.",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildVariantCard(theme, isDark),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ──────────────────────────────
                  // BOTTOM SAVE BUTTON
                  // ──────────────────────────────
                  _buildBottomBar(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // IMAGE UPLOAD AREA — konsisten PaymentPage
  // ────────────────────────────────────────────
  Widget _buildImageUpload(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: imageBytes != null ? 200 : 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : theme.colorScheme.primary.withValues(alpha: 0.03),
          border: Border.all(
            color: imageBytes != null
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    // Overlay ganti
                    Positioned(
                      bottom: 12,
                      right: 12,
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
                              "Ganti Foto",
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Upload Gambar Produk",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "SVG, PNG, JPG • Maks 5MB",
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
  // FORM CARD — nama & deskripsi
  // ────────────────────────────────────────────
  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("NAMA PRODUK", theme),
          _inputField(
            hint: "Contoh: Netflix Premium",
            controller: _nameController,
            icon: Icons.inventory_2_outlined,
            theme: theme,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _fieldLabel("DESKRIPSI", theme),
          _inputField(
            hint: "Deskripsikan fitur dan ketentuan subscription...",
            controller: _descController,
            icon: Icons.description_outlined,
            theme: theme,
            isDark: isDark,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // CATEGORY PICKER — pill selector visual
  // ────────────────────────────────────────────
  Widget _buildCategoryPicker(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(theme, isDark),
      child: Column(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isSelected
                    ? LinearGradient(
                        colors: isDark
                            ? [
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.22),
                                theme.colorScheme.secondary
                                    .withValues(alpha: 0.12),
                              ]
                            : [
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                                theme.colorScheme.secondary
                                    .withValues(alpha: 0.04),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade100,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                  width: isSelected ? 1.5 : 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Icon kategori
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.15)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.35)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      cat.$2,
                      size: 17,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.$1,
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
      ),
    );
  }

  // ────────────────────────────────────────────
  // VARIANT DEFAULT CARD
  // ────────────────────────────────────────────
  Widget _buildVariantCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.amber.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  "Tipe variant: Default",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel("HARGA (Rp)", theme),
                    _inputField(
                      hint: "Contoh: 150000",
                      controller: _priceController,
                      icon: Icons.payments_outlined,
                      theme: theme,
                      isDark: isDark,
                      isNumber: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Durasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel("DURASI (HARI)", theme),
                    _inputField(
                      hint: "Contoh: 30",
                      controller: _durationController,
                      icon: Icons.timer_outlined,
                      theme: theme,
                      isDark: isDark,
                      isNumber: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Preview harga live
          if (_priceController.text.isNotEmpty ||
              _durationController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
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
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_nameController.text.isNotEmpty ? _nameController.text : 'Produk'} • ${_durationController.text.isNotEmpty ? '${_durationController.text} Hari' : '-'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                if (_priceController.text.isNotEmpty)
                  Text(
                    "Rp ${_formatPrice(_priceController.text)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // BOTTOM SAVE BAR
  // ────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingH, 16, AppConstants.paddingH, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppConstants.darkBg1.withValues(alpha: 0.0),
                  AppConstants.darkBg1,
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
        onTap: _isSaving ? null : _saveProduct,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            gradient: _isSaving
                ? LinearGradient(colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.5),
                    theme.colorScheme.secondary.withValues(alpha: 0.5),
                  ])
                : LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
            boxShadow: _isSaving
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
            child: _isSaving
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
                        Icons.save_outlined,
                        size: 18,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Simpan Produk",
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
  // HELPERS
  // ────────────────────────────────────────────
  BoxDecoration _glassDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
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
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : maxLines > 1
              ? TextInputType.multiline
              : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        prefixIcon: maxLines == 1
            ? Icon(icon,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.6))
            : null,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
      ),
    );
  }

  String _formatPrice(String raw) {
    final num = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
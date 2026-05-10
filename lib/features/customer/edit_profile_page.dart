import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPasswordVisible = false;

  // ✅ Animasi fade + slide konsisten dengan Login & Register
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
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('users')
          .select('name, email, phone')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _isLoading = false;
      });

      // Animasi mulai setelah data masuk
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat data profil', isError: true);
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    // ✅ Validasi tidak boleh kosong
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnackBar('Nama, email, dan nomor WA wajib diisi', isError: true);
      return;
    }

    // ✅ Validasi email pakai regex
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Format email tidak valid', isError: true);
      return;
    }

    // ✅ Validasi phone
    final phone = _phoneController.text.trim();
    if (!phone.startsWith('08') || phone.length < 10) {
      _showSnackBar(
        'Nomor WA harus diawali 08 dan minimal 10 digit',
        isError: true,
      );
      return;
    }

    // ✅ Validasi password jika diisi
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.trim().length < 6) {
      _showSnackBar('Password baru minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      }).eq('id', user.id);

      if (_passwordController.text.trim().isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim()),
        );
      }

      if (!mounted) return;

      _showSnackBar('Profil berhasil diperbarui!', isError: false);
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
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [

                        // ─────────────────────────────
                        // APPBAR CUSTOM
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
                                "Edit Profile",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              // Placeholder biar title tetap center
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
                              children: [

                                // ─────────────────────
                                // AVATAR + INFO HEADER
                                // ─────────────────────
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Aura luar
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            theme.colorScheme.primary
                                                .withValues(alpha: 0.2),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Foto
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.4),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Image.asset(
                                        'assets/images/profile.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // ✅ Edit badge di pojok kanan bawah
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF0A0A14)
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // ✅ Nama & email live update saat mengetik
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _emailController.text.isNotEmpty
                                      ? _emailController.text
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // ─────────────────────
                                // FORM CARD
                                // ─────────────────────
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              Colors.white
                                                  .withValues(alpha: 0.06),
                                              Colors.white
                                                  .withValues(alpha: 0.02),
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
                                          ? Colors.white
                                              .withValues(alpha: 0.08)
                                          : Colors.black
                                              .withValues(alpha: 0.04),
                                    ),
                                    boxShadow: isDark
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 30,
                                              offset: const Offset(0, 10),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.07),
                                              blurRadius: 24,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      _label("FULL NAME"),
                                      _input(
                                        "Nama lengkap",
                                        controller: _nameController,
                                        icon: Icons.person_outline,
                                        inputType: TextInputType.name,
                                      ),

                                      const SizedBox(height: 16),

                                      _label("EMAIL ADDRESS"),
                                      _input(
                                        "your@email.com",
                                        controller: _emailController,
                                        icon: Icons.mail_outline,
                                        inputType: TextInputType.emailAddress,
                                      ),

                                      const SizedBox(height: 16),

                                      _label("WHATSAPP"),
                                      _input(
                                        "08xxxxxxxxxx",
                                        controller: _phoneController,
                                        icon: Icons.phone_outlined,
                                        inputType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      _label("NEW PASSWORD (OPTIONAL)"),
                                      _input(
                                        "Kosongkan jika tidak diubah",
                                        controller: _passwordController,
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                      ),

                                      const SizedBox(height: 28),

                                      // Button / Loading
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                            milliseconds: 300),
                                        child: _isSaving
                                            ? Center(
                                                key: const ValueKey('saving'),
                                                child: SizedBox(
                                                  height: 55,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 12),
                                                      Text(
                                                        "Menyimpan...",
                                                        style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                  alpha: 0.6),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : _button(theme, isDark),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),
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
  // WIDGET HELPERS — konsisten 100%
  // ─────────────────────────────────────

  Widget _label(String text) {
    final theme = Theme.of(context);
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

  Widget _input(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      // ✅ Live update nama & email di header saat mengetik
      onChanged: isPassword ? null : (_) => setState(() {}),
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
        suffixIcon: isPassword
            ? GestureDetector(
                onTapDown: (_) =>
                    setState(() => _isPasswordVisible = true),
                onTapUp: (_) =>
                    setState(() => _isPasswordVisible = false),
                onTapCancel: () =>
                    setState(() => _isPasswordVisible = false),
                child: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              )
            : null,
      ),
    );
  }

  Widget _button(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _saveChanges,
      child: Container(
        height: 55,
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
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Simpan Perubahan",
            style: TextStyle(
              color: isDark ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
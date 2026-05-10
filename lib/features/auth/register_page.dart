  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import '../../core/constants.dart';
  import '../../services/auth_service.dart';
  import '../../widgets/inputs/no_emoji_formatter.dart';

  class RegisterPage extends StatefulWidget {
    const RegisterPage({super.key});

    @override
    State<RegisterPage> createState() => _RegisterPageState();
  }

  class _RegisterPageState extends State<RegisterPage>
      with SingleTickerProviderStateMixin {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _passwordController = TextEditingController();

    bool _isLoading = false;

    // ✅ FIX: Pisah visibility per field agar tidak konflik
    bool _isPasswordVisible = false;

    // ✅ FIX: Validasi email lebih proper pakai regex
    bool _isValidEmail(String email) {
      final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      return regex.hasMatch(email);
    }

    bool _isValidPhone(String phone) {
      return phone.startsWith("08") && phone.length >= 10 && phone.length <= 15;
    }

    // ✅ FIX: Animasi fade-in saat halaman muncul
    late AnimationController _animController;
    late Animation<double> _fadeAnim;
    late Animation<Offset> _slideAnim;

    final _authService = AuthService();

    @override
    void initState() {
      super.initState();
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
      _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.07),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
      _animController.forward();
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

    Future<void> _register() async {
      // Tutup keyboard
      FocusScope.of(context).unfocus();

      // Validasi kosong
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _showSnackBar("Semua field wajib diisi", isError: true);
        return;
      }

      // ✅ FIX: Validasi email pakai regex
      if (!_isValidEmail(_emailController.text.trim())) {
        _showSnackBar("Format email tidak valid", isError: true);
        return;
      }

      // Validasi nomor WA
      if (!_isValidPhone(_phoneController.text.trim())) {
        _showSnackBar(
          "Nomor WA harus diawali 08 dan minimal 10 digit",
          isError: true,
        );
        return;
      }

      // Validasi password minimal 6 karakter
      if (_passwordController.text.trim().length < 6) {
        _showSnackBar("Password minimal 6 karakter", isError: true);
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _authService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        _showSnackBar("Akun berhasil dibuat!", isError: false);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        // ✅ FIX: Hapus print() — tampilkan error ke user saja
        _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Scaffold(
        // ✅ Transparan agar gradient terlihat sampai status bar
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ─────────────────────────────
                        // NAVBAR
                        // ─────────────────────────────
                        Row(
                          children: [
                            // ✅ Tombol back yang proper
                            if (Navigator.canPop(context))
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
                            Icon(
                              Icons.blur_on,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "ARNN.APPREM",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.8,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ─────────────────────────────
                        // LOGO — lebih impactful
                        // ─────────────────────────────
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Lingkaran aura luar
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
                            // Lingkaran border
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
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ─────────────────────────────
                        // HEADING
                        // ─────────────────────────────
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Daftar dan mulai gunakan layanan premium",
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // ─────────────────────────────
                        // FORM CARD
                        // ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withValues(alpha: 0.06),
                                      Colors.white.withValues(alpha: 0.02),
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
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.07),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                // Hanya angka
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),

                              const SizedBox(height: 16),

                              _label("PASSWORD"),
                              _input(
                                "Minimal 6 karakter",
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              const SizedBox(height: 28),

                              // ─────────────────────────
                              // BUTTON / LOADING
                              // ─────────────────────────
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isLoading
                                    ? Center(
                                        key: const ValueKey('loading'),
                                        child: SizedBox(
                                          height: 55,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Membuat akun...",
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _button(theme, isDark),
                              ),

                              const SizedBox(height: 16),

                              // ─────────────────────────
                              // LOGIN LINK
                              // ─────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sudah punya akun?",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/login'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ─────────────────────────────────────
    // WIDGET HELPERS
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
        inputFormatters: [
          NoEmojiFormatter(), // ✅ FIX: block emoji
          if (inputFormatters != null) ...inputFormatters,
        ],
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
          // ✅ Icon prefix per field
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
          // Eye icon hanya untuk password
          suffixIcon: isPassword
    ? GestureDetector(
        onTap: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
        child: Icon(
          _isPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 18,
          color:
              theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      )
    : null,
        ),
      );
    }

    // ✅ FIX: withValues bukan withOpacity
    Widget _button(ThemeData theme, bool isDark) {
      return GestureDetector(
        onTap: _register,
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
              "Daftar Sekarang",
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
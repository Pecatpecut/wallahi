import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../core/theme_controller.dart';
import '../../widgets/inputs/no_emoji_formatter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Email & password wajib diisi", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;

      String message = "Terjadi kesalahan, coba lagi";
      if (e.toString().contains("Invalid login credentials")) {
        message = "Email atau password salah";
      } else if (e.toString().contains("missing email")) {
        message = "Email wajib diisi";
      }

      _showSnackBar(message, isError: true);
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: screenHeight),
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
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.paddingH,
                    20,
                    AppConstants.paddingH,
                    MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── NAVBAR ──
                      Row(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.blur_on,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Get.find<ThemeController>().toggleTheme();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ Jarak atas adaptif — iPhone SE lebih kecil
                      SizedBox(height: screenHeight < 700 ? 24 : 48),

                      // ── LOGO ──
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
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

                      // ── HEADING ──
                      Text(
                        "ARNN.APPREM",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "˗ˏˋ apps premium by arnn 🐰 ࿐ྂ",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // ── FORM CARD ──
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppConstants.dialogRadius,
                          ),
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
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.07),
                              blurRadius: isDark ? 30 : 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Masuk ke akun kamu untuk melanjutkan.",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            _label("EMAIL ADDRESS"),
                            _input(
                              "your@email.com",
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              inputType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 16),

                            _label("PASSWORD"),
                            _input(
                              "Masukkan password",
                              controller: _passwordController,
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),

                            const SizedBox(height: 28),

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
                                              "Sedang masuk...",
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Belum punya akun?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Daftar",
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
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: inputType,
      inputFormatters: [NoEmojiFormatter()], // ✅ FIX: block emoji
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
          vertical: 16,
        ),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                child: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            : null,
      ),
    );
  }

  Widget _button(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _login,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
            "Masuk Sekarang",
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

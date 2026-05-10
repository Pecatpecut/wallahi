import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/shared/status_badge.dart';

class GaransiDetailPage extends StatefulWidget {
  const GaransiDetailPage({super.key});

  @override
  State<GaransiDetailPage> createState() => _GaransiDetailPageState();
}

class _GaransiDetailPageState extends State<GaransiDetailPage>
    with SingleTickerProviderStateMixin {
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
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    // ✅ Animasi langsung saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ModalRoute.of(context)?.settings.arguments as Map?;

    if (data == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    final product = data['orders']?['product_name'] ?? "Premium";
    final variant = data['orders']?['variant_type'] ?? "";
    final imageUrl = data['orders']?['products']?['image'];

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg1 : Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // ✅ Gradient background identik dengan EditProfilePage
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
                          "Detail Garansi",
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── HEADER CARD ──
                          _headerCard(data, product, variant, theme, isDark),
                          const SizedBox(height: 16),

                          // ── INFO GRID ──
                          _infoGrid(data, theme, isDark),
                          const SizedBox(height: 20),

                          // ── DESKRIPSI ──
                          _sectionLabel("Deskripsi Masalah", theme),
                          const SizedBox(height: 10),
                          _descriptionBox(data, theme, isDark),
                          const SizedBox(height: 20),

                          // ── BUKTI FOTO ──
                          _sectionLabel("Bukti Foto", theme),
                          const SizedBox(height: 10),
                          _proofImage(imageUrl, data, theme, isDark),
                          const SizedBox(height: 20),

                          // ── TIMELINE ──
                          _sectionLabel("Progress Klaim", theme),
                          const SizedBox(height: 10),
                          _timelineCard(data, theme, isDark),
                          const SizedBox(height: 20),

                          // ── CATATAN ADMIN ──
                          _sectionLabel("Catatan Admin", theme),
                          const SizedBox(height: 10),
                          _adminResolution(data, theme),
                          const SizedBox(height: 20),

                          // ── FOOTER STATUS ──
                          _footerStrip(data, theme),
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
  // WIDGET HELPERS
  // ─────────────────────────────────────

  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: theme.colorScheme.primary.withValues(alpha: 0.75),
      ),
    );
  }

  // ── GLASS CARD DECORATION (reusable) ──
  BoxDecoration _glassCard(ThemeData theme, bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
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
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  Widget _headerCard(
    Map data,
    String product,
    String variant,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1B1B2F), Color(0xFF23233A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.primary.withValues(alpha: 0.03),
                ],
              ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACTIVE CLAIM",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              StatusBadge(status: data['status']),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['title'] ?? "–",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "#${data['id']}",
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // ✅ Product mini card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        variant.isNotEmpty
                            ? "$variant · Garansi s/d Des 2025"
                            : "Garansi s/d Des 2025",
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(Map data, ThemeData theme, bool isDark) {
    final cells = [
      {"label": "Tanggal Klaim", "value": data['created_at']?.toString().substring(0, 10) ?? "–"},
      {"label": "Status", "value": data['status'] ?? "–"},
      {"label": "Tipe Klaim", "value": data['claim_type'] ?? "Hardware"},
      {"label": "Estimasi", "value": "3–5 hari"},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: cells.map((cell) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cell["label"]!.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cell["value"]!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _descriptionBox(Map data, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        data['problem_description'] ?? "–",
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _proofImage(
    String? imageUrl,
    Map data,
    ThemeData theme,
    bool isDark,
  ) {
    final proofUrl = data['proof_image'] as String?;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: proofUrl != null && proofUrl.isNotEmpty
          ? Image.network(
              proofUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _noImageBox(theme, isDark),
            )
          : _noImageBox(theme, isDark),
    );
  }

  Widget _noImageBox(ThemeData theme, bool isDark) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak ada gambar tersedia",
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineCard(Map data, ThemeData theme, bool isDark) {
    final status = data['status'] ?? 'pending';
    final steps = [
      {
        'title': 'Klaim Diajukan',
        'sub': data['created_at']?.toString().substring(0, 10) ?? '–',
        'done': true,
      },
      {
        'title': 'Verifikasi Admin',
        'sub': 'Klaim telah diterima',
        'done': status != 'pending',
      },
      {
        'title': 'Sedang Diproses',
        'sub': 'Estimasi 3–5 hari kerja',
        'done': status == 'approved' || status == 'rejected',
        'active': status == 'in_progress',
      },
      {
        'title': 'Selesai',
        'sub': status == 'approved'
            ? 'Klaim disetujui'
            : status == 'rejected'
                ? 'Klaim ditolak'
                : 'Menunggu proses',
        'done': status == 'approved' || status == 'rejected',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _glassCard(theme, isDark),
      child: Column(
        children: List.generate(steps.length, (i) {
          final s = steps[i];
          final isLast = i == steps.length - 1;
          final isDone = s['done'] as bool;
          final isActive = (s['active'] ?? false) as bool;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF5DCAA5)
                            : isActive
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF5DCAA5)
                              : isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1.5,
                        height: 36,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.1),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 20,
                    top: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDone || isActive
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['sub'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _adminResolution(Map data, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent_outlined,
                size: 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                "Live Update",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['admin_note'] ??
                "Tim kami sedang memproses klaim Anda. Teknisi akan menghubungi melalui nomor WhatsApp yang terdaftar dalam waktu 1×24 jam.",
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerStrip(Map data, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              "Tim sedang memproses klaim Anda",
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Text(
              "Menunggu",
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  // ── Data rules ──────────────────────────────────
  static const _sections = [
    {
      "icon": Icons.calendar_month_outlined,
      "title": "General Rules",
      "subtitle": "Aturan Umum",
      "color": 0xFF7F77DD,
      "bgColor": 0x1A7F77DD,
      "badge": "4 rules",
      "items": [
        "Payment dilakukan di awal sebelum layanan diaktifkan",
        "Tidak menerima refund dalam kondisi apapun",
        "Wajib mengikuti semua aturan yang berlaku",
        "Garansi berlaku sesuai ketentuan yang tertera",
      ],
      "bulletChar": null, // pakai nomor
    },
    {
      "icon": Icons.info_outline,
      "title": "Important Notes",
      "subtitle": "Catatan Penting",
      "color": 0xFF5DCAA5,
      "bgColor": 0x1A1D9E75,
      "badge": "3 notes",
      "items": [
        "Tidak melayani service atau perbaikan perangkat",
        "Jika tidak bisa login, cek device terlebih dahulu sebelum menghubungi admin",
        "Harap bersabar dan ikuti antrian yang berlaku",
      ],
      "bulletChar": null,
    },
    {
      "icon": Icons.warning_amber_rounded,
      "title": "Warning",
      "subtitle": "Larangan & Sanksi",
      "color": 0xFFEF9F27,
      "bgColor": 0x1ABA7517,
      "badge": "3 items",
      "items": [
        "Dilarang keras mengganti password tanpa seizin admin",
        "Pelanggaran aturan dapat menyebabkan akun diblokir permanen",
        "Kami tidak bertanggung jawab atas kelalaian yang dilakukan user",
      ],
      "bulletChar": "!", // pakai tanda seru
    },
  ];

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
          child: Column(
            children: [

              // ── APPBAR CUSTOM ──
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
                      "Rules & Terms",
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

              // ── CONTENT ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── HERO CARD ──
                      _heroCard(theme, isDark),
                      const SizedBox(height: 16),

                      // ── RULE CARDS ──
                      ..._sections.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ruleCard(
                            context: context,
                            theme: theme,
                            isDark: isDark,
                            section: s,
                          ),
                        );
                      }),

                      const SizedBox(height: 4),

                      // ── FOOTER NOTE ──
                      _footerNote(context, theme, isDark),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────

  Widget _heroCard(ThemeData theme, bool isDark) {
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
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shield icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Terms & Conditions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Harap baca dan pahami seluruh ketentuan sebelum melakukan pembelian di Arini Store.",
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          // Chips ringkasan
          Wrap(
            spacing: 8,
            children: [
              _heroBadge("3 Kategori", theme.colorScheme.primary, theme),
              _heroBadge("10 Aturan", const Color(0xFF5DCAA5), theme),
              _heroBadge("Wajib Dibaca", const Color(0xFFEF9F27), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _ruleCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Map section,
  }) {
    final accentColor = Color(section["color"] as int);
    final bgColor = Color(section["bgColor"] as int);
    final items = section["items"] as List<String>;
    final bulletChar = section["bulletChar"] as String?;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ✅ Accent bar di kiri
            Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── HEADER ──
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: bgColor,
                        ),
                        child: Icon(
                          section["icon"] as IconData,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section["title"] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              section["subtitle"] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: accentColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge jumlah item
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: bgColor,
                        ),
                        child: Text(
                          section["badge"] as String,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                  ),
                  const SizedBox(height: 12),

                  // ── ITEMS ──
                  ...List.generate(items.length, (i) {
                    final label = bulletChar ?? "${i + 1}";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: bgColor,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              items[i],
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerNote(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade100,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.support_agent_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ada pertanyaan?",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Hubungi admin melalui WhatsApp jika ada hal yang perlu dikonfirmasi sebelum pembelian.",
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 10),
                // ✅ Tombol WA langsung
                GestureDetector(
                  onTap: () async {
                    const phone = "6285349661585";
                    const message = "Halo admin, saya ingin bertanya tentang ketentuan di Arini Store";
                    final url = Uri.parse(
                      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 14,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Hubungi Admin",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
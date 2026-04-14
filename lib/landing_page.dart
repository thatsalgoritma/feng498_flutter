import 'package:flutter/material.dart';
import 'login_page.dart';
import 'business_login_page.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────
// Call LandingPage() as the home widget in your MaterialApp.
// ─────────────────────────────────────────────────────────────────────────────

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _featureFade;
  late final Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _heroFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _featureFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOut));
    _ctaFade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.7, 1.0, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginPage()));

  void _goSignUp() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginPage())); // opens on Sign Up tab

  void _goBusinessLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const BusinessLoginPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LandingTheme.bg,
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────────────────────
          const _BackgroundDecor(),

          SafeArea(
            child: Column(
              children: [
                // ── App Bar ────────────────────────────────────────────────
                _LandingAppBar(
                  onLogin: _goLogin,
                  onSignUp: _goSignUp,
                  onBusiness: _goBusinessLogin,
                ),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),

                        // Hero
                        FadeTransition(
                          opacity: _heroFade,
                          child: SlideTransition(
                            position: _heroSlide,
                            child: const _HeroSection(),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Features
                        FadeTransition(
                          opacity: _featureFade,
                          child: const _FeaturesSection(),
                        ),

                        const SizedBox(height: 48),

                        // How it works
                        FadeTransition(
                          opacity: _featureFade,
                          child: const _HowItWorksSection(),
                        ),

                        const SizedBox(height: 48),

                        // CTA
                        FadeTransition(
                          opacity: _ctaFade,
                          child: _CtaSection(
                            onSignUp: _goSignUp,
                            onBusiness: _goBusinessLogin,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Footer
                        FadeTransition(
                          opacity: _ctaFade,
                          child: const _Footer(),
                        ),

                        const SizedBox(height: 32),
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

// ═════════════════════════════════════════════════════════════════════════════
// THEME  constants
// ═════════════════════════════════════════════════════════════════════════════

abstract class _LandingTheme {
  static const bg = Color(0xFFF4F7FF);
  static const blue = Color(0xFF1A73E8);
  static const blueDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF00C9A7); // teal-green accent
  static const textDark = Color(0xFF0D1B3E);
  static const textMid = Color(0xFF4A5568);
  static const textLight = Color(0xFF8A97B0);
  static const card = Colors.white;

  static const gradient = LinearGradient(
    colors: [blue, blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF0094C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// BACKGROUND DECORATIONS
// ═════════════════════════════════════════════════════════════════════════════

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Stack(children: [
      // Top-right blob
      Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: w * 0.7,
          height: w * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF1A73E8).withOpacity(0.08),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      // Bottom-left blob
      Positioned(
        bottom: 60,
        left: -60,
        child: Container(
          width: w * 0.55,
          height: w * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF00C9A7).withOpacity(0.07),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// APP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _LandingAppBar extends StatelessWidget {
  final VoidCallback onLogin, onSignUp, onBusiness;
  const _LandingAppBar(
      {required this.onLogin,
      required this.onSignUp,
      required this.onBusiness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        const Text('PRICELY',
            style: TextStyle(
                color: _LandingTheme.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2.5)),
        const Spacer(),

        // Business login (subtle)
        TextButton(
          onPressed: onBusiness,
          style: TextButton.styleFrom(
            foregroundColor: _LandingTheme.textMid,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: const Text('For Business'),
        ),
        const SizedBox(width: 4),

        // Login
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: _LandingTheme.blue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Login',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),

        // Sign Up
        ElevatedButton(
          onPressed: onSignUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: _LandingTheme.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Sign Up',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 24),

      // Title
      RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
              color: _LandingTheme.textDark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5),
          children: [
            TextSpan(text: 'Find Local Businesses\n'),
            TextSpan(text: '& Compare '),
            TextSpan(
              text: 'Prices',
              style: TextStyle(color: _LandingTheme.blue),
            ),
            TextSpan(text: ' Instantly'),
          ],
        ),
      ),

      const SizedBox(height: 18),

      // Sub-heading
      const Text(
        'Pricely connects you with nearby shops,\nrestaurants, and services — so you always\nknow what to expect before you walk in.',
        textAlign: TextAlign.center,
        style:
            TextStyle(fontSize: 15, color: _LandingTheme.textMid, height: 1.65),
      ),

      const SizedBox(height: 32),

      // Hero illustration card
      Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(children: [
            // Grid pattern overlay
            CustomPaint(
              painter: _GridPainter(),
              child: const SizedBox.expand(),
            ),
            // Centered content
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 52),
                const SizedBox(height: 12),
                const Text('500+ Local Businesses',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('In your neighbourhood',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ]),
            ),
            // Floating stat pills
            Positioned(
              top: 20,
              right: 20,
              child: _FloatingPill(
                  icon: Icons.star_rounded,
                  label: '4.8 Avg',
                  color: const Color(0xFFFFC107)),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _FloatingPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FloatingPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

// Subtle dot-grid background painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// FEATURES SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    _FeatureData(
      icon: Icons.search_rounded,
      color: Color(0xFF1A73E8),
      title: 'Browse & Discover',
      body:
          'Explore hundreds of local shops, salons, cafes, and more — all in one place.',
    ),
    _FeatureData(
      icon: Icons.price_check_rounded,
      color: Color(0xFF00C9A7),
      title: 'Transparent Prices',
      body:
          'See real product and service prices upfront. No surprises when you arrive.',
    ),
    _FeatureData(
      icon: Icons.handshake_rounded,
      color: Color(0xFFFF6D00),
      title: 'Negotiate & Book',
      body:
          'Send price offers directly to businesses and book appointments in-app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel(label: 'WHY PRICELY'),
      const SizedBox(height: 8),
      const Text('Everything you need\nto shop smarter',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _LandingTheme.textDark,
              height: 1.2)),
      const SizedBox(height: 24),
      ..._features.map((f) => _FeatureCard(data: f)),
    ]);
  }
}

class _FeatureData {
  final IconData icon;
  final Color color;
  final String title, body;
  const _FeatureData(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _LandingTheme.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _LandingTheme.textDark)),
              const SizedBox(height: 4),
              Text(data.body,
                  style: const TextStyle(
                      fontSize: 13, color: _LandingTheme.textMid, height: 1.5)),
            ]),
          ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// HOW IT WORKS SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    _StepData(
        number: '01',
        title: 'Create your account',
        body:
            'Sign up in under a minute — just your name, email, and password.',
        icon: Icons.person_add_alt_1_rounded),
    _StepData(
        number: '02',
        title: 'Browse nearby businesses',
        body: 'Filter by category, check photos, prices, and reviews.',
        icon: Icons.map_rounded),
    _StepData(
        number: '03',
        title: 'Offer, book, or message',
        body:
            'Negotiate prices, book appointments, or chat directly with the business.',
        icon: Icons.chat_bubble_rounded),
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A73E8).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('HOW IT WORKS',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 14),
          const Text('Get started in\n3 simple steps',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
          const SizedBox(height: 28),
          ..._steps.asMap().entries.map((e) =>
              _StepRow(data: e.value, isLast: e.key == _steps.length - 1)),
        ]),
      );
}

class _StepData {
  final String number, title, body;
  final IconData icon;
  const _StepData(
      {required this.number,
      required this.title,
      required this.body,
      required this.icon});
}

class _StepRow extends StatelessWidget {
  final _StepData data;
  final bool isLast;
  const _StepRow({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(data.number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13))),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white.withOpacity(0.15),
              ),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(data.body,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 13,
                            height: 1.5)),
                  ]),
            ),
          ),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// STATS STRIP
// ═════════════════════════════════════════════════════════════════════════════

class _StatStrip extends StatelessWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: _LandingTheme.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          _stat('500+', 'Businesses'),
          _divider(),
          _stat('12K+', 'Users'),
          _divider(),
          _stat('4.8★', 'Rating'),
        ]),
      );

  Widget _stat(String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: _LandingTheme.blue)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: _LandingTheme.textLight)),
        ]),
      );

  Widget _divider() =>
      Container(width: 1, height: 32, color: const Color(0xFFE2E8F0));
}

// ═════════════════════════════════════════════════════════════════════════════
// CTA SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _CtaSection extends StatelessWidget {
  final VoidCallback onSignUp, onBusiness;
  const _CtaSection({required this.onSignUp, required this.onBusiness});

  @override
  Widget build(BuildContext context) => Column(children: [
        // Stats first
        const _StatStrip(),
        const SizedBox(height: 32),

        // CTA card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _LandingTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _LandingTheme.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Ready to explore?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _LandingTheme.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Join thousands of users discovering\nthe best local businesses today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: _LandingTheme.textMid, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LandingTheme.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Get Started — It\'s Free',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBusiness,
                icon: const Icon(Icons.business_center_outlined, size: 17),
                label: const Text('Register Your Business'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _LandingTheme.textDark,
                  side: const BorderSide(color: Color(0xFFCBD5E0)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// FOOTER
// ═════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Column(children: [
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: _LandingTheme.gradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
                child: Text('P',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13))),
          ),
          const SizedBox(width: 8),
          const Text('PRICELY',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _LandingTheme.textDark,
                  letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 10),
        const Text('© 2025 Pricely · All rights reserved',
            style: TextStyle(fontSize: 11, color: _LandingTheme.textLight)),
        const SizedBox(height: 4),
        const Text('Connecting you with the best local businesses',
            style: TextStyle(fontSize: 11, color: _LandingTheme.textLight)),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _LandingTheme.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _LandingTheme.blue,
                letterSpacing: 1.5)),
      );
}

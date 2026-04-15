import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'business_login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _floatingController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _placeholderTexts = [
    'Search for haircut, manicure, gym, tattoo...',
    'Find the best nail salon near you...',
    'Book a skin care appointment today...',
    'Explore gyms, clinics, cafes and more...',
  ];

  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    ));

    _heroController.forward();

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 12;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });

    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _placeholderIndex = (_placeholderIndex + 1) % _placeholderTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _floatingController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _placeholderTimer?.cancel();
    super.dispose();
  }

  void _goUserLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goUserSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(initialTab: 1)),
    );
  }

  void _goBusinessLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BusinessLoginPage()),
    );
  }

  void _fillSearch(String text) {
    setState(() {
      _searchController.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      body: Stack(
        children: [
          const _LandingBackground(),
          SafeArea(
            child: Column(
              children: [
                _LandingTopBar(
                  isScrolled: _isScrolled,
                  onUserLogin: _goUserLogin,
                  onUserSignup: _goUserSignup,
                  onBusinessLogin: _goBusinessLogin,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: _HeroSection(
                              floatingController: _floatingController,
                              searchController: _searchController,
                              placeholder: _placeholderTexts[_placeholderIndex],
                              onSearchTap: _goUserLogin,
                              onBusinessTap: _goBusinessLogin,
                              onQuickFill: _fillSearch,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _SplitCardsSection(),
                        const SizedBox(height: 28),
                        const _HowItWorksSection(),
                        const SizedBox(height: 28),
                        const _CategoriesSection(),
                        const SizedBox(height: 28),
                        const _FeaturesSection(),
                        const SizedBox(height: 28),
                        _BusinessSection(onBusinessTap: _goBusinessLogin),
                        const SizedBox(height: 28),
                        _AdsSection(onBusinessTap: _goBusinessLogin),
                        const SizedBox(height: 28),
                        _BottomCtaSection(
                          onUserTap: _goUserSignup,
                          onBusinessTap: _goBusinessLogin,
                        ),
                        const SizedBox(height: 28),
                        const _FooterSection(),
                        const SizedBox(height: 24),
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

class _LandingTopBar extends StatelessWidget {
  final bool isScrolled;
  final VoidCallback onUserLogin;
  final VoidCallback onUserSignup;
  final VoidCallback onBusinessLogin;

  const _LandingTopBar({
    required this.isScrolled,
    required this.onUserLogin,
    required this.onUserSignup,
    required this.onBusinessLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isScrolled
            ? const Color(0xFFF7F4F1).withOpacity(0.95)
            : const Color(0xFFF7F4F1).withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DDD7)),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: const Color(0xFF2B0D1A).withOpacity(0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF4A0019), Color(0xFF8A3E5D)],
              ),
            ),
            child: const Center(
              child: Text(
                'p',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Pricely',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A1019),
            ),
          ),
          const Spacer(),
          _TopButton(
            label: 'User Log in',
            background: const Color(0xFFF0E7E3),
            textColor: const Color(0xFF2A1019),
            onTap: onUserLogin,
          ),
          const SizedBox(width: 10),
          _TopButton(
            label: 'User Sign up',
            background: const Color(0xFFEFE76E),
            textColor: const Color(0xFF2A1019),
            onTap: onUserSignup,
          ),
          const SizedBox(width: 10),
          _TopButton(
            label: 'Business Log in',
            background: const Color(0xFF2A1019),
            textColor: Colors.white,
            onTap: onBusinessLogin,
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _TopButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AnimationController floatingController;
  final TextEditingController searchController;
  final String placeholder;
  final VoidCallback onSearchTap;
  final VoidCallback onBusinessTap;
  final ValueChanged<String> onQuickFill;

  const _HeroSection({
    required this.floatingController,
    required this.searchController,
    required this.placeholder,
    required this.onSearchTap,
    required this.onBusinessTap,
    required this.onQuickFill,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Container(
            constraints: const BoxConstraints(minHeight: 690),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2ED),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFE7DDD7)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  '⌘',
                  style: TextStyle(
                    fontSize: 68,
                    color: Color(0xFF3A0517),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 42,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFD4C5CB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 38),
                    Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 48,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF3A0517),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 38),
                    Text(
                      'Grow',
                      style: TextStyle(
                        fontSize: 42,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFD4C5CB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Book local\nservices with',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 64,
                    height: 0.95,
                    letterSpacing: -2.4,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F0715),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ease',
                  style: TextStyle(
                    fontSize: 54,
                    height: 1,
                    letterSpacing: -1.8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE8DFDE),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Find trusted businesses, compare services, choose\nstaff and book instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Color(0xFF6C5560),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE8D8D0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3A0517).withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFFDDBFC9), width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: Color(0xFF8D707D), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: placeholder,
                                  border: InputBorder.none,
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF8B727D),
                                    fontSize: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF42212E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: onSearchTap,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD8C6CE),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.arrow_upward,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _PromptTag(
                            label: 'Look up',
                            onTap: () => onQuickFill('Haircut near me'),
                          ),
                          _PromptTag(
                            label: 'Compare',
                            onTap: () =>
                                onQuickFill('Best nail salon in İzmir'),
                          ),
                          _PromptTag(
                            label: 'Book',
                            onTap: () =>
                                onQuickFill('Book skin care appointment'),
                          ),
                          _PromptTag(
                            label: 'Explore',
                            onTap: () => onQuickFill('Find gym with trainer'),
                          ),
                          _PromptTag(
                            label: 'Try this',
                            onTap: () =>
                                onQuickFill('Tattoo studio open today'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroActionButton(
                      label: 'Get started',
                      background: const Color(0xFFEFE76E),
                      textColor: const Color(0xFF2A1019),
                      onTap: onSearchTap,
                    ),
                    const SizedBox(width: 14),
                    _HeroActionButton(
                      label: 'Business portal',
                      background: const Color(0xFF2A1019),
                      textColor: Colors.white,
                      onTap: onBusinessTap,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 9,
          child: Container(
            constraints: const BoxConstraints(minHeight: 690),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE6),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFE7DDD7)),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: floatingController,
                  builder: (context, child) {
                    final y = (floatingController.value - 0.5) * 10;
                    return Positioned(
                      top: 8 + y,
                      right: 0,
                      child: const _FloatingBadge(
                        icon: '⚡',
                        text: 'Instant Booking',
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: floatingController,
                  builder: (context, child) {
                    final y = (floatingController.value - 0.5) * -10;
                    return Positioned(
                      top: 120 + y,
                      left: 0,
                      child: const _FloatingBadge(
                        icon: '✔',
                        text: 'Verified Businesses',
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: floatingController,
                  builder: (context, child) {
                    final y = (floatingController.value - 0.5) * 8;
                    return Positioned(
                      bottom: 12 + y,
                      right: 12,
                      child: const _FloatingBadge(
                        icon: '🔥',
                        text: 'Offers & Promotions',
                      ),
                    );
                  },
                ),
                Center(
                  child: Container(
                    width: 360,
                    height: 620,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(42),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 18),
                        )
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              gradient: LinearGradient(
                                colors: [Color(0xFF4A0019), Color(0xFF7C3B56)],
                              ),
                            ),
                            child: const Text(
                              'Book your next appointment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Glow Beauty Center',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF7EF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '4.9 rating • 1.2k reviews',
                                    style: TextStyle(
                                      color: Color(0xFF28774B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _PhoneServiceItem(
                                  title: 'Haircut & styling',
                                  subtitle: '45 min • Instant confirmation',
                                  price: '₺450',
                                ),
                                const _PhoneServiceItem(
                                  title: 'Gel manicure',
                                  subtitle: '60 min • Staff selection',
                                  price: '₺600',
                                ),
                                const _PhoneServiceItem(
                                  title: 'Skin care session',
                                  subtitle: '90 min • Deposit required',
                                  price: '₺850',
                                ),
                                const _PhoneServiceItem(
                                  title: 'Personal training',
                                  subtitle: '50 min • Available today',
                                  price: '₺700',
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptTag({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFAF8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8D8D0)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6C5560),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final String icon;
  final String text;

  const _FloatingBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B0D1A).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Text(
        '$icon $text',
        style: const TextStyle(
          color: Color(0xFF2A1019),
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PhoneServiceItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;

  const _PhoneServiceItem({
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A7A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF111111),
            ),
          )
        ],
      ),
    );
  }
}

class _SplitCardsSection extends StatelessWidget {
  const _SplitCardsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _InfoCard(
            background: Color(0xFFEFE8EC),
            borderColor: Color(0xFFDFD0D7),
            title: 'For Customers',
            desc:
                'Search businesses, compare services, choose staff, see availability and book without calling.',
            bullets: [
              'Discover trusted local businesses',
              'Compare services, reviews and prices',
              'Choose the right staff member',
              'Book instantly in a few clicks',
            ],
          ),
        ),
        SizedBox(width: 18),
        Expanded(
          child: _InfoCard(
            background: Color(0xFFF6F0D8),
            borderColor: Color(0xFFECE1A9),
            title: 'For Businesses',
            desc:
                'Manage services, staff and working hours. Receive bookings, promote your business and grow faster.',
            bullets: [
              'Add products and bookable services',
              'Manage staff and availability',
              'Receive offers and customer messages',
              'Boost visibility with advertising packages',
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color background;
  final Color borderColor;
  final String title;
  final String desc;
  final List<String> bullets;

  const _InfoCard({
    required this.background,
    required this.borderColor,
    required this.title,
    required this.desc,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D0C18))),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFF584851),
              height: 1.7,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ...bullets.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '• $e',
                style: const TextStyle(
                  color: Color(0xFF24151B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'How it works',
      subtitle: 'Simple for customers, powerful for businesses.',
      child: Row(
        children: const [
          Expanded(
            child: _SimpleCard(
              icon: '🔎',
              title: 'Search',
              body:
                  'Find a service or business near you with a clean and quick discovery flow.',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _SimpleCard(
              icon: '📋',
              title: 'Choose',
              body:
                  'Compare services, staff, pricing, reviews and available booking times.',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _SimpleCard(
              icon: '📅',
              title: 'Book',
              body:
                  'Reserve your appointment in seconds and keep everything organized in one place.',
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: _SimpleCard(
              icon: '🚀',
              title: 'Grow',
              body:
                  'Businesses can manage operations and increase visibility with built-in promotion tools.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Popular categories',
      subtitle:
          'Designed for both everyday needs and appointment-based services.',
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.15,
        children: const [
          _CategoryCard(
              icon: '💇',
              title: 'Hairdresser',
              body: 'Haircuts, styling, coloring and care services.'),
          _CategoryCard(
              icon: '💅',
              title: 'Nail Bar',
              body: 'Manicure, pedicure and beauty care sessions.'),
          _CategoryCard(
              icon: '🏋️',
              title: 'Gym',
              body: 'Training sessions, memberships and wellness bookings.'),
          _CategoryCard(
              icon: '🩺',
              title: 'Clinic',
              body: 'Appointments, consultations and service scheduling.'),
          _CategoryCard(
              icon: '🛠️',
              title: 'Repair',
              body: 'Technical fixes, maintenance and service requests.'),
          _CategoryCard(
              icon: '☕',
              title: 'Cafe',
              body: 'Discover local spots, offers and popular places nearby.'),
          _CategoryCard(
              icon: '🍽️',
              title: 'Restaurant',
              body: 'Explore trending businesses and featured locations.'),
          _CategoryCard(
              icon: '🐾',
              title: 'Pet Shop',
              body: 'Pet care, services, supplies and specialized bookings.'),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Everything your users need',
      subtitle: 'A booking experience that feels simple, modern and fast.',
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFF5ECE8),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: const Color(0xFFEADAD2)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                children: [
                  _FeatureBox(
                    title: 'Real-time availability',
                    body:
                        'Customers can quickly see available times and choose what fits best.',
                  ),
                  SizedBox(height: 16),
                  _FeatureBox(
                    title: 'Staff selection',
                    body:
                        'Let users book the exact person they want for the service.',
                  ),
                  SizedBox(height: 16),
                  _FeatureBox(
                    title: 'Verified reviews',
                    body:
                        'Build trust with transparent feedback and visible customer experience.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      _MiniFeatureTile(label: 'Upcoming appointment'),
                      SizedBox(height: 12),
                      _MiniFeatureTile(label: 'Choose staff member'),
                      SizedBox(height: 12),
                      _MiniFeatureTile(label: 'Best offers nearby'),
                      SizedBox(height: 12),
                      _MiniFeatureTile(label: 'Fast booking confirmation'),
                      SizedBox(height: 12),
                      _MiniFeatureTile(label: 'Message the business'),
                      SizedBox(height: 12),
                      _MiniFeatureTile(label: 'Easy reschedule flow'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                children: [
                  _FeatureBox(
                    title: 'Offers & discounts',
                    body:
                        'Promote special deals and highlight attractive services.',
                  ),
                  SizedBox(height: 16),
                  _FeatureBox(
                    title: 'Messaging',
                    body:
                        'Allow direct communication between customers and businesses.',
                  ),
                  SizedBox(height: 16),
                  _FeatureBox(
                    title: 'Smart discovery',
                    body:
                        'Help users explore the right categories, businesses and services faster.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessSection extends StatelessWidget {
  final VoidCallback onBusinessTap;

  const _BusinessSection({required this.onBusinessTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: const Color(0xFF250813),
        borderRadius: BorderRadius.circular(42),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Business management made simple',
                    style: TextStyle(
                      color: Color(0xFFD7C8CF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Everything businesses\nneed to grow.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.05,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Manage services, staff, working hours, incoming offers and customer communication from one dashboard.',
                  style: TextStyle(
                    color: Color(0xFFD9CDD1),
                    height: 1.8,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                const _DarkListTile(text: 'Manage staff and assign services'),
                const SizedBox(height: 10),
                const _DarkListTile(
                    text: 'Set business hours and availability'),
                const SizedBox(height: 10),
                const _DarkListTile(
                    text: 'Receive bookings, messages and offers'),
                const SizedBox(height: 10),
                const _DarkListTile(
                    text: 'Promote your business with featured advertising'),
                const SizedBox(height: 22),
                _HeroActionButton(
                  label: 'Open business panel',
                  background: const Color(0xFFEFE76E),
                  textColor: const Color(0xFF2A1019),
                  onTap: onBusinessTap,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B0A11),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Business Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                      _PreviewPill(),
                    ],
                  ),
                  SizedBox(height: 18),
                  _PreviewItem(text: 'Manage products and bookable services'),
                  _PreviewItem(
                      text: 'Edit staff, roles and service assignments'),
                  _PreviewItem(text: 'Set weekly working hours'),
                  _PreviewItem(text: 'Reply to reviews and customer messages'),
                  _PreviewItem(
                      text: 'Buy Bronze / Silver / Gold visibility packages'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdsSection extends StatelessWidget {
  final VoidCallback onBusinessTap;

  const _AdsSection({required this.onBusinessTap});

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Boost visibility with advertising',
      subtitle:
          'Simple packages for businesses that want more discovery, more traffic and more bookings.',
      child: Row(
        children: [
          Expanded(
            child: _AdCard(
              title: 'Bronze',
              price: '₺199',
              background: const Color(0xFFFFF8F0),
              textColor: const Color(0xFF1B1B1B),
              borderColor: const Color(0xFFEFE2D4),
              bullets: const [
                'Featured on home',
                'Better visibility for new customers',
                'Entry-level promotion',
              ],
              buttonLabel: 'Get started',
              onTap: onBusinessTap,
              darkButton: true,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _AdCard(
              title: 'Silver',
              price: '₺399',
              background: const Color(0xFFF5F1EE),
              textColor: const Color(0xFF1B1B1B),
              borderColor: const Color(0xFFE8E1D7),
              bullets: const [
                'Featured on home',
                'Boosted in search results',
                'Great for category discovery',
              ],
              buttonLabel: 'Choose silver',
              onTap: onBusinessTap,
              darkButton: true,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _AdCard(
              title: 'Gold',
              price: '₺699',
              background: const Color(0xFF12070B),
              textColor: Colors.white,
              borderColor: const Color(0xFF24141A),
              bullets: const [
                'Featured on home',
                'Boosted in search results',
                'Highlighted on map',
              ],
              buttonLabel: 'Choose gold',
              onTap: onBusinessTap,
              darkButton: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCtaSection extends StatelessWidget {
  final VoidCallback onUserTap;
  final VoidCallback onBusinessTap;

  const _BottomCtaSection({
    required this.onUserTap,
    required this.onBusinessTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7DDD7)),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to explore?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A1019),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Join thousands of users discovering the best local businesses today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B5B63),
              height: 1.7,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroActionButton(
                label: 'Get Started — It\'s Free',
                background: const Color(0xFFEFE76E),
                textColor: const Color(0xFF2A1019),
                onTap: onUserTap,
              ),
              const SizedBox(width: 14),
              _HeroActionButton(
                label: 'Register Your Business',
                background: const Color(0xFF2A1019),
                textColor: Colors.white,
                onTap: onBusinessTap,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Divider(color: Color(0xFFE7DDD7)),
        SizedBox(height: 16),
        Text(
          'PRICELY',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: Color(0xFF2A1019),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Discover, book and grow with local services.',
          style: TextStyle(
            color: Color(0xFF7B6A72),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SectionFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B0D1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF66555D),
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 22),
        child,
      ],
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _SimpleCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEADFD7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D0D19),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF6A6A6A),
              height: 1.7,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEADFD7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D0D19),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF6A6A6A),
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBox extends StatelessWidget {
  final String title;
  final String body;

  const _FeatureBox({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D0C19),
              )),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF666666),
              height: 1.6,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }
}

class _MiniFeatureTile extends StatelessWidget {
  final String label;

  const _MiniFeatureTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE7DF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _DarkListTile extends StatelessWidget {
  final String text;

  const _DarkListTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Live',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String text;

  const _PreviewItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF3EDEF),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final String title;
  final String price;
  final Color background;
  final Color textColor;
  final Color borderColor;
  final List<String> bullets;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool darkButton;

  const _AdCard({
    required this.title,
    required this.price,
    required this.background,
    required this.textColor,
    required this.borderColor,
    required this.bullets,
    required this.buttonLabel,
    required this.onTap,
    required this.darkButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: textColor,
              )),
          const SizedBox(height: 12),
          Text(price,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: textColor,
              )),
          const SizedBox(height: 14),
          ...bullets.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '• $e',
                style: TextStyle(
                  color: textColor.withOpacity(0.82),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color:
                darkButton ? const Color(0xFF2A1019) : const Color(0xFFEFE76E),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Center(
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      color:
                          darkButton ? Colors.white : const Color(0xFF2A1019),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA5657E).withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -160,
          left: -120,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFE76E).withOpacity(0.14),
            ),
          ),
        ),
      ],
    );
  }
}

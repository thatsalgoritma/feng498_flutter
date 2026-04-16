import 'package:flutter/material.dart';
import 'login_page.dart';
import 'business_login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 18),
              _buildQuickActions(),
              const SizedBox(height: 18),
              _buildCategories(),
              const SizedBox(height: 18),
              _buildBusinessCard(),
              const SizedBox(height: 18),
              _buildBottomCta(),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Pricely · Discover, book and grow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7B6A72),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A0019), Color(0xFF8A3E5D)],
            ),
          ),
          child: const Center(
            child: Text(
              'p',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Pricely',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A1019),
            ),
          ),
        ),
        TextButton(
          onPressed: _goBusinessLogin,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Business',
            style: TextStyle(
              color: Color(0xFF6C5560),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDD7)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFEADFD7)),
            ),
            child: const Text(
              'Trusted local services',
              style: TextStyle(
                color: Color(0xFF7B6A72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Book local\nservices with ease',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              height: 0.98,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F0715),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Find trusted businesses, compare services, choose staff and book instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Color(0xFF6C5560),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8D8D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF8D707D), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Haircut, manicure, gym...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _goUserLogin,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8C6CE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ChipTag(label: 'Haircut'),
              _ChipTag(label: 'Nail salon'),
              _ChipTag(label: 'Gym'),
              _ChipTag(label: 'Tattoo'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goUserLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFE76E),
                foregroundColor: const Color(0xFF2A1019),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'User Login / Sign Up',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goBusinessLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1019),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Business Login',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: const [
        Expanded(
          child: _MiniActionCard(
            icon: Icons.search_rounded,
            title: 'Search',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniActionCard(
            icon: Icons.calendar_today_rounded,
            title: 'Book',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniActionCard(
            icon: Icons.scale_rounded,
            title: 'Compare',
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final items = [
      {'icon': '💇', 'title': 'Hairdresser'},
      {'icon': '💅', 'title': 'Nail Bar'},
      {'icon': '🏋️', 'title': 'Gym'},
      {'icon': '🩺', 'title': 'Clinic'},
      {'icon': '🛠️', 'title': 'Repair'},
      {'icon': '☕', 'title': 'Cafe'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular categories',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B0D1A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Browse local services quickly.',
          style: TextStyle(
            color: Color(0xFF66555D),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEADFD7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['icon'] as String,
                      style: const TextStyle(fontSize: 26)),
                  const Spacer(),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D0D19),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBusinessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF250813),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For Businesses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage services, staff, working hours and promotions from one dashboard.',
            style: TextStyle(
              color: Color(0xFFD9CDD1),
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          const _DarkItem(text: 'Manage staff and assign services'),
          const SizedBox(height: 8),
          const _DarkItem(text: 'Set business hours'),
          const SizedBox(height: 8),
          const _DarkItem(text: 'Receive offers and messages'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goBusinessLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFE76E),
                foregroundColor: const Color(0xFF2A1019),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Open business panel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDD7)),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to explore?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A1019),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Join users discovering the best local businesses today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B5B63),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goUserSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFE76E),
                foregroundColor: const Color(0xFF2A1019),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  final String label;
  const _ChipTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAD8CF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6C5560),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MiniActionCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFD7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4A0019), size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2A1019),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }
}

class _DarkItem extends StatelessWidget {
  final String text;
  const _DarkItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

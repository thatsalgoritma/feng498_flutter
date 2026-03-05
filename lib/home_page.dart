import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'business_detail_page.dart';
import 'profile_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  static const List<IconData> _categoryIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.shopping_bag,
    Icons.local_grocery_store,
    Icons.spa,
    Icons.fitness_center,
    Icons.local_pharmacy,
    Icons.auto_fix_high,
    Icons.store,
    Icons.category,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cats = await DatabaseHelper.getCategories();
    final biz = await DatabaseHelper.getBusinesses();
    setState(() {
      _categories = ['All', ...cats];
      _businesses = biz;
      _filtered = biz;
      _loading = false;
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    _applySearch();
  }

  void _applySearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _businesses.where((b) {
        final matchCat = _selectedCategory == 'All' ||
            (b['category'] ?? '') == _selectedCategory;
        final matchSearch = query.isEmpty ||
            (b['name'] ?? '').toString().toLowerCase().contains(query) ||
            (b['address'] ?? '').toString().toLowerCase().contains(query);
        return matchCat && matchSearch;
      }).toList();
    });
  }

  IconData _iconForIndex(int i) => _categoryIcons[i % _categoryIcons.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeBody(),
          MapPage(user: widget.user),
          ProfilePage(user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A73E8).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1A73E8)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF1A73E8)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1A73E8)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('PRICELY',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  (widget.user['full_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    widget.user['full_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
              ],
              onSelected: (v) {
                if (v == 'logout') {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // ── Search Bar ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFF1A73E8),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search businesses…',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF1A73E8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),

                  // ── Category Chips ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final selected = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () => _selectCategory(cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF1A73E8)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      i == 0
                                          ? Icons.grid_view
                                          : _iconForIndex(i - 1),
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF1A73E8),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 64,
                                    child: Text(
                                      cat,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? const Color(0xFF1A73E8)
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Section Label ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            _selectedCategory == 'All'
                                ? 'All Businesses'
                                : _selectedCategory,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_filtered.length}',
                              style: const TextStyle(
                                  color: Color(0xFF1A73E8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Business List ─────────────────────────────────────
                  _filtered.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.store_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('No businesses found',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _BusinessCard(
                                  business: _filtered[i], user: widget.user),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  } // end _buildHomeBody
}

// ── Business Card ────────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final Map<String, dynamic> user;

  const _BusinessCard({required this.business, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = business['name'] ?? 'Unknown';
    final address = business['address'] ?? '';
    final category = business['category'] ?? '';
    final description = business['description'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDetailPage(
            shopId: business['shop_id'] as int,
            user: user,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder image / gradient header
            Container(
              height: 130,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A73E8).withOpacity(0.8),
                    const Color(0xFF0D47A1).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (category.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white38, width: 1),
                        ),
                        child: Text(category,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessDetailPage(
                              shopId: business['shop_id'] as int,
                              user: user,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1A73E8)),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'db_helper.dart';

class BusinessDetailPage extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic> user;

  const BusinessDetailPage(
      {super.key, required this.shopId, required this.user});

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _business;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _reviews = [];
  List<String> _photos = [];
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.getBusinessDetail(widget.shopId),
      DatabaseHelper.getProductsByBusiness(widget.shopId),
      DatabaseHelper.getReviews(widget.shopId),
      DatabaseHelper.getBusinessPhotos(widget.shopId),
      DatabaseHelper.isFavorite(widget.user['id'] as int, widget.shopId),
    ]);
    setState(() {
      _business = results[0] as Map<String, dynamic>?;
      _products = results[1] as List<Map<String, dynamic>>;
      _reviews = results[2] as List<Map<String, dynamic>>;
      _photos = results[3] as List<String>;
      _isFavorite = results[4] as bool;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final newState = await DatabaseHelper.toggleFavorite(
        widget.user['id'] as int, widget.shopId);
    setState(() => _isFavorite = newState);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(newState ? 'Added to favorites' : 'Removed from favorites'),
      duration: const Duration(seconds: 2),
    ));
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum =
        _reviews.fold<int>(0, (acc, r) => acc + ((r['rank'] as int?) ?? 0));
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_business == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: const Center(child: Text('Business not found.')));
    }

    final b = _business!;
    final name = b['name'] ?? '';
    final address = b['address'] ?? '';
    final tel = b['tel_no'] ?? '';
    final description = b['description'] ?? '';
    final category = b['category'] ?? '';
    final isEditors = b['is_editors_choice'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isFavorite),
                    color: _isFavorite ? Colors.red.shade300 : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 56, right: 48),
              title: Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo or gradient
                  _photos.isNotEmpty
                      ? Image.network(
                          _photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBg(),
                        )
                      : _gradientBg(),
                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Row(
                      children: [
                        if (isEditors)
                          _chip(Icons.star, "Editor's Choice",
                              const Color(0xFFFFC107)),
                        if (category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child:
                                _chip(Icons.category, category, Colors.white24),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Products'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverview(address, tel, description),
            _buildProducts(),
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  // ── Overview ─────────────────────────────────────────────────────────────
  Widget _buildOverview(String address, String tel, String description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat row
          Row(
            children: [
              _statCard(Icons.star, _avgRating.toStringAsFixed(1), 'Avg Rating',
                  const Color(0xFFFFC107)),
              const SizedBox(width: 12),
              _statCard(Icons.rate_review, '${_reviews.length}', 'Reviews',
                  const Color(0xFF1A73E8)),
              const SizedBox(width: 12),
              _statCard(Icons.inventory_2, '${_products.length}', 'Products',
                  const Color(0xFF34A853)),
            ],
          ),
          const SizedBox(height: 20),

          // Info card
          _infoSection('About', [
            if (description.isNotEmpty)
              _infoRow(Icons.info_outline, description),
            if (address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, address),
            if (tel.isNotEmpty) _infoRow(Icons.phone_outlined, tel),
          ]),

          // Photo strip
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _photos[i],
                    width: 160,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Products ─────────────────────────────────────────────────────────────
  Widget _buildProducts() {
    if (_products.isEmpty) {
      return const Center(
          child: Text('No products listed.',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        final name = p['name'] ?? 'Unnamed';
        final desc = p['description'] ?? '';
        final price = _toDouble(p['product_prices']);
        final isDiscount = p['is_discounted'] == true;
        final discountedPrice = _toDouble(p['discounted_price']);
        final originalPrice = _toDouble(p['original_price']) ?? price ?? 0.0;
        final discountPct = p['discount_percent'];
        final categories = p['categories'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF1A73E8)),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    if (categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(categories,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600)),
                        ),
                      ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isDiscount && discountedPrice != null) ...[
                    Text(
                      '₺${discountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34A853),
                          fontSize: 15),
                    ),
                    Text(
                      '₺${originalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough),
                    ),
                    if (discountPct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-$discountPct%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ] else if (price != null)
                    Text(
                      '₺${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A73E8),
                          fontSize: 15),
                    )
                  else
                    const Text('—', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reviews ──────────────────────────────────────────────────────────────
  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return const Center(
          child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (_, i) {
        final r = _reviews[i];
        final fullName = r['full_name'] ?? 'Anonymous';
        final rank = (r['rank'] as int?) ?? 0;
        final comments = r['comments'] ?? '';
        final time = r['time'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1A73E8).withOpacity(0.15),
                    child: Text(
                      fullName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: List.generate(
                            5,
                            (j) => Icon(
                              j < rank ? Icons.star : Icons.star_border,
                              size: 14,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(
                      time.length > 10 ? time.substring(0, 10) : time,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                ],
              ),
              if (comments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(comments,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _statCard(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );

  Widget _infoSection(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ),
          ],
        ),
      );

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return double.tryParse(val.toString());
  }
}

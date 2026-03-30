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

  // The current user's own review (null = hasn't written one yet)
  Map<String, dynamic>? _myReview;

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
    final userId = widget.user['id'] as int;
    final results = await Future.wait([
      DatabaseHelper.getBusinessDetail(widget.shopId),
      DatabaseHelper.getProductsByBusiness(widget.shopId),
      DatabaseHelper.getReviews(widget.shopId),
      DatabaseHelper.getBusinessPhotos(widget.shopId),
      DatabaseHelper.isFavorite(userId, widget.shopId),
      DatabaseHelper.getUserReviewForBusiness(userId, widget.shopId),
    ]);
    setState(() {
      _business = results[0] as Map<String, dynamic>?;
      _products = results[1] as List<Map<String, dynamic>>;
      _reviews = results[2] as List<Map<String, dynamic>>;
      _photos = results[3] as List<String>;
      _isFavorite = results[4] as bool;
      _myReview = results[5] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final newState = await DatabaseHelper.toggleFavorite(
        widget.user['id'] as int, widget.shopId);
    setState(() => _isFavorite = newState);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(newState ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum =
        _reviews.fold<int>(0, (acc, r) => acc + ((r['rank'] as int?) ?? 0));
    return sum / _reviews.length;
  }

  // ── Review sheet ──────────────────────────────────────────────────────────
  void _showReviewSheet([Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReviewSheet(
        userId: widget.user['id'] as int,
        businessId: widget.shopId,
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          _loadAll();
        },
      ),
    );
  }

  Future<void> _deleteMyReview() async {
    final id = _myReview?['review_id'] as int?;
    if (id == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text('Are you sure you want to delete your review?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await DatabaseHelper.deleteReview(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Review deleted'), backgroundColor: Colors.red));
      }
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  // ── Offer sheet ───────────────────────────────────────────────────────────
  void _showOfferSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OfferSheet(
        user: widget.user,
        businessId: widget.shopId,
        product: product,
        onSent: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Offer sent!'),
              backgroundColor: Color(0xFF34A853)));
        },
      ),
    );
  }

  // ── Message screen ────────────────────────────────────────────────────────
  Future<void> _openChat() async {
    try {
      final chatId = await DatabaseHelper.getOrCreateChat(
          widget.user['id'] as int, widget.shopId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _UserChatScreen(
            chatId: chatId,
            userId: widget.user['id'] as int,
            businessName: _business?['name'] ?? 'Business',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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
      // ── Chat FAB ──────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _openChat,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        tooltip: 'Message business',
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
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
                  _photos.isNotEmpty
                      ? Image.network(_photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientBg())
                      : _gradientBg(),
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
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Row(children: [
                      if (isEditors)
                        _chip(Icons.star, "Editor's Choice",
                            const Color(0xFFFFC107)),
                      if (category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child:
                              _chip(Icons.category, category, Colors.white24),
                        ),
                    ]),
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

  // ── Overview ──────────────────────────────────────────────────────────────
  Widget _buildOverview(String address, String tel, String description) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _statCard(Icons.star, _avgRating.toStringAsFixed(1), 'Avg Rating',
                const Color(0xFFFFC107)),
            const SizedBox(width: 12),
            _statCard(Icons.rate_review, '${_reviews.length}', 'Reviews',
                const Color(0xFF1A73E8)),
            const SizedBox(width: 12),
            _statCard(Icons.inventory_2, '${_products.length}', 'Products',
                const Color(0xFF34A853)),
          ]),
          const SizedBox(height: 20),
          _infoSection('About', [
            if (description.isNotEmpty)
              _infoRow(Icons.info_outline, description),
            if (address.isNotEmpty)
              _infoRow(Icons.location_on_outlined, address),
            if (tel.isNotEmpty) _infoRow(Icons.phone_outlined, tel),
          ]),
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
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
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
            ),
          ],
        ],
      ),
    );
  }

  // ── Products ──────────────────────────────────────────────────────────────
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
        final pName = p['name'] ?? 'Unnamed';
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pName,
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
                                      fontSize: 10,
                                      color: Colors.grey.shade600)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Price column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isDiscount && discountedPrice != null) ...[
                        Text('₺${discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34A853),
                                fontSize: 15)),
                        Text('₺${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough)),
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
                        Text('₺${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A73E8),
                                fontSize: 15))
                      else
                        const Text('—', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              // ── Make Offer button (shown for negotiable products) ────────
              _OfferButton(
                product: p,
                onTap: () => _showOfferSheet(p),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reviews ───────────────────────────────────────────────────────────────
  Widget _buildReviews() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // ── My review card ─────────────────────────────────────────────────
        if (_myReview != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person, color: Color(0xFF1A73E8), size: 18),
                  const SizedBox(width: 6),
                  const Text('Your Review',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A73E8),
                          fontSize: 13)),
                  const Spacer(),
                  // Edit
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFF1A73E8)),
                    tooltip: 'Edit',
                    onPressed: () => _showReviewSheet(_myReview),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: _deleteMyReview,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (j) => Icon(
                      j < ((_myReview!['rank'] as int?) ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                ),
                if (((_myReview!['comments'] ?? '') as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_myReview!['comments'],
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
                if (_myReview!['is_approved'] != true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Pending approval',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange.shade700)),
                    ]),
                  ),
              ],
            ),
          ),
        ] else ...[
          // ── Write a review prompt ─────────────────────────────────────────
          GestureDetector(
            onTap: () => _showReviewSheet(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: Row(children: [
                const Icon(Icons.rate_review_outlined,
                    color: Color(0xFF1A73E8)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Write a review…',
                      style: TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF1A73E8)),
              ]),
            ),
          ),
        ],

        // ── All approved reviews ──────────────────────────────────────────
        if (_reviews.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text('No approved reviews yet.',
                style: TextStyle(color: Colors.grey)),
          ))
        else
          ..._reviews.map((r) {
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
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          const Color(0xFF1A73E8).withOpacity(0.15),
                      child: Text(fullName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.bold)),
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
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                  ]),
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(comments,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...rows,
        ]),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700))),
        ]),
      );

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return double.tryParse(val.toString());
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// OFFER BUTTON  — async checks negotiability then shows/hides itself
// ═════════════════════════════════════════════════════════════════════════════

class _OfferButton extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _OfferButton({required this.product, required this.onTap});
  @override
  State<_OfferButton> createState() => _OfferButtonState();
}

class _OfferButtonState extends State<_OfferButton> {
  bool _negotiable = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final n =
        await DatabaseHelper.isProductNegotiable(widget.product['id'] as int);
    if (mounted)
      setState(() {
        _negotiable = n;
        _checked = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_negotiable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: widget.onTap,
        icon: const Icon(Icons.local_offer_outlined, size: 16),
        label: const Text('Make an Offer'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF6D00),
          side: const BorderSide(color: Color(0xFFFF6D00)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REVIEW SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewSheet extends StatefulWidget {
  final int userId, businessId;
  final Map<String, dynamic>? existing; // non-null = edit mode
  final VoidCallback onSaved;
  const _ReviewSheet(
      {required this.userId,
      required this.businessId,
      this.existing,
      required this.onSaved});
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late TextEditingController _commentC;
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = (widget.existing?['rank'] as int?) ?? 0;
    _commentC = TextEditingController(text: widget.existing?['comments'] ?? '');
  }

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a star rating.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    try {
      await DatabaseHelper.upsertReview(
        userId: widget.userId,
        businessId: widget.businessId,
        rank: _rating,
        comments: _commentC.text.trim(),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                        widget.existing == null
                            ? 'Write a Review'
                            : 'Edit Your Review',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              // Star selector
              const Text('Rating',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC107),
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Comment (optional)',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _commentC,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: 'Share your experience…',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(14)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(_saving ? 'Saving…' : 'Submit Review',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// OFFER SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _OfferSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final int businessId;
  final Map<String, dynamic> product;
  final VoidCallback onSent;
  const _OfferSheet(
      {required this.user,
      required this.businessId,
      required this.product,
      required this.onSent});
  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _priceC = TextEditingController();
  final _noteC = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _priceC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final price = double.tryParse(_priceC.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a valid price.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _sending = true);
    try {
      await DatabaseHelper.createOffer(
        userId: widget.user['id'] as int,
        businessId: widget.businessId,
        productId: widget.product['id'] as int,
        offeredPrice: price,
        note: _noteC.text.trim(),
      );
      widget.onSent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final listPrice = DatabaseHelper.toDouble(widget.product['product_prices']);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Make an Offer',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18))),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 4),
            Text(widget.product['name'] ?? '',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (listPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Listed price: ₺${listPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            const SizedBox(height: 20),
            const Text('Your Offer Price (₺)',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _priceC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money,
                      color: Color.fromARGB(255, 173, 158, 146)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            ),
            const SizedBox(height: 14),
            const Text('Note (optional)',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteC,
              maxLines: 3,
              decoration: InputDecoration(
                  hintText: 'Add a message to the business…',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_sending ? 'Sending…' : 'Send Offer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            // Secondary: open chat directly
            OutlinedButton.icon(
              onPressed: _sending
                  ? null
                  : () async {
                      Navigator.pop(context);
                      try {
                        final chatId = await DatabaseHelper.getOrCreateChat(
                            widget.user['id'] as int, widget.businessId);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _UserChatScreen(
                              chatId: chatId,
                              userId: widget.user['id'] as int,
                              businessName: '',
                            ),
                          ),
                        );
                      } catch (_) {}
                    },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Message Instead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// USER CHAT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _UserChatScreen extends StatefulWidget {
  final int chatId, userId;
  final String businessName;
  const _UserChatScreen(
      {required this.chatId, required this.userId, required this.businessName});
  @override
  State<_UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<_UserChatScreen> {
  List<Map<String, dynamic>> _msgs = [];
  final _ctrl = TextEditingController();
  bool _sending = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    DatabaseHelper.markOwnerMessagesRead(widget.chatId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final m = await DatabaseHelper.getChatMessages(widget.chatId);
    setState(() => _msgs = m);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _sending = true);
    try {
      await DatabaseHelper.sendUserMessage(widget.chatId, widget.userId, t);
      _ctrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          title: Text(
              widget.businessName.isNotEmpty
                  ? widget.businessName
                  : 'Business Chat',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
          ],
        ),
        body: Column(children: [
          Expanded(
            child: _msgs.isEmpty
                ? const Center(
                    child: Text('No messages yet.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) {
                      final m = _msgs[i];
                      final isMe = (m['sender_type'] ?? '') == 'user';
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color:
                                isMe ? const Color(0xFF1A73E8) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(m['content'] ?? '',
                                  style: TextStyle(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(_fmtT(m['created_at']),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white60
                                          : Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      );
                    }),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: _ctrl,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            hintText: 'Type a message…',
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1A73E8), shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );

  String _fmtT(dynamic t) {
    if (t == null) return '';
    try {
      final dt = DateTime.parse(t.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

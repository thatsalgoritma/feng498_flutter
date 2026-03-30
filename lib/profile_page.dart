import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'business_detail_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final uid = widget.user['id'] as int;
    final results = await Future.wait([
      DatabaseHelper.getFavoriteBusinesses(uid),
      DatabaseHelper.getUserReviews(uid),
      DatabaseHelper.getUserOffers(uid),
    ]);
    setState(() {
      _favorites = results[0];
      _reviews = results[1];
      _offers = results[2];
      _loading = false;
    });
  }

  Future<void> _deleteReview(int reviewId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Review'),
            content: const Text('Are you sure you want to delete this review?'),
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
      await DatabaseHelper.deleteReview(reviewId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Review deleted'), backgroundColor: Colors.red));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['full_name'] ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            title: const Text('My Profile',
                style: TextStyle(fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Text(initial,
                          style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(widget.user['role_type'] ?? 'user',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'Favorites (${_favorites.length})'),
                Tab(text: 'Reviews (${_reviews.length})'),
                Tab(text: 'Offers (${_offers.length})'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavorites(),
                    _buildReviews(),
                    _buildOffers(),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Favorites Tab ─────────────────────────────────────────────────────────
  Widget _buildFavorites() {
    if (_favorites.isEmpty) {
      return _emptyState(Icons.favorite_border, 'No favorites yet',
          'Tap the heart icon on any business to save it here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (_, i) {
        final b = _favorites[i];
        return _card(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessDetailPage(
                shopId: b['shop_id'] as int,
                user: widget.user,
              ),
            ),
          ).then((_) => _loadData()),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1A73E8).withOpacity(0.15),
              child: Text(
                (b['name'] ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if ((b['address'] ?? '').isNotEmpty)
                    Text(b['address'],
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  if ((b['category'] ?? '').isNotEmpty) _pill(b['category']),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        );
      },
    );
  }

  // ── Reviews Tab ───────────────────────────────────────────────────────────
  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return _emptyState(Icons.rate_review_outlined, 'No reviews yet',
          'Your reviews on businesses will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (_, i) {
        final r = _reviews[i];
        final rank = (r['rank'] as int?) ?? 0;
        final reviewId = r['review_id'] as int?;
        return _card(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessDetailPage(
                shopId: r['shop_id'] as int,
                user: widget.user,
              ),
            ),
          ).then((_) => _loadData()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(r['business_name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                // Star rating
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
                // Delete button
                if (reviewId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => _deleteReview(reviewId),
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                    ),
                  ),
              ]),
              if ((r['comments'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r['comments'],
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              if ((r['time'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  r['time'].length > 10
                      ? r['time'].substring(0, 10)
                      : r['time'],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Offers Tab ────────────────────────────────────────────────────────────
  Widget _buildOffers() {
    if (_offers.isEmpty) {
      return _emptyState(Icons.local_offer_outlined, 'No offers yet',
          'Price offers you make will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      itemBuilder: (_, i) {
        final o = _offers[i];
        final status = (o['status'] ?? 'pending').toString();
        final offeredPrice = _toDouble(o['offered_price']);
        final counterPrice = _toDouble(o['counter_price']);

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['business_name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if ((o['product_name'] ?? '').isNotEmpty)
                        Text(o['product_name'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                _statusBadge(status),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _priceChip(
                    'Your offer',
                    offeredPrice != null
                        ? '₺${offeredPrice.toStringAsFixed(2)}'
                        : '—',
                    const Color(0xFF1A73E8)),
                if (counterPrice != null) ...[
                  const SizedBox(width: 10),
                  _priceChip(
                      'Counter offer',
                      '₺${counterPrice.toStringAsFixed(2)}',
                      const Color(0xFFFF6D00)),
                ],
              ]),
              if ((o['note'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(o['note'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if ((o['created_time'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  o['created_time'].length > 10
                      ? o['created_time'].substring(0, 10)
                      : o['created_time'],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _card({required Widget child, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
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
          child: child,
        ),
      );

  Widget _emptyState(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ]),
        ),
      );

  Widget _pill(String label) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF1A73E8))),
      );

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = const Color(0xFF34A853);
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'countered':
        color = const Color(0xFFFF6D00);
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _priceChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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

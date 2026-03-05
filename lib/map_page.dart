import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'business_detail_page.dart';

/// Map page — shows businesses with coordinates in a scrollable card list.
/// To use a real map, add the `flutter_map` + `latlong2` packages and
/// uncomment the FlutterMap widget below.
class MapPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const MapPage({super.key, required this.user});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await DatabaseHelper.getBusinesses();
    // Only keep businesses that have coordinates
    final withCoords = all
        .where((b) => b['latitude'] != null && b['longitude'] != null)
        .toList();
    setState(() {
      _businesses = withCoords;
      _filtered = withCoords;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _businesses.where((b) {
        return q.isEmpty ||
            (b['name'] ?? '').toString().toLowerCase().contains(q) ||
            (b['address'] ?? '').toString().toLowerCase().contains(q) ||
            (b['category'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Nearby Businesses',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Search ───────────────────────────────────────────────
                Container(
                  color: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by name, address, category…',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF1A73E8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),

                // ── Map placeholder ───────────────────────────────────────
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Grid pattern to simulate a map
                        CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: _MapGridPainter(),
                        ),
                        // Business dots
                        if (_filtered.isNotEmpty)
                          ..._filtered.take(20).map((b) {
                            final lat = _toDouble(b['latitude']) ?? 0;
                            final lng = _toDouble(b['longitude']) ?? 0;
                            final isSelected =
                                _selected?['shop_id'] == b['shop_id'];
                            // Normalize lat/lng to canvas position (rough demo)
                            final allLats = _filtered
                                .map((x) => _toDouble(x['latitude']) ?? 0)
                                .toList();
                            final allLngs = _filtered
                                .map((x) => _toDouble(x['longitude']) ?? 0)
                                .toList();
                            final minLat =
                                allLats.reduce((a, b) => a < b ? a : b);
                            final maxLat =
                                allLats.reduce((a, b) => a > b ? a : b);
                            final minLng =
                                allLngs.reduce((a, b) => a < b ? a : b);
                            final maxLng =
                                allLngs.reduce((a, b) => a > b ? a : b);
                            final latRange = (maxLat - minLat).abs() < 0.001
                                ? 1.0
                                : maxLat - minLat;
                            final lngRange = (maxLng - minLng).abs() < 0.001
                                ? 1.0
                                : maxLng - minLng;

                            return LayoutBuilder(
                              builder: (ctx, constraints) {
                                final x = ((lng - minLng) / lngRange) *
                                        (constraints.maxWidth - 40) +
                                    20;
                                final y =
                                    (1 - (lat - minLat) / latRange) * (180) +
                                        10;
                                return Positioned(
                                  left: x - 10,
                                  top: y - 10,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selected = b),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: isSelected ? 28 : 20,
                                      height: isSelected ? 28 : 20,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF1A73E8)
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.store,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),

                        // Map label
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  '${_filtered.length} businesses',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // No coords message
                        if (_businesses.isEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('No location data available',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Selected business card ────────────────────────────────
                if (_selected != null)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessDetailPage(
                          shopId: _selected!['shop_id'] as int,
                          user: widget.user,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selected!['name'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                if ((_selected!['address'] ?? '').isNotEmpty)
                                  Text(_selected!['address'],
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),

                // ── Business list ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text('All Locations',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_filtered.length}',
                            style: const TextStyle(
                                color: Color(0xFF1A73E8),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text('No businesses with location data.',
                              style: TextStyle(color: Colors.grey.shade500)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final b = _filtered[i];
                            final lat = _toDouble(b['latitude']);
                            final lng = _toDouble(b['longitude']);
                            final isSelected =
                                _selected?['shop_id'] == b['shop_id'];
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selected = b);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusinessDetailPage(
                                      shopId: b['shop_id'] as int,
                                      user: widget.user,
                                    ),
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1A73E8)
                                          .withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1A73E8)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
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
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A73E8)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.location_on,
                                          color: Color(0xFF1A73E8), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(b['name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14)),
                                          if ((b['address'] ?? '').isNotEmpty)
                                            Text(b['address'],
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey.shade500),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          if (lat != null && lng != null)
                                            Text(
                                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if ((b['category'] ?? '').isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(b['category'],
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600)),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return double.tryParse(val.toString());
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8F0FE);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFBBCEF8)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw some "roads"
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.7, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), roadPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

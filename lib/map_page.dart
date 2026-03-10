import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'db_helper.dart';
import 'business_detail_page.dart';

class MapPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const MapPage({super.key, required this.user});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Map<String, dynamic>> _businesses = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _categories = [];
  InAppWebViewController? _webCtrl;
  bool _mapReady = false;
  Map<String, dynamic>? _selected;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
      _pushMarkersToMap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await DatabaseHelper.getBusinesses();
    final cats = <String>{};
    for (final b in all) {
      final c = b['category']?.toString() ?? '';
      if (c.isNotEmpty) cats.add(c);
    }
    setState(() {
      _businesses = all
          .where((b) => b['latitude'] != null && b['longitude'] != null)
          .toList();
      _categories = cats.toList()..sort();
      _loading = false;
    });
    _pushMarkersToMap();
  }

  List<Map<String, dynamic>> get _filtered => _businesses.where((b) {
        final matchSearch = _searchQuery.isEmpty ||
            (b['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
            (b['address'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery);
        final matchCat =
            _selectedCategory.isEmpty || b['category'] == _selectedCategory;
        return matchSearch && matchCat;
      }).toList();

  String _buildLeafletHtml() => '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body, #map { width:100%; height:100%; }
  .leaflet-popup-content-wrapper { border-radius:10px; border-top:4px solid #1A73E8; box-shadow:0 4px 16px rgba(0,0,0,.15); }
  .leaflet-popup-content { font-size:13px; color:#333; margin:10px; }
  .pname { font-weight:700; font-size:14px; color:#1A73E8; margin-bottom:4px; }
  .pcat  { color:#888; font-size:12px; margin-bottom:3px; }
  .paddr { color:#555; font-size:12px; margin-bottom:8px; }
  .pbtn  { display:block; background:#1A73E8; color:#fff; padding:7px; border-radius:8px; font-size:12px; font-weight:600; cursor:pointer; border:none; width:100%; text-align:center; }
  .pbtn:hover { background:#0D47A1; }
</style>
</head>
<body>
<div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
const map = L.map("map").setView([38.4192,27.1287],12);
L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19}).addTo(map);
let markers=[];

function setMarkers(list){
  markers.forEach(m=>map.removeLayer(m)); markers=[];
  list.forEach(b=>{
    if(!b.latitude||!b.longitude) return;
    const icon=L.divIcon({className:"",html:'<div style="background:#1A73E8;width:14px;height:14px;border-radius:50%;border:2.5px solid white;box-shadow:0 1px 5px rgba(0,0,0,.5)"></div>',iconSize:[14,14],iconAnchor:[7,7]});
    const m=L.marker([b.latitude,b.longitude],{icon}).addTo(map);
    m.bindPopup(
      '<div class="pname">'+b.name+'</div>'+
      (b.category?'<div class="pcat">'+b.category+'</div>':'')+
      (b.address?'<div class="paddr">'+b.address+'</div>':'')+
      '<button class="pbtn" onclick="tap('+b.shop_id+')">View Details</button>'
    );
    markers.push(m);
  });
  if(markers.length){const g=L.featureGroup(markers);map.fitBounds(g.getBounds(),{padding:[40,40]});}
}

function tap(id){ window.flutter_inappwebview.callHandler("onTap",id); }
window.addEventListener("flutterInAppWebViewPlatformReady",()=>{ window.flutter_inappwebview.callHandler("ready"); });
</script>
</body>
</html>
''';

  void _pushMarkersToMap() {
    if (!_mapReady || _webCtrl == null) return;
    final list = _filtered;
    final sb = StringBuffer('setMarkers([');
    for (int i = 0; i < list.length; i++) {
      final b = list[i];
      final lat = DatabaseHelper.toDouble(b['latitude']) ?? 0;
      final lng = DatabaseHelper.toDouble(b['longitude']) ?? 0;
      sb.write(
          '{"shop_id":${b['shop_id']},"name":"${_e(b['name'])}","address":"${_e(b['address'])}","category":"${_e(b['category'])}","latitude":$lat,"longitude":$lng}');
      if (i < list.length - 1) sb.write(',');
    }
    sb.write(']);');
    _webCtrl!.evaluateJavascript(source: sb.toString());
  }

  String _e(dynamic s) =>
      (s ?? '').toString().replaceAll('"', '\\"').replaceAll("'", "\\'");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Explore Map',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
        ],
      ),
      body: Column(children: [
        // Search + category
        Container(
          color: const Color(0xFF1A73E8),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search businesses…',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: const Text('All', style: TextStyle(fontSize: 13)),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    ..._categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedCategory = v ?? '');
                    _pushMarkersToMap();
                  },
                ),
              ),
            ),
          ]),
        ),

        // Leaflet map
        Expanded(
          flex: 3,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : InAppWebView(
                  initialData:
                      InAppWebViewInitialData(data: _buildLeafletHtml()),
                  initialSettings:
                      InAppWebViewSettings(javaScriptEnabled: true),
                  onWebViewCreated: (ctrl) {
                    _webCtrl = ctrl;
                    ctrl.addJavaScriptHandler(
                        handlerName: 'ready',
                        callback: (_) {
                          setState(() => _mapReady = true);
                          _pushMarkersToMap();
                        });
                    ctrl.addJavaScriptHandler(
                        handlerName: 'onTap',
                        callback: (args) {
                          final shopId =
                              args.isNotEmpty ? (args[0] as num).toInt() : null;
                          if (shopId == null) return;
                          final b = _businesses.firstWhere(
                              (b) => b['shop_id'] == shopId,
                              orElse: () => {});
                          if (b.isEmpty) return;
                          setState(() => _selected = b);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BusinessDetailPage(
                                      shopId: shopId, user: widget.user)));
                        });
                  },
                ),
        ),

        // Selected banner
        if (_selected != null)
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BusinessDetailPage(
                        shopId: _selected!['shop_id'] as int,
                        user: widget.user))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1A73E8),
              child: Row(children: [
                const Icon(Icons.store, color: Colors.white, size: 18),
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
                    ])),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 14),
              ]),
            ),
          ),

        // Count footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(children: [
            const Icon(Icons.location_on, size: 14, color: Color(0xFF1A73E8)),
            const SizedBox(width: 6),
            Text('${_filtered.length} businesses on map',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ),
      ]),
    );
  }
}

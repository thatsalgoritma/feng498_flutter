import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';
import 'login_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF1A73E8);
const _kGreen = Color(0xFF34A853);
const _kOrange = Color(0xFFFF9800);
const _kBg = Color(0xFFF5F7FA);
const _kDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

// ═════════════════════════════════════════════════════════════════════════════
// SHELL
// ═════════════════════════════════════════════════════════════════════════════

class OwnerDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  const OwnerDashboard({super.key, required this.user});
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _idx = 0;
  Map<String, dynamic>? _biz;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await DatabaseHelper.getOwnerBusiness(widget.user['id'] as int);
    setState(() {
      _biz = b;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_biz == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: _kBlue,
            foregroundColor: Colors.white),
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No business found for your account.'),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ])),
      );
    }

    final sid = _biz!['shop_id'] as int;
    final oid = widget.user['id'] as int;

    final pages = [
      _InfoTab(biz: _biz!, onSaved: _load),
      _ProductsTab(shopId: sid),
      _PriceListTab(shopId: sid),
      _StaffTab(shopId: sid),
      _BookingsTab(shopId: sid),
      _OffersTab(shopId: sid, ownerId: oid),
      _MessagesTab(businessId: sid, ownerId: oid),
      _ReviewsTab(shopId: sid),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Owner Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_biz!['name'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text((widget.user['full_name'] ?? 'O')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
            itemBuilder: (_) => [
              PopupMenuItem(
                  enabled: false,
                  child: Text(widget.user['full_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
            onSelected: (v) {
              if (v == 'logout')
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          )
        ],
      ),
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Colors.white,
        indicatorColor: _kBlue.withOpacity(0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store, color: _kBlue),
              label: 'Info'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: _kBlue),
              label: 'Products'),
          NavigationDestination(
              icon: Icon(Icons.price_change_outlined),
              selectedIcon: Icon(Icons.price_change, color: _kBlue),
              label: 'Prices'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: _kBlue),
              label: 'Staff'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: _kBlue),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer, color: _kBlue),
              label: 'Offers'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: _kBlue),
              label: 'Messages'),
          NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star, color: _kBlue),
              label: 'Reviews'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — INFO  (Turkey address dropdowns + map pin + operating hours)
// ═════════════════════════════════════════════════════════════════════════════

class _InfoTab extends StatefulWidget {
  final Map<String, dynamic> biz;
  final VoidCallback onSaved;
  const _InfoTab({required this.biz, required this.onSaved});
  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  late TextEditingController _nameC, _descC, _telC, _catC;
  bool _saving = false;

  // Address
  List<dynamic> _provinces = [];
  bool _turkeLoaded = false;
  String? _province, _district, _neighbourhood;
  List<String> _districts = [], _hoods = [];

  // Location
  double? _lat, _lng;

  // Hours
  final Map<String, Map<String, dynamic>> _hrs = {};
  bool _hrsLoading = true;

  @override
  void initState() {
    super.initState();
    final b = widget.biz;
    _nameC = TextEditingController(text: b['name'] ?? '');
    _descC = TextEditingController(text: b['description'] ?? '');
    _telC = TextEditingController(text: b['tel_no'] ?? '');
    _catC = TextEditingController(text: b['category'] ?? '');
    _lat = DatabaseHelper.toDouble(b['latitude']);
    _lng = DatabaseHelper.toDouble(b['longitude']);
    for (final d in _kDays)
      _hrs[d] = {'open': '09:00', 'close': '18:00', 'closed': false};
    _loadTurkey();
    _loadHours();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _telC.dispose();
    _catC.dispose();
    super.dispose();
  }

  Future<void> _loadTurkey() async {
    try {
      final raw = await rootBundle.loadString('assets/turkey.json');
      final list = json.decode(raw) as List<dynamic>;
      setState(() {
        _provinces = list;
        _turkeLoaded = true;
      });

      final parts = (widget.biz['address'] ?? '')
          .toString()
          .split(',')
          .map((s) => s.trim())
          .toList();
      if (parts.isEmpty) return;
      final pObj =
          list.firstWhere((p) => p['Province'] == parts[0], orElse: () => null);
      if (pObj == null) return;
      _province = parts[0];
      _districts = (pObj['Districts'] as List)
          .map((d) => d['District'] as String)
          .toList();
      if (parts.length > 1 && _districts.contains(parts[1])) {
        _district = parts[1];
        _fillHoods(pObj, parts[1]);
        if (parts.length > 2 && _hoods.contains(parts[2]))
          _neighbourhood = parts[2];
      }
      setState(() {});
    } catch (e) {
      print('turkey.json: $e');
    }
  }

  void _fillHoods(dynamic provObj, String distName) {
    final dObj = (provObj['Districts'] as List)
        .firstWhere((d) => d['District'] == distName, orElse: () => null);
    if (dObj == null) {
      _hoods = [];
      return;
    }
    final set = <String>{};
    for (final t in (dObj['Towns'] as List? ?? [])) {
      for (final n in (t['Neighbourhoods'] as List? ?? []))
        set.add(n.toString());
    }
    _hoods = set.toList()..sort();
  }

  Future<void> _loadHours() async {
    setState(() => _hrsLoading = true);
    final rows =
        await DatabaseHelper.getBusinessHours(widget.biz['shop_id'] as int);
    for (final r in rows) {
      final d = r['day_of_week'] as String;
      if (_hrs.containsKey(d))
        _hrs[d] = {
          'open': _ts(r['open_hour']),
          'close': _ts(r['close_hour']),
          'closed': r['is_closed'] == true
        };
    }
    setState(() => _hrsLoading = false);
  }

  String _ts(dynamic v) {
    if (v == null) return '09:00';
    final s = v.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Future<void> _pickTime(String day, String field) async {
    final p = (_hrs[day]![field] as String).split(':');
    final init = TimeOfDay(
        hour: int.tryParse(p[0]) ?? 9, minute: int.tryParse(p[1]) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null)
      setState(() => _hrs[day]![field] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _openMap() async {
    final result = await Navigator.push<Map<String, double>>(
        context,
        MaterialPageRoute(
            builder: (_) => _MapPickerPage(initLat: _lat, initLng: _lng)));
    if (result != null)
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
      });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final addr = [_province, _district, _neighbourhood]
          .where((s) => s != null && s!.isNotEmpty)
          .join(', ');
      final sid = widget.biz['shop_id'] as int;
      await DatabaseHelper.updateBusinessInfo(sid, {
        'name': _nameC.text.trim(),
        'address': addr,
        'description': _descC.text.trim(),
        'tel_no': _telC.text.trim(),
        'category': _catC.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
      });
      for (final day in _kDays) {
        await DatabaseHelper.upsertBusinessHour(sid, {
          'day_of_week': day,
          'open_hour': _hrs[day]!['closed'] ? null : _hrs[day]!['open'],
          'close_hour': _hrs[day]!['closed'] ? null : _hrs[day]!['close'],
          'is_closed': _hrs[day]!['closed'],
        });
      }
      widget.onSaved();
      if (mounted) _snack('Saved!', _kGreen);
    } catch (e) {
      if (mounted) _snack(e.toString(), Colors.red);
    }
    setState(() => _saving = false);
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Basic ─────────────────────────────────────────────────────
        _sh(Icons.store, 'Basic Information'),
        const SizedBox(height: 14),
        _tf('Business Name', _nameC, Icons.store_outlined),
        _tf('Category', _catC, Icons.category_outlined),
        _tf('Phone', _telC, Icons.phone_outlined, kb: TextInputType.phone),
        _tf('Description', _descC, Icons.info_outline, lines: 3),

        // ── Address dropdowns ─────────────────────────────────────────
        const SizedBox(height: 6),
        _sh(Icons.location_on, 'Address'),
        const SizedBox(height: 14),
        _lbl('Province'),
        _dd(
          value: _province,
          hint: 'Select province…',
          items: _turkeLoaded
              ? _provinces.map((p) => p['Province'] as String).toList()
              : [],
          onChange: (v) {
            final po = _provinces.firstWhere((p) => p['Province'] == v,
                orElse: () => null);
            setState(() {
              _province = v;
              _district = null;
              _neighbourhood = null;
              _districts = po != null
                  ? (po['Districts'] as List)
                      .map((d) => d['District'] as String)
                      .toList()
                  : [];
              _hoods = [];
            });
          },
        ),
        const SizedBox(height: 10),
        _lbl('District'),
        _dd(
          value: _district,
          hint: 'Select district…',
          items: _districts,
          onChange: _districts.isEmpty
              ? null
              : (v) {
                  final po = _provinces.firstWhere(
                      (p) => p['Province'] == _province,
                      orElse: () => null);
                  setState(() {
                    _district = v;
                    _neighbourhood = null;
                    if (po != null) _fillHoods(po, v!);
                  });
                },
        ),
        const SizedBox(height: 10),
        _lbl('Neighbourhood / Mahalle'),
        _dd(
          value: _neighbourhood,
          hint: 'Select neighbourhood…',
          items: _hoods,
          onChange:
              _hoods.isEmpty ? null : (v) => setState(() => _neighbourhood = v),
        ),

        // ── Map location ──────────────────────────────────────────────
        const SizedBox(height: 18),
        _sh(Icons.map, 'Business Location on Map'),
        const SizedBox(height: 10),
        if (_lat != null && _lng != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.location_pin, color: _kBlue, size: 18),
              const SizedBox(width: 8),
              Text('${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                  style: const TextStyle(
                      color: _kBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        OutlinedButton.icon(
          onPressed: _openMap,
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: Text(
              _lat != null ? 'Change Location on Map' : 'Pick Location on Map'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: const BorderSide(color: _kBlue),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // ── Operating hours ───────────────────────────────────────────
        const SizedBox(height: 20),
        _sh(Icons.schedule, 'Operating Hours'),
        const SizedBox(height: 14),
        if (_hrsLoading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()))
        else
          ..._kDays.map((day) => _HourRow(
                day: day,
                data: _hrs[day]!,
                onToggle: (v) => setState(() => _hrs[day]!['closed'] = v),
                onOpen: () => _pickTime(day, 'open'),
                onClose: () => _pickTime(day, 'close'),
              )),

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving…' : 'Save All Changes'),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sh(IconData ic, String t) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(ic, color: _kBlue, size: 22),
        const SizedBox(width: 8),
        Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))
      ]));
  Widget _lbl(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(t,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF444444))));

  Widget _tf(String label, TextEditingController ctrl, IconData ic,
          {int lines = 1, TextInputType? kb}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _lbl(label),
        TextField(
            controller: ctrl,
            maxLines: lines,
            keyboardType: kb,
            decoration: InputDecoration(
                prefixIcon: Icon(ic, color: _kBlue, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
        const SizedBox(height: 12),
      ]);

  Widget _dd(
          {required String? value,
          required String hint,
          required List<String> items,
          required ValueChanged<String?>? onChange}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400)),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChange,
        )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAP PICKER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _MapPickerPage extends StatefulWidget {
  final double? initLat, initLng;
  const _MapPickerPage({this.initLat, this.initLng});
  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  double? _lat, _lng;

  String _html() {
    final lat = widget.initLat ?? 39.9334;
    final lng = widget.initLng ?? 32.8597;
    return '''<!DOCTYPE html><html><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<style>*{margin:0;padding:0}html,body,#map{width:100%;height:100%}
#hint{position:absolute;top:10px;left:50%;transform:translateX(-50%);background:rgba(0,0,0,.65);color:#fff;padding:8px 18px;border-radius:20px;font-size:13px;z-index:999;pointer-events:none;font-family:sans-serif;white-space:nowrap}
</style></head><body>
<div id="hint">Tap anywhere to pin location</div>
<div id="map"></div>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
var map=L.map("map").setView([$lat,$lng],14);
L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",{maxZoom:19,attribution:"© OSM"}).addTo(map);
var mk=L.marker([$lat,$lng]).addTo(map);
map.on("click",function(e){
  mk.setLatLng(e.latlng);
  window.flutter_inappwebview.callHandler("pick",e.latlng.lat,e.latlng.lng);
  document.getElementById("hint").style.display="none";
});
window.addEventListener("flutterInAppWebViewPlatformReady",function(){window.flutter_inappwebview.callHandler("ready");});
</script></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
        title: const Text('Pin Business Location'),
        actions: [
          if (_lat != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, {'lat': _lat!, 'lng': _lng!}),
              child: const Text('CONFIRM',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
        ],
      ),
      body: Stack(children: [
        InAppWebView(
          initialData: InAppWebViewInitialData(data: _html()),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
          onWebViewCreated: (ctrl) {
            ctrl.addJavaScriptHandler(handlerName: 'ready', callback: (_) {});
            ctrl.addJavaScriptHandler(
                handlerName: 'pick',
                callback: (args) {
                  setState(() {
                    _lat = (args[0] as num).toDouble();
                    _lng = (args[1] as num).toDouble();
                  });
                });
          },
        ),
        if (_lat != null)
          Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12), blurRadius: 12)
                    ]),
                child: Row(children: [
                  const Icon(Icons.location_pin, color: _kBlue),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: _kBlue, fontWeight: FontWeight.w600))),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, {'lat': _lat!, 'lng': _lng!}),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('Use'),
                  ),
                ]),
              )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOUR ROW  (shared by Info tab + Staff form)
// ─────────────────────────────────────────────────────────────────────────────

class _HourRow extends StatelessWidget {
  final String day;
  final Map<String, dynamic> data;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpen, onClose;
  const _HourRow(
      {required this.day,
      required this.data,
      required this.onToggle,
      required this.onOpen,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    final closed = data['closed'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ]),
      child: Row(children: [
        SizedBox(
            width: 94,
            child: Text(day,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(width: 8),
        if (closed)
          const Expanded(
              child: Text('Closed',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500)))
        else ...[
          Expanded(
              child: GestureDetector(
                  onTap: onOpen, child: _chip(data['open'] as String))),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: GestureDetector(
                  onTap: onClose, child: _chip(data['close'] as String))),
        ],
        Switch(
            value: closed,
            onChanged: onToggle,
            activeColor: Colors.red,
            inactiveThumbColor: _kGreen),
      ]),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8)),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, color: _kBlue, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — PRODUCTS
// ═════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatefulWidget {
  final int shopId;
  const _ProductsTab({required this.shopId});
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await DatabaseHelper.getAllProductsByBusiness(widget.shopId);
    setState(() => _loading = false);
  }

  void _form([Map<String, dynamic>? p]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) =>
            _ProductForm(shopId: widget.shopId, product: p, onSaved: _load),
      );

  Future<void> _del(int id) async {
    if (!await _confirm(context, 'Delete this product?')) return;
    try {
      await DatabaseHelper.deleteProduct(id);
      _load();
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _form,
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Product')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? _empty(Icons.inventory_2_outlined, 'No products yet',
                    'Tap + to add your first product.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final p = _list[i];
                      final price =
                          DatabaseHelper.toDouble(p['product_prices']);
                      return _card(
                        title: p['name'] ?? '',
                        subtitle: p['categories'] ?? '',
                        trailing: price != null
                            ? '₺${price.toStringAsFixed(2)}'
                            : '—',
                        active: p['available'] == true,
                        onEdit: () => _form(p),
                        onDel: () => _del(p['id'] as int),
                      );
                    }),
      );
}

class _ProductForm extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;
  const _ProductForm(
      {required this.shopId, this.product, required this.onSaved});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late TextEditingController _nameC, _descC, _priceC, _newCatC;
  bool _avail = true, _bookable = false, _saving = false, _typeNew = false;
  String? _cat;
  List<String> _cats = [];
  File? _img;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameC = TextEditingController(text: p?['name'] ?? '');
    _descC = TextEditingController(text: p?['description'] ?? '');
    _priceC = TextEditingController(
        text:
            DatabaseHelper.toDouble(p?['product_prices'])?.toStringAsFixed(2) ??
                '');
    _newCatC = TextEditingController();
    _avail = p?['available'] ?? true;
    _bookable = p?['bookable'] == true;
    _cat = (p?['categories'] ?? '').toString().isNotEmpty
        ? p!['categories'].toString()
        : null;
    _loadCats();
  }

  Future<void> _loadCats() async {
    final c = await DatabaseHelper.getProductCategories();
    setState(() {
      _cats = c;
      if (_cat != null && !c.contains(_cat)) _cats.insert(0, _cat!);
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _priceC.dispose();
    _newCatC.dispose();
    super.dispose();
  }

  Future<void> _pickImg() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _img = File(x.path));
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) return;
    final cat = _typeNew ? _newCatC.text.trim() : (_cat ?? '');
    setState(() => _saving = true);
    try {
      await DatabaseHelper.upsertProductFull(widget.shopId, {
        'id': widget.product?['id'],
        'name': _nameC.text.trim(),
        'description': _descC.text.trim(),
        'product_prices': double.tryParse(_priceC.text) ?? 0,
        'categories': cat,
        'available': _avail,
        'bookable': _bookable,
      });
      if (_img != null)
        await DatabaseHelper.addProductPhoto(widget.shopId, _img!.path);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
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
                            widget.product == null
                                ? 'Add Product'
                                : 'Edit Product',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 16),
                  _sf('Name *', _nameC),
                  const SizedBox(height: 12),
                  // Category
                  const Text('Category',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  if (!_typeNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                        value: _cat,
                        isExpanded: true,
                        hint: const Text('Select or add category'),
                        items: [
                          ..._cats.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))),
                          const DropdownMenuItem(
                              value: '__new__',
                              child: Text('+ Type new…',
                                  style: TextStyle(color: _kBlue))),
                        ],
                        onChanged: (v) {
                          if (v == '__new__')
                            setState(() {
                              _typeNew = true;
                              _cat = null;
                            });
                          else
                            setState(() => _cat = v);
                        },
                      )),
                    )
                  else
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: _newCatC,
                              decoration: InputDecoration(
                                  hintText: 'New category name…',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none)))),
                      IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _typeNew = false)),
                    ]),
                  const SizedBox(height: 12),
                  _sf('Price (₺)', _priceC, kb: TextInputType.number),
                  const SizedBox(height: 12),
                  _sf('Description', _descC, lines: 3),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _tog('Available', _avail, _kGreen,
                            (v) => setState(() => _avail = v))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _tog('Bookable', _bookable, _kBlue,
                            (v) => setState(() => _bookable = v))),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Product Photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickImg,
                    child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300)),
                        child: _img != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_img!,
                                    fit: BoxFit.cover, width: double.infinity))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 34, color: Colors.grey),
                                    SizedBox(height: 6),
                                    Text('Tap to pick photo',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13)),
                                  ])),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(_saving ? 'Saving…' : 'Save Product',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ])),
      );

  Widget _sf(String lbl, TextEditingController c,
          {int lines = 1, TextInputType? kb}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lbl, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
            controller: c,
            maxLines: lines,
            keyboardType: kb,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      ]);

  Widget _tog(String lbl, bool on, Color col, ValueChanged<bool> cb) =>
      GestureDetector(
        onTap: () => cb(!on),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: on ? col.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? col : Colors.grey.shade300)),
            child: Column(children: [
              Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: on ? col : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(lbl,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: on ? col : Colors.grey.shade600)),
            ])),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — PRICE LIST
// ═════════════════════════════════════════════════════════════════════════════

class _PriceListTab extends StatefulWidget {
  final int shopId;
  const _PriceListTab({required this.shopId});
  @override
  State<_PriceListTab> createState() => _PriceListTabState();
}

class _PriceListTabState extends State<_PriceListTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await DatabaseHelper.getPriceLists(widget.shopId);
    setState(() => _loading = false);
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final i in _items)
      m
          .putIfAbsent(
              (i['categories'] ?? 'Uncategorised').toString(), () => [])
          .add(i);
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty)
      return _empty(Icons.price_change_outlined, 'No price list',
          'Add products from the Products tab.');
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _grouped.entries
              .map((e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: _kBlue,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14))),
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8)
                              ]),
                          child: Column(
                              children: e.value.asMap().entries.map((en) {
                            final idx = en.key;
                            final it = en.value;
                            final price =
                                DatabaseHelper.toDouble(it['product_prices']) ??
                                    0;
                            final disc =
                                DatabaseHelper.toDouble(it['discounted_price']);
                            final isD =
                                it['is_discounted'] == true && disc != null;
                            final isB = it['bookable'] == true;
                            return Column(children: [
                              if (idx > 0)
                                const Divider(
                                    height: 1, indent: 16, endIndent: 16),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Row(children: [
                                            Text(it['name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14)),
                                            if (isB) ...[
                                              const SizedBox(width: 6),
                                              _bdg('Bookable', _kBlue)
                                            ],
                                            if (it['available'] != true) ...[
                                              const SizedBox(width: 6),
                                              _bdg('Unavail.', Colors.grey)
                                            ],
                                          ]),
                                        ])),
                                    if (isD)
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text('₺${disc!.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: _kGreen)),
                                            Text('₺${price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ])
                                    else
                                      Text('₺${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: _kBlue)),
                                  ])),
                            ]);
                          }).toList()),
                        ),
                        const SizedBox(height: 8),
                      ]))
              .toList(),
        ));
  }

  Widget _bdg(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withOpacity(0.4))),
        child: Text(t,
            style:
                TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: c)),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4 — STAFF
// ═════════════════════════════════════════════════════════════════════════════

class _StaffTab extends StatefulWidget {
  final int shopId;
  const _StaffTab({required this.shopId});
  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await DatabaseHelper.getStaff(widget.shopId);
    setState(() => _loading = false);
  }

  void _form([Map<String, dynamic>? s]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) =>
            _StaffForm(shopId: widget.shopId, staff: s, onSaved: _load),
      );

  Future<void> _del(int id) async {
    if (!await _confirm(context, 'Remove this staff member?')) return;
    try {
      await DatabaseHelper.deleteStaff(id);
      _load();
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _form,
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Staff')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? _empty(Icons.people_outline, 'No staff yet',
                    'Tap + to add a team member.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final s = _list[i];
                      final r = DatabaseHelper.toDouble(s['rating']) ?? 0;
                      return _card(
                        title: s['full_name'] ?? '',
                        subtitle: s['role'] ?? '',
                        trailing: '⭐ ${r.toStringAsFixed(1)}',
                        active: s['is_active'] == true,
                        onEdit: () => _form(s),
                        onDel: () => _del(s['id'] as int),
                      );
                    }),
      );
}

class _StaffForm extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic>? staff;
  final VoidCallback onSaved;
  const _StaffForm({required this.shopId, this.staff, required this.onSaved});
  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  late TextEditingController _nameC, _roleC;
  bool _active = true, _saving = false;
  int? _staffId;

  final Map<String, Map<String, dynamic>> _hrs = {};
  bool _hrsLoading = false;

  List<Map<String, dynamic>> _bookable = [];
  Set<int> _services = {};
  bool _svcLoading = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.staff?['full_name'] ?? '');
    _roleC = TextEditingController(text: widget.staff?['role'] ?? '');
    _active = widget.staff?['is_active'] ?? true;
    _staffId = widget.staff?['id'] as int?;
    for (final d in _kDays)
      _hrs[d] = {'open': '09:00', 'close': '18:00', 'closed': false};
    _loadBookable();
    if (_staffId != null) {
      _loadHours();
      _loadServices();
    }
  }

  Future<void> _loadHours() async {
    setState(() => _hrsLoading = true);
    final rows = await DatabaseHelper.getStaffAvailability(_staffId!);
    for (final r in rows) {
      final d = r['day_of_week'] as String;
      if (_hrs.containsKey(d))
        _hrs[d] = {
          'open': _ts(r['start_time']),
          'close': _ts(r['end_time']),
          'closed': r['is_closed'] == true
        };
    }
    setState(() => _hrsLoading = false);
  }

  Future<void> _loadServices() async {
    final ids = await DatabaseHelper.getStaffServiceIds(_staffId!);
    setState(() => _services = ids.toSet());
  }

  Future<void> _loadBookable() async {
    setState(() => _svcLoading = true);
    _bookable = await DatabaseHelper.getBookableProducts(widget.shopId);
    setState(() => _svcLoading = false);
  }

  String _ts(dynamic v) {
    if (v == null) return '09:00';
    final s = v.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Future<void> _pickTime(String day, String field) async {
    final p = (_hrs[day]![field] as String).split(':');
    final init = TimeOfDay(
        hour: int.tryParse(p[0]) ?? 9, minute: int.tryParse(p[1]) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null)
      setState(() => _hrs[day]![field] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _save() async {
    if (_nameC.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final id = await DatabaseHelper.upsertStaff(widget.shopId, {
        'id': _staffId,
        'full_name': _nameC.text.trim(),
        'role': _roleC.text.trim(),
        'is_active': _active
      });
      for (final day in _kDays) {
        await DatabaseHelper.upsertStaffAvailability(id, {
          'day_of_week': day,
          'start_time': _hrs[day]!['closed'] ? null : _hrs[day]!['open'],
          'end_time': _hrs[day]!['closed'] ? null : _hrs[day]!['close'],
          'is_closed': _hrs[day]!['closed'],
        });
      }
      await DatabaseHelper.setStaffServices(id, _services.toList());
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _roleC.dispose();
    super.dispose();
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
                            widget.staff == null
                                ? 'Add Staff Member'
                                : 'Edit Staff Member',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: 16),
                  _sf('Full Name *', _nameC),
                  const SizedBox(height: 12),
                  _sf('Role / Title', _roleC),
                  const SizedBox(height: 8),
                  SwitchListTile(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: const Text('Active'),
                      activeColor: _kBlue,
                      contentPadding: EdgeInsets.zero),

                  // Services
                  const SizedBox(height: 16),
                  const Text('Assigned Bookable Services',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (_svcLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_bookable.isEmpty)
                    const Text(
                        'No bookable products yet. Mark products as Bookable first.',
                        style: TextStyle(color: Colors.grey, fontSize: 13))
                  else
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bookable.map((p) {
                          final id = p['id'] as int;
                          final on = _services.contains(id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (on)
                                _services.remove(id);
                              else
                                _services.add(id);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: on
                                    ? _kBlue.withOpacity(0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: on ? _kBlue : Colors.grey.shade300),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (on)
                                      const Icon(Icons.check,
                                          size: 14, color: _kBlue),
                                    if (on) const SizedBox(width: 4),
                                    Text(p['name'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: on
                                                ? _kBlue
                                                : Colors.grey.shade600)),
                                  ]),
                            ),
                          );
                        }).toList()),

                  // Working hours
                  const SizedBox(height: 20),
                  const Text('Working Hours',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_hrsLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._kDays.map((day) => _HourRow(
                          day: day,
                          data: _hrs[day]!,
                          onToggle: (v) =>
                              setState(() => _hrs[day]!['closed'] = v),
                          onOpen: () => _pickTime(day, 'open'),
                          onClose: () => _pickTime(day, 'close'),
                        )),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(_saving ? 'Saving…' : 'Save Staff Member',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ])),
      );

  Widget _sf(String lbl, TextEditingController c) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lbl, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
            controller: c,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 5 — BOOKINGS
// ═════════════════════════════════════════════════════════════════════════════

class _BookingsTab extends StatefulWidget {
  final int shopId;
  const _BookingsTab({required this.shopId});
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String _filter = 'all';
  DateTime? _date;
  static const _stt = [
    'all',
    'pending',
    'confirmed',
    'completed',
    'cancelled',
    'no_show',
    'rescheduled'
  ];
  static const _col = {
    'pending': _kOrange,
    'confirmed': _kBlue,
    'completed': _kGreen,
    'cancelled': Colors.red,
    'no_show': Colors.purple,
    'rescheduled': Color(0xFF00BCD4),
    'all': Colors.grey
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await DatabaseHelper.getAppointments(widget.shopId,
        status: _filter == 'all' ? null : _filter, date: _date);
    setState(() => _loading = false);
  }

  Future<void> _upd(int id, String s) async {
    try {
      await DatabaseHelper.updateAppointmentStatus(id, s);
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated to $s'), backgroundColor: _kGreen));
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _date ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (d != null) {
      setState(() => _date = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _stt.map((s) {
                        final sel = s == _filter;
                        final c = _col[s] ?? Colors.grey;
                        return GestureDetector(
                            onTap: () {
                              setState(() => _filter = s);
                              _load();
                            },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: sel ? c : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(s.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: sel
                                            ? Colors.white
                                            : Colors.grey.shade600))));
                      }).toList(),
                    ))),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _date != null ? _kBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today,
                        size: 14,
                        color: _date != null
                            ? Colors.white
                            : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                        _date != null
                            ? '${_date!.day}/${_date!.month}'
                            : 'Date',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _date != null
                                ? Colors.white
                                : Colors.grey.shade600)),
                    if (_date != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                          onTap: () {
                            setState(() => _date = null);
                            _load();
                          },
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white))
                    ],
                  ]),
                )),
          ]),
        ),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? _empty(Icons.calendar_month_outlined, 'No appointments',
                        'No appointments match your filter.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (_, i) =>
                            _AptCard(apt: _list[i], onStatus: _upd))),
      ]);
}

class _AptCard extends StatelessWidget {
  final Map<String, dynamic> apt;
  final Function(int, String) onStatus;
  const _AptCard({required this.apt, required this.onStatus});
  static const _next = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['completed', 'no_show', 'rescheduled', 'cancelled'],
    'rescheduled': ['confirmed', 'cancelled'],
    'completed': <String>[],
    'cancelled': <String>[],
    'no_show': <String>[]
  };
  static const _col = {
    'pending': _kOrange,
    'confirmed': _kBlue,
    'completed': _kGreen,
    'cancelled': Colors.red,
    'no_show': Colors.purple,
    'rescheduled': Color(0xFF00BCD4)
  };
  String _fd(dynamic d) {
    if (d == null) return '—';
    final s = d.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _ft(dynamic t) {
    if (t == null) return '—';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  Widget build(BuildContext context) {
    final st = (apt['status'] ?? 'pending').toString();
    final c = _col[st] ?? Colors.grey;
    final acts = _next[st] ?? [];
    final agreed = DatabaseHelper.toDouble(apt['agreed_price']);
    final listed = DatabaseHelper.toDouble(apt['listed_price']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: c, width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(apt['user_name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(apt['product_name'] ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.withOpacity(0.4))),
                  child: Text(st.toUpperCase(),
                      style: TextStyle(
                          color: c,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 16, children: [
              _ic(Icons.calendar_today, _fd(apt['appointment_date'])),
              _ic(Icons.access_time,
                  '${_ft(apt['start_time'])} – ${_ft(apt['end_time'])}'),
              if (apt['staff_name'] != null)
                _ic(Icons.person, apt['staff_name']),
              if (agreed != null)
                _ic(Icons.payments, '₺${agreed.toStringAsFixed(2)}')
              else if (listed != null)
                _ic(Icons.payments, '₺${listed.toStringAsFixed(2)}'),
            ]),
            if ((apt['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(apt['notes'].toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)
            ],
            if (acts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Update:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  ...acts.map((a) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () => onStatus(apt['id'] as int, a),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            side: BorderSide(color: _col[a] ?? Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: Text(a,
                            style: TextStyle(
                                fontSize: 11,
                                color: _col[a] ?? Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ))),
                ],
              )
            ],
          ])),
    );
  }

  Widget _ic(IconData ic, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(t, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 6 — OFFERS
// ═════════════════════════════════════════════════════════════════════════════

class _OffersTab extends StatefulWidget {
  final int shopId, ownerId;
  const _OffersTab({required this.shopId, required this.ownerId});
  @override
  State<_OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<_OffersTab> {
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;
  String _filter = 'all';
  static const _stt = ['all', 'pending', 'accepted', 'rejected', 'countered'];
  static const _col = {
    'pending': _kOrange,
    'accepted': _kGreen,
    'rejected': Colors.red,
    'countered': _kBlue,
    'all': Colors.grey
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _offers = await DatabaseHelper.getBusinessOffers(widget.shopId,
        status: _filter == 'all' ? null : _filter);
    setState(() => _loading = false);
  }

  Future<void> _accept(int id) async {
    try {
      await DatabaseHelper.updateOfferStatus(id, 'accepted');
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Offer accepted'), backgroundColor: _kGreen));
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  Future<void> _reject(int id) async {
    try {
      await DatabaseHelper.updateOfferStatus(id, 'rejected');
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Offer rejected'), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  Future<void> _counter(Map<String, dynamic> offer) async {
    double? val;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Counter Offer'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        'Customer offered: ₺${DatabaseHelper.toDouble(offer['offered_price'])?.toStringAsFixed(2) ?? "—"}'),
                    const SizedBox(height: 12),
                    TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Your counter price (₺)',
                            border: OutlineInputBorder())),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        val = double.tryParse(ctrl.text);
                        Navigator.pop(context, val != null);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
                      child: const Text('Send',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )) ??
        false;
    ctrl.dispose();
    if (!ok || val == null) return;
    try {
      await DatabaseHelper.updateOfferStatus(offer['id'] as int, 'countered',
          counterPrice: val);
      _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Counter offer sent'), backgroundColor: _kBlue));
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stt.map((s) {
                  final sel = s == _filter;
                  final c = _col[s] ?? Colors.grey;
                  return GestureDetector(
                      onTap: () {
                        setState(() => _filter = s);
                        _load();
                      },
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                              color: sel ? c : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(s.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade600))));
                }).toList(),
              )),
        ),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _offers.isEmpty
                    ? _empty(Icons.local_offer_outlined, 'No offers',
                        'Customer offers will appear here.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _offers.length,
                            itemBuilder: (_, i) {
                              final o = _offers[i];
                              final st = (o['status'] ?? 'pending').toString();
                              final c = _col[st] ?? Colors.grey;
                              final offered =
                                  DatabaseHelper.toDouble(o['offered_price']);
                              final counter =
                                  DatabaseHelper.toDouble(o['counter_price']);
                              final isPending = st == 'pending';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border(
                                        left: BorderSide(color: c, width: 4)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8)
                                    ]),
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    _kBlue.withOpacity(0.15),
                                                child: Text(
                                                    (o['user_name'] ?? '?')[0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: _kBlue,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(o['user_name'] ?? '',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14)),
                                                  if ((o['product_name'] ?? '')
                                                      .toString()
                                                      .isNotEmpty)
                                                    Text(
                                                        o['product_name']
                                                            .toString(),
                                                        style:
                                                            TextStyle(
                                                                color: Colors
                                                                    .grey
                                                                    .shade600,
                                                                fontSize: 12)),
                                                ])),
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: c.withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                        color: c
                                                            .withOpacity(0.4))),
                                                child: Text(st.toUpperCase(),
                                                    style: TextStyle(
                                                        color: c,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                          ]),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            _ppill(
                                                'Offered', offered, _kOrange),
                                            if (counter != null) ...[
                                              const SizedBox(width: 10),
                                              _ppill('Counter', counter, _kBlue)
                                            ],
                                          ]),
                                          if ((o['note'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text('"${o['note']}"',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                    fontStyle:
                                                        FontStyle.italic))
                                          ],
                                          if ((o['created_time'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(_fmtDate(o['created_time']),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.grey.shade400))
                                          ],
                                          if (isPending) ...[
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Row(children: [
                                              Expanded(
                                                  child: OutlinedButton.icon(
                                                      onPressed: () => _reject(
                                                          o['id'] as int),
                                                      icon: const Icon(
                                                          Icons.close,
                                                          size: 16),
                                                      label:
                                                          const Text('Reject'),
                                                      style: OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              Colors.red,
                                                          side:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .red),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      10))))),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: OutlinedButton.icon(
                                                      onPressed: () =>
                                                          _counter(o),
                                                      icon: const Icon(
                                                          Icons.swap_horiz,
                                                          size: 16),
                                                      label:
                                                          const Text('Counter'),
                                                      style: OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              _kBlue,
                                                          side:
                                                              const BorderSide(
                                                                  color:
                                                                      _kBlue),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10))))),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: ElevatedButton.icon(
                                                      onPressed: () => _accept(
                                                          o['id'] as int),
                                                      icon: const Icon(
                                                          Icons.check,
                                                          size: 16),
                                                      label:
                                                          const Text('Accept'),
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              _kGreen,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10))))),
                                            ]),
                                          ],
                                        ])),
                              );
                            }))),
      ]);

  Widget _ppill(String lbl, double? price, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withOpacity(0.4))),
        child: Column(children: [
          Text(lbl, style: TextStyle(fontSize: 10, color: c)),
          Text(price != null ? '₺${price.toStringAsFixed(2)}' : '—',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: c))
        ]),
      );

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return d.toString().substring(0, 10);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 7 — MESSAGES  (uses chats + messages schema)
// ═════════════════════════════════════════════════════════════════════════════

class _MessagesTab extends StatefulWidget {
  final int businessId, ownerId;
  const _MessagesTab({required this.businessId, required this.ownerId});
  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _chats = await DatabaseHelper.getBusinessChats(widget.businessId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_chats.isEmpty)
      return _empty(Icons.chat_bubble_outline, 'No messages yet',
          'Customer conversations will appear here.');
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _chats.map((ch) {
            final unread = int.tryParse(ch['unread']?.toString() ?? '0') ?? 0;
            final hasBold = unread > 0;
            return GestureDetector(
              onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => _ChatScreen(
                              chatId: ch['chat_id'] as int,
                              ownerId: widget.ownerId,
                              otherName: ch['user_name'] ?? 'Customer')))
                  .then((_) => _load()),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
                    ]),
                child: Row(children: [
                  CircleAvatar(
                      radius: 22,
                      backgroundColor: _kBlue.withOpacity(0.15),
                      child: Text((ch['user_name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              color: _kBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(ch['user_name'] ?? '',
                            style: TextStyle(
                                fontWeight: hasBold
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(ch['last_msg'] ?? 'No messages yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: hasBold
                                    ? FontWeight.w600
                                    : FontWeight.normal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ])),
                  if (hasBold)
                    Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: _kBlue, shape: BoxShape.circle),
                        child: Center(
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)))),
                ]),
              ),
            );
          }).toList(),
        ));
  }
}

class _ChatScreen extends StatefulWidget {
  final int chatId, ownerId;
  final String otherName;
  const _ChatScreen(
      {required this.chatId, required this.ownerId, required this.otherName});
  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  List<Map<String, dynamic>> _msgs = [];
  final _ctrl = TextEditingController();
  bool _sending = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    DatabaseHelper.markChatRead(widget.chatId);
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
      await DatabaseHelper.sendOwnerMessage(widget.chatId, widget.ownerId, t);
      _ctrl.clear();
      await _load();
    } catch (e) {
      if (mounted) _errSnack(context, e.toString());
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            title: Text(widget.otherName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
            ]),
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
                        final isMe = (m['sender_type'] ?? '') == 'owner';
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: isMe ? _kBlue : Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16)),
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
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text(_fmtT(m['created_at']),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white60
                                              : Colors.grey.shade400)),
                                ]),
                          ),
                        );
                      })),
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
                                fillColor: _kBg,
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
                                color: _kBlue, shape: BoxShape.circle),
                            child: _sending
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20))),
                  ]))),
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

// ═════════════════════════════════════════════════════════════════════════════
// TAB 8 — REVIEWS
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewsTab extends StatefulWidget {
  final int shopId;
  const _ReviewsTab({required this.shopId});
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await DatabaseHelper.getOwnerReviews(widget.shopId);
    setState(() => _loading = false);
  }

  double get _avg => _list.isEmpty
      ? 0
      : _list.fold<int>(0, (a, r) => a + ((r['rank'] as int?) ?? 0)) /
          _list.length;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
        onRefresh: _load,
        child: Column(children: [
          if (_list.isNotEmpty)
            Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
                    ]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sb('${_list.length}', 'Total', _kBlue),
                      _sb(_avg.toStringAsFixed(1), 'Avg ⭐',
                          const Color(0xFFFFC107)),
                      _sb('${_list.where((r) => r['is_approved'] == true).length}',
                          'Approved', _kGreen),
                    ])),
          Expanded(
              child: _list.isEmpty
                  ? _empty(Icons.rate_review_outlined, 'No reviews yet',
                      'Customer reviews will appear here.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final r = _list[i];
                        final rank = (r['rank'] as int?) ?? 0;
                        final ok = r['is_approved'] == true;
                        return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border(
                                    left: BorderSide(
                                        color: ok ? _kGreen : Colors.orange,
                                        width: 3)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6)
                                ]),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            _kBlue.withOpacity(0.15),
                                        child: Text(
                                            (r['full_name'] ?? '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: _kBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12))),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(r['full_name'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Row(
                                              children: List.generate(
                                                  5,
                                                  (j) => Icon(
                                                      j < rank
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      size: 12,
                                                      color: const Color(
                                                          0xFFFFC107)))),
                                        ])),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color:
                                                (ok ? _kGreen : Colors.orange)
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text(ok ? 'Approved' : 'Pending',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: ok
                                                    ? _kGreen
                                                    : Colors.orange))),
                                  ]),
                                  if ((r['comments'] ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(r['comments'],
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700))
                                  ],
                                ]));
                      })),
        ]));
  }

  Widget _sb(String v, String l, Color c) => Column(children: [
        Text(v,
            style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
        Text(l, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═════════════════════════════════════════════════════════════════════════════

Widget _card(
        {required String title,
        required String subtitle,
        required String trailing,
        required bool active,
        required VoidCallback onEdit,
        required VoidCallback onDel}) =>
    Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: (active ? _kBlue : Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.circle,
                  size: 10, color: active ? _kGreen : Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
          Text(trailing,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: _kBlue)),
          const SizedBox(width: 8),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20, color: _kBlue)),
          IconButton(
              onPressed: onDel,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red)),
        ]));

Widget _empty(IconData ic, String title, String sub) => Center(
    child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ])));

Future<bool> _confirm(BuildContext ctx, String msg) async =>
    await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
                title: const Text('Confirm'),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)))
                ])) ??
    false;

void _errSnack(BuildContext ctx, String msg) => ScaffoldMessenger.of(ctx)
    .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

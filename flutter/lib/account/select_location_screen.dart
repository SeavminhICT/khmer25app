import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart' as olc;

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final MapController _controller = MapController();
  final LatLng _center = const LatLng(11.5564, 104.9282); // Phnom Penh default
  LatLng? _pin;
  final TextEditingController _labelCtrl = TextEditingController();
  final List<String> _quickLabels = const ['Home', 'Office', 'Store', 'Other'];

  @override
  void initState() {
    super.initState();
    _labelCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  String _composeLabel(LatLng pin, String custom) {
    final plus = olc.PlusCode.encode(pin, codeLength: 10).toString();
    final codeOnly = plus.split(' ').first;
    final trimmed = custom.trim();
    if (trimmed.isEmpty) return codeOnly;
    return '$codeOnly, $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final fallbackLabel = _pin == null ? '' : _composeLabel(_pin!, '');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.navigation_rounded,
                            color: Colors.green.shade700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pin your delivery spot',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Drag the map or tap to drop a pin. Add a label to help drivers.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickLabels
                        .map(
                          (label) => ChoiceChip(
                            label: Text(label),
                            selected:
                                _labelCtrl.text.trim().toLowerCase() ==
                                    label.toLowerCase(),
                            onSelected: (_) =>
                                _labelCtrl.text = label,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: 360,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _pin ?? _center,
                    initialZoom: 13,
                    onTap: (tapPosition, point) {
                      setState(() => _pin = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    if (_pin != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pin!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _labelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location title',
                    hintText: 'Home, Office, Store...',
                    prefixIcon: const Icon(Icons.place_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      _pin == null
                          ? Icons.info_outline
                          : Icons.check_circle,
                      color: _pin == null
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _pin == null
                            ? 'Tap on the map to drop a pin.'
                            : 'Selected: ${_labelCtrl.text.trim().isEmpty ? fallbackLabel : _composeLabel(_pin!, _labelCtrl.text.trim())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _pin == null
                        ? null
                        : () {
                            final custom = _labelCtrl.text.trim();
                            final label = _composeLabel(_pin!, custom);
                            Navigator.pop(context, {
                              "lat": _pin!.latitude,
                              "lng": _pin!.longitude,
                              "label": label,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                    label: const Text(
                      'Use this location',
                      style: TextStyle(fontSize: 16),
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

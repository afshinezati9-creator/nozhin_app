import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

/// انتخاب موقعیت روی نقشه OpenStreetMap
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _point;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _point = LatLng(
      widget.initialLat ?? 35.6892,
      widget.initialLng ?? 51.3890,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب موقعیت روی نقشه'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _point.latitude,
                'lng': _point.longitude,
              });
            },
            child: Text(
              'تأیید',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.brand3,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 14,
              onTap: (_, latLng) => setState(() => _point = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nozhin.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'روی نقشه بزن تا موقعیت انتخاب شود',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'عرض: ${_point.latitude.toStringAsFixed(5)}   طول: ${_point.longitude.toStringAsFixed(5)}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'lat': _point.latitude,
                          'lng': _point.longitude,
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand3,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('تأیید این موقعیت'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

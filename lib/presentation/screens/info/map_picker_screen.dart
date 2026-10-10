import 'package:flutter/material.dart';

/// انتخاب مختصات بدون وابستگی به flutter_map / اینترنت.
/// (نقشه آنلاین حذف شده — فقط ورود دستی عرض/طول جغرافیایی)
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(
      text: widget.initialLat?.toStringAsFixed(6) ?? '',
    );
    _lng = TextEditingController(
      text: widget.initialLng?.toStringAsFixed(6) ?? '',
    );
  }

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _submit() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عرض و طول جغرافیایی را درست وارد کن')),
      );
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مختصات خارج از محدوده است')),
      );
      return;
    }
    Navigator.pop(context, {'lat': lat, 'lng': lng});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مختصات مکانی')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نقشه آنلاین در نسخه آفلاین فعال نیست. مختصات را دستی وارد کن یا از اپ نقشه کپی کن.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'عرض جغرافیایی (Latitude)',
                hintText: 'مثال: 35.6892',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lng,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'طول جغرافیایی (Longitude)',
                hintText: 'مثال: 51.3890',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('تأیید مختصات'),
            ),
          ],
        ),
      ),
    );
  }
}

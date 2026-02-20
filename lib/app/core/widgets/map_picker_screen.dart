// اختيار موقع على الخريطة — شاشة كاملة أو حوار (مربّع)

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_colors.dart';

/// نتيجة اختيار الموقع: (lat, lng) أو null عند الإلغاء
typedef MapPickerResult = ({double lat, double lng})?;

/// عرض خريطة اختيار الموقع كـ **حوار** (مربّع) — لا تملأ الشاشة.
/// يعيد [MapPickerResult] عند الإغلاق.
Future<MapPickerResult> showMapPickerDialog(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
  String title = 'تحديد موقع المسجد',
}) async {
  return showDialog<MapPickerResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _MapPickerDialogBody(
      title: title,
      initialLat: initialLat,
      initialLng: initialLng,
      mapHeight: 320,
    ),
  );
}

/// جسم الحوار: خريطة بحجم ثابت + زرّي إلغاء وتأكيد
class _MapPickerDialogBody extends StatefulWidget {
  const _MapPickerDialogBody({
    required this.title,
    this.initialLat,
    this.initialLng,
    required this.mapHeight,
  });

  final String title;
  final double? initialLat;
  final double? initialLng;
  final double mapHeight;

  @override
  State<_MapPickerDialogBody> createState() => _MapPickerDialogBodyState();
}

class _MapPickerDialogBodyState extends State<_MapPickerDialogBody> {
  static const _defaultLat = 24.7136;
  static const _defaultLng = 46.6753;

  late final MapController _mapController;
  LatLng? _selected;
  LatLng? _myLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _fetchMyLocation();
  }

  Future<void> _fetchMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  LatLng get _center {
    if (_selected != null) return _selected!;
    if (_myLocation != null) return _myLocation!;
    return LatLng(widget.initialLat ?? _defaultLat, widget.initialLng ?? _defaultLng);
  }

  void _onConfirm() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اضغط على الخريطة لتحديد موقع المسجد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop<MapPickerResult>((lat: _selected!.latitude, lng: _selected!.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: widget.mapHeight,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: _myLocation != null ? 15 : 14,
                      onTap: (_, point) => setState(() => _selected = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.salati_hayati.app',
                      ),
                      if (_myLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _myLocation!,
                              width: 32,
                              height: 32,
                              child: const Icon(Icons.my_location, color: AppColors.info, size: 32),
                            ),
                          ],
                        ),
                      if (_selected != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selected!,
                              width: 48,
                              height: 48,
                              child: const Icon(Icons.location_on, color: AppColors.error, size: 48),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (_loadingLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text('جاري تحديد موقعك...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              else if (_myLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('النقطة الزرقاء = موقعك الحالي', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              const SizedBox(height: 8),
              Text(
                _selected == null
                    ? 'اضغط على مكان المسجد بالضبط (النقطة الحمراء = موقع المسجد)'
                    : 'الموقع: ${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<MapPickerResult>(null),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _onConfirm,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('تأكيد الموقع'),
          ),
        ],
      ),
    );
  }
}

/// شاشة كاملة لاختيار الموقع (للاحتياج لاحقاً)
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'تحديد الموقع على الخريطة',
  });

  final double? initialLat;
  final double? initialLng;
  final String title;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultLat = 24.7136;
  static const _defaultLng = 46.6753;

  late final MapController _mapController;
  LatLng? _selected;
  LatLng? _myLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _fetchMyLocation();
  }

  Future<void> _fetchMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  LatLng get _center {
    if (_selected != null) return _selected!;
    if (_myLocation != null) return _myLocation!;
    return LatLng(widget.initialLat ?? _defaultLat, widget.initialLng ?? _defaultLng);
  }

  void _onConfirm() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اضغط على الخريطة لتحديد موقع المسجد'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop<MapPickerResult>((lat: _selected!.latitude, lng: _selected!.longitude));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop<MapPickerResult>(null),
          ),
          actions: [
            FilledButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('تأكيد الموقع'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _myLocation != null ? 15 : 14,
            onTap: (_, point) => setState(() => _selected = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salati_hayati.app',
            ),
            if (_myLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _myLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: AppColors.info, size: 40),
                  ),
                ],
              ),
            if (_selected != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected!,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on, color: AppColors.error, size: 48),
                  ),
                ],
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingLocation)
                  const Text('جاري تحديد موقعك...', style: TextStyle(fontSize: 12))
                else if (_myLocation != null)
                  const Text('النقطة الزرقاء = موقعك الحالي', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _selected == null
                      ? 'اضغط على مكان المسجد بالضبط على الخريطة (النقطة الحمراء = موقع المسجد)'
                      : 'الموقع: ${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

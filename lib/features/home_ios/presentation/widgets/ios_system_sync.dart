import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/fuel/data/services/gas_station_service.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_system_bridge.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';

/// Đồng bộ GPS + trạm xăng gần nhất vào [IosSystemBridge] cho Dynamic Island.
class IosSystemSync extends StatefulWidget {
  const IosSystemSync({super.key, required this.child});

  final Widget child;

  @override
  State<IosSystemSync> createState() => _IosSystemSyncState();
}

class _IosSystemSyncState extends State<IosSystemSync> {
  final _gasService = GasStationService();
  LatLng? _lastFetchOrigin;
  DateTime? _lastFetchAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<LocationService>().addListener(_onLocation);
    _onLocation();
  }

  @override
  void dispose() {
    context.read<LocationService>().removeListener(_onLocation);
    super.dispose();
  }

  void _onLocation() {
    final location = context.read<LocationService>();
    final bridge = context.read<IosSystemBridge>();
    final pos = location.currentPosition;

    if (pos == null) return;

    final origin = LatLng(pos.latitude, pos.longitude);
    final shouldFetch = _lastFetchOrigin == null ||
        _lastFetchAt == null ||
        DateTime.now().difference(_lastFetchAt!) > const Duration(minutes: 2);

    if (!shouldFetch) return;

    _lastFetchOrigin = origin;
    _lastFetchAt = DateTime.now();
    bridge.setLoadingStations(true);

    _gasService
        .findNearestStations(origin: origin, limit: 1)
        .then((stations) {
      if (!mounted) return;
      bridge.setNearestStation(stations.isNotEmpty ? stations.first : null);
      bridge.setLoadingStations(false);
    }).catchError((_) {
      if (!mounted) return;
      bridge.setLoadingStations(false);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/models/plan_entity.dart';

import 'package:trufi_core/pages/home/repository/local_repository.dart';

class MapRouteHiveLocalRepository implements MapRouteLocalRepository {
  static const String path = "MapRouteHiveLocalRepository";
  static const _planKey = 'MapRouteHiveLocalRepository_Plan';
  static const _originKey = 'MapRouteHiveLocalRepository_Origin';
  static const _destinationKey = 'MapRouteHiveLocalRepository_Destination';

  late Box _box;

  @override
  Future<void> loadRepository() async {
    _box = Hive.box(path);
  }

  @override
  Future<PlanEntity?> getPlan() async {
    final data = _box.get(_planKey);
    if (data == null) return null;
    return PlanEntity.fromJson(jsonDecode(data));
  }

  @override
  Future<void> savePlan(PlanEntity? data) async {
    await _box.put(_planKey, data != null ? jsonEncode(data) : null);
  }

  @override
  Future<void> saveOriginPosition(latlng.LatLng? position) async {
    if (position == null) {
      await _box.put(_originKey, null);
      return;
    }
    await _box.put(_originKey, jsonEncode({
      'lat': position.latitude,
      'lng': position.longitude,
    }));
  }

  @override
  Future<latlng.LatLng?> getOriginPosition() async {
    final data = _box.get(_originKey);
    if (data == null) return null;
    final map = jsonDecode(data);
    final lat = (map['lat'] as num).toDouble();
    final lng = (map['lng'] as num).toDouble();
    return latlng.LatLng(lat, lng);
    }

  @override
  Future<void> saveDestinationPosition(latlng.LatLng? position) async {
    if (position == null) {
      await _box.put(_destinationKey, null);
      return;
    }
    await _box.put(_destinationKey, jsonEncode({
      'lat': position.latitude,
      'lng': position.longitude,
    }));
  }

  @override
  Future<latlng.LatLng?> getDestinationPosition() async {
    final data = _box.get(_destinationKey);
    if (data == null) return null;
    final map = jsonDecode(data);
    final lat = (map['lat'] as num).toDouble();
    final lng = (map['lng'] as num).toDouble();
    return latlng.LatLng(lat, lng);
  }
}

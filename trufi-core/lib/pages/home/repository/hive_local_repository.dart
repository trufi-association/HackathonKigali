import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:trufi_core/models/plan_entity.dart';

import 'package:trufi_core/pages/home/repository/local_repository.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

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
  Future<void> saveOriginPosition(TrufiLocation? location) async {
    if (location == null) {
      await _box.put(_originKey, null);
      return;
    }
    await _box.put(_originKey, jsonEncode(location.toJson()));
  }

  @override
  Future<TrufiLocation?> getOriginPosition() async {
    final data = _box.get(_originKey);
    if (data == null) return null;
    return TrufiLocation.fromJson(jsonDecode(data));
  }

  @override
  Future<void> saveDestinationPosition(TrufiLocation? location) async {
    if (location == null) {
      await _box.put(_destinationKey, null);
      return;
    }
    await _box.put(_destinationKey, jsonEncode(location.toJson()));
  }

  @override
  Future<TrufiLocation?> getDestinationPosition() async {
    final data = _box.get(_destinationKey);
    if (data == null) return null;
    return TrufiLocation.fromJson(jsonDecode(data));
  }
}

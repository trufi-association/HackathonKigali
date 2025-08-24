import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:trufi_core/models/plan_entity.dart';

import 'package:trufi_core/pages/home/repository/local_repository.dart';

class MapRouteHiveLocalRepository implements MapRouteLocalRepository {
  static const String path = "MapRouteHiveLocalRepository";
  static const _planKey = 'MapRouteHiveLocalRepository_Plan';
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
}

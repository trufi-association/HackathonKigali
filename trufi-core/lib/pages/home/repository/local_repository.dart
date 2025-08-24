import 'package:trufi_core/models/plan_entity.dart';

abstract class MapRouteLocalRepository {
  Future<void> loadRepository();

  Future<void> savePlan(PlanEntity? data);
  Future<PlanEntity?> getPlan();

}

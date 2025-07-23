import 'package:trufi_core/models/plan_entity.dart';
import 'package:trufi_core/trufi_map_controller.dart';

abstract class IPlanRepository {
  Future<PlanEntity> fetchPlanAdvanced({
    required TrufiLocation fromLocation,
    required TrufiLocation toLocation,
    int numItineraries,
    String? locale,
    bool defaultFecth,
    bool useDefaultModes = false,
  });
}

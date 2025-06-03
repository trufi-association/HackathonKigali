import 'package:stadtnavi_core/base/models/plan_entity.dart';
import 'package:trufi_core/base/models/trufi_place.dart';
import 'package:stadtnavi_core/base/models/othermodel/plan.dart';
import 'package:stadtnavi_core/base/models/othermodel/modes_transport.dart';
import 'package:stadtnavi_core/base/pages/home/cubits/payload_data_plan/setting_fetch_cubit.dart';

abstract class IPlanRepository {
  /// Fetches a detailed plan using the provided locations and advanced settings.
  Future<PlanEntity> fetchPlanAdvanced({
    required TrufiLocation fromLocation,
    required TrufiLocation toLocation,
    required SettingFetchState advancedOptions,
    int numItineraries,
    String? locale,
    bool defaultFecth,
  });

  /// Fetches summary modes including walk, bike, car, and park-ride options.
  Future<ModesTransport> fetchWalkBikePlanQuery({
    required TrufiLocation fromLocation,
    required TrufiLocation toLocation,
    required SettingFetchState advancedOptions,
    String? locale,
  });
}
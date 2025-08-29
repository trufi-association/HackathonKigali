import 'package:latlong2/latlong.dart' as latlng;
import 'package:trufi_core/models/plan_entity.dart';

abstract class MapRouteLocalRepository {
  Future<void> loadRepository();

  Future<void> savePlan(PlanEntity? data);
  Future<PlanEntity?> getPlan();

  Future<void> saveOriginPosition(latlng.LatLng? position);
  Future<latlng.LatLng?> getOriginPosition();

  Future<void> saveDestinationPosition(latlng.LatLng? position);
  Future<latlng.LatLng?> getDestinationPosition();
}

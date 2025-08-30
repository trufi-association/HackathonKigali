import 'package:latlong2/latlong.dart';
import 'package:trufi_core/screens/route_navigation/maps/trufi_map_controller.dart';

enum DefaultLocationEnum { defaultHome, defaultWork }

extension DefaultLocationExtension on DefaultLocationEnum {
  static final initLocations = <DefaultLocationEnum, TrufiLocation>{
    DefaultLocationEnum.defaultHome: TrufiLocation(
      description: keys[DefaultLocationEnum.defaultHome]!,
      position: LatLng(0, 0),
      type: 'saved_place:home',
    ),
    DefaultLocationEnum.defaultWork: TrufiLocation(
      description: keys[DefaultLocationEnum.defaultWork]!,
      position: LatLng(0, 0),
      type: 'saved_place:work',
    ),
  };

  static final keys = <DefaultLocationEnum, String>{
    DefaultLocationEnum.defaultHome: 'Key-Default-Home',
    DefaultLocationEnum.defaultWork: 'Key-Default-Work',
  };

  TrufiLocation get initLocation => initLocations[this]!;

  String get keyLocation => keys[this]!;
}

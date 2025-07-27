import 'vehicle_parking.dart';

class VehicleParkingWithEntrance {
  final VehicleParking? vehicleParking;
  final bool? closesSoon;
  final bool? realtime;

  const VehicleParkingWithEntrance({
    this.vehicleParking,
    this.closesSoon,
    this.realtime,
  });

  static const String _vehicleParking = 'vehicleParking';
  static const String _closesSoon = 'closesSoon';
  static const String _realtime = 'realtime';

  factory VehicleParkingWithEntrance.fromMap(Map<String, dynamic> json) =>
      VehicleParkingWithEntrance(
        vehicleParking:
            json[_vehicleParking] != null
                ? VehicleParking.fromMap(
                  json[_vehicleParking] as Map<String, dynamic>,
                )
                : null,
        closesSoon: json[_closesSoon],
        realtime: json[_realtime],
      );

  Map<String, dynamic> toMap() => {
    _vehicleParking: vehicleParking?.toMap(),
    _closesSoon: closesSoon,
    _realtime: realtime,
  };
}

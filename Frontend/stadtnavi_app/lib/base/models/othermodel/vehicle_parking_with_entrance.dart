import 'package:equatable/equatable.dart';
import 'vehicle_parking.dart';

class VehicleParkingWithEntrance extends Equatable {
  final VehicleParking? vehicleParking;
  final bool? closesSoon;
  final bool? realtime;

  const VehicleParkingWithEntrance({
    this.vehicleParking,
    this.closesSoon,
    this.realtime,
  });

  factory VehicleParkingWithEntrance.fromMap(Map<String, dynamic> json) =>
      VehicleParkingWithEntrance(
        vehicleParking: json['vehicleParking'] != null
            ? VehicleParking.fromMap(
                json['vehicleParking'] as Map<String, dynamic>)
            : null,
        closesSoon: json['closesSoon'] as bool?,
        realtime: json['realtime'] as bool?,
      );

  Map<String, dynamic> toMap() => {
        'vehicleParking': vehicleParking?.toMap(),
        'closesSoon': closesSoon,
        'realtime': realtime,
      };

  @override
  List<Object?> get props => [
        vehicleParking,
        closesSoon,
        realtime,
      ];
}

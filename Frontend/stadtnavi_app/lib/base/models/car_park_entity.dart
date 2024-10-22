part of 'plan_entity.dart';

class CarParkEntity extends Equatable {
  final String? id;
  final String? carParkId;
  final String? name;
  final int? maxCapacity;
  final int? spacesAvailable;
  final bool? realtime;
  final double? lon;
  final double? lat;

  const CarParkEntity({
    this.id,
    this.carParkId,
    this.name,
    this.maxCapacity,
    this.spacesAvailable,
    this.realtime,
    this.lon,
    this.lat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carParkId': carParkId,
      'name': name,
      'maxCapacity': maxCapacity,
      'spacesAvailable': spacesAvailable,
      'realtime': realtime,
      'lon': lon,
      'lat': lat,
    };
  }

  factory CarParkEntity.fromMap(Map<String, dynamic> map) {
    return CarParkEntity(
      id: map['id'] as String?,
      carParkId: map['carParkId'] as String?,
      name: map['name'] as String?,
      maxCapacity: map['maxCapacity'] as int?,
      spacesAvailable: map['spacesAvailable'] as int?,
      realtime: map['realtime'] as bool?,
      lon: map['lon'] as double?,
      lat: map['lat'] as double?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        carParkId,
        name,
        maxCapacity,
        spacesAvailable,
        realtime,
        lon,
        lat,
      ];
}

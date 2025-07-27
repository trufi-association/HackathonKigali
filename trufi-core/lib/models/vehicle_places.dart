class VehiclePlaces {
  final int? bicycleSpaces;
  final int? carSpaces;
  final int? wheelchairAccessibleCarSpaces;

  const VehiclePlaces({
    this.bicycleSpaces,
    this.carSpaces,
    this.wheelchairAccessibleCarSpaces,
  });

  static const String _bicycleSpaces = 'bicycleSpaces';
  static const String _carSpaces = 'carSpaces';
  static const String _wheelchairAccessibleCarSpaces =
      'wheelchairAccessibleCarSpaces';

  factory VehiclePlaces.fromMap(Map<String, dynamic> json) => VehiclePlaces(
    bicycleSpaces: json[_bicycleSpaces],
    carSpaces: json[_carSpaces],
    wheelchairAccessibleCarSpaces: json[_wheelchairAccessibleCarSpaces],
  );

  Map<String, dynamic> toMap() => {
    _bicycleSpaces: bicycleSpaces,
    _carSpaces: carSpaces,
    _wheelchairAccessibleCarSpaces: wheelchairAccessibleCarSpaces,
  };
}

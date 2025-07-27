class Coordinates {
  final double? lat;
  final double? lon;

  const Coordinates({this.lat, this.lon});

  static const String _lat = 'lat';
  static const String _lon = 'lon';

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      Coordinates(lat: json[_lat], lon: json[_lon]);

  Map<String, dynamic> toJson() => {_lat: lat, _lon: lon};
}

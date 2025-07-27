class ElevationProfileComponent {
  final double? distance;
  final double? elevation;

  const ElevationProfileComponent({this.distance, this.elevation});

  static const String _distance = 'distance';
  static const String _elevation = 'elevation';

  factory ElevationProfileComponent.fromJson(Map<String, dynamic> json) =>
      ElevationProfileComponent(
        distance: json[_distance],
        elevation: json[_elevation],
      );

  Map<String, dynamic> toJson() => {_distance: distance, _elevation: elevation};
}

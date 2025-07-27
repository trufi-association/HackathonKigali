class Geometry {
  final int? length;
  final String? points;

  const Geometry({this.length, this.points});

  static const String _length = 'length';
  static const String _points = 'points';

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      Geometry(length: json[_length], points: json[_points]);

  Map<String, dynamic> toJson() => {_length: length, _points: points};
}

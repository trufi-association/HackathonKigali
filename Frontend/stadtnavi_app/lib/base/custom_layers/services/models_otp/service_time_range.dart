class ServiceTimeRange {
  final int? start;
  final int? end;

  const ServiceTimeRange({
    this.start,
    this.end,
  });

  factory ServiceTimeRange.fromJson(Map<String, dynamic> json) =>
      ServiceTimeRange(
        start: int.tryParse(json['start'].toString()) ?? 0,
        end: int.tryParse(json['end'].toString()) ?? 0,
      );

  // Map<String, dynamic> toJson() => {
  //       'start': start,
  //       'end': end,
  //     };
}

class ReportedBadPrediction {
  /// The snapped position on the route at the time when the user reported the bad prediction (longitude).
  final double snappedPositionOnRouteLng;

  /// The snapped position on the route at the time when the user reported the bad prediction (latitude).
  final double snappedPositionOnRouteLat;

  /// The timestamp of the report.
  final int timestampOfReport;

  /// Whether the user selected the SG or the SG was selected automatically based on the current position on the route.
  final bool sgUserSelected;

  ReportedBadPrediction({
    required this.snappedPositionOnRouteLng,
    required this.snappedPositionOnRouteLat,
    required this.timestampOfReport,
    required this.sgUserSelected,
  });

  Map<String, dynamic> toJson() {
    return {
      'snappedPositionOnRouteLng': snappedPositionOnRouteLng,
      'snappedPositionOnRouteLat': snappedPositionOnRouteLat,
      'timestampOfReport': timestampOfReport,
      'sgUserSelected': sgUserSelected,
    };
  }

  factory ReportedBadPrediction.fromJson(Map<String, dynamic> json) {
    return ReportedBadPrediction(
      snappedPositionOnRouteLng: json['snappedPositionOnRouteLng'],
      snappedPositionOnRouteLat: json['snappedPositionOnRouteLat'],
      timestampOfReport: json['timestampOfReport'],
      sgUserSelected: json['sgUserSelected'],
    );
  }
}

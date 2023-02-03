enum TrackingSubmissionPolicy {
  onlyOnWifi,
  always,
}

extension TrackingPolicyDescription on TrackingSubmissionPolicy {
  String get description {
    switch (this) {
      case TrackingSubmissionPolicy.onlyOnWifi:
        return "Nur über WLAN senden";
      case TrackingSubmissionPolicy.always:
        return "Auch über mobile Daten senden";
    }
  }
}

/// Helper method to format the duration of the track.
String? formatDuration(int? durationSeconds) {
  if (durationSeconds == null) return null;
  if (durationSeconds < 60) {
    // Show only seconds.
    final seconds = durationSeconds.floor();
    return "$seconds s";
  } else if (durationSeconds < 3600) {
    // Show minutes and seconds.
    final minutes = (durationSeconds / 60).floor();
    final seconds = (durationSeconds - (minutes * 60)).floor();
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")} min";
  } else {
    // Show only hours and minutes.
    final hours = (durationSeconds / 3600).floor();
    final minutes = ((durationSeconds - (hours * 3600)) / 60).floor();
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")} h";
  }
}

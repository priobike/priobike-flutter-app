/// A location that is part of a weekly event.
class EventLocation {
  /// Unique id of the location.
  final int id;

  /// Latitude of the location.
  final double lat;

  /// Longitude of the location.
  final double lon;

  /// Title describing the location.
  final String title;

  EventLocation(this.lat, this.lon, this.title, this.id);

  EventLocation.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        lat = json['lat'],
        lon = json['lon'],
        title = json['title'];

  toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'title': title,
      };
}

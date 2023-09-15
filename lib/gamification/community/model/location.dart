class EventLocation {
  final double lat;

  final double lon;

  final String title;

  EventLocation(this.lat, this.lon, this.title);

  EventLocation.fromJson(Map<String, dynamic> json)
      : lat = json['lat'],
        lon = json['lon'],
        title = json['title'];

  toJson() => {
        'lat': lat,
        'lon': lon,
        'title': title,
      };
}

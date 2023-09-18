class EventLocation {
  final int id;

  final double lat;

  final double lon;

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

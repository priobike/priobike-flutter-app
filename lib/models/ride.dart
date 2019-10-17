import 'package:bike_now_flutter/geo_coding/address_to_location_response.dart';

class Ride {
  int id;
  bool isFavorite = false;
  Place start;
  Place end;
  int date;

  Ride(this.start, this.end, this.date, [this.isFavorite]);
}
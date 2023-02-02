/// The zoomToGeographicalDistance map includes all zoom level and maps it to the distance in meter per pixel.
/// Taken from +-60 Latitude since it only needs to be approximate and its closer to 53 than +-40.
/// Its also to small in worst case.
final Map<int, double> zoomToGeographicalDistance = {
  0: 39135.742,
  1: 19567.871,
  2: 9783.936,
  3: 4891.968,
  4: 2445.984,
  5: 1222.992,
  6: 611.496,
  7: 305.748,
  8: 152.874,
  9: 76.437,
  10: 38.218,
  11: 19.109,
  12: 9.555,
  13: 4.777,
  14: 2.389,
  15: 1.194,
  16: 0.597,
  17: 0.299,
  18: 0.149,
  19: 0.075,
  20: 0.047,
  21: 0.019,
  22: 0.009
};

/// Fade a layer out before a specific zoom level.
dynamic showAfter({required int zoom, dynamic opacity = 1.0}) {
  return [
    "interpolate",
    ["linear"],
    ["zoom"],
    0,
    0,
    zoom - 1,
    0,
    zoom,
    opacity,
  ];
}

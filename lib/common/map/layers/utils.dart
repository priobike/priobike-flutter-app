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

/// Fade a layer out before a specific zoom level.
dynamic reduceRadius({required int zoom, dynamic radius = 1.0}) {
  return [
    "interpolate",
    ["linear"],
    ["zoom"],
    0,
    0,
    zoom - 5,
    0,
    zoom,
    radius,
  ];
}

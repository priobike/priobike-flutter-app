
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';
import 'package:priobike/v2/routing/models/route.dart';
import 'package:priobike/v2/routing/models/waypoint.dart';
import 'package:priobike/v2/routing/services/routing.dart';

/// A simple example route.
/// Note that this route was created arbitrarily by hand and contains mock (not actual) information.
/// See: https://www.google.com/maps/dir/53.564789,9.901472/53.5630731,9.9042051/@53.5638537,9.9017505,18z/data=!3m1!4b1!4m2!4m1!3e1
final exampleRoute = Route(
  coordinates: const [
    LatLng(53.564813, 9.901410),
    LatLng(53.564292, 9.902202),
    LatLng(53.563083, 9.904235),
  ], 
  duration: 60, 
  distance: 270,
  trafficLights: const [
    LatLng(53.563983, 9.902759),
  ],
  discomforts: const [
    Discomfort(description: "Dieser Wegabschnitt ist unbefestigt.", coordinates: [
      LatLng(53.563983, 9.902759),
      LatLng(53.563605, 9.903354),
    ]),
    Discomfort(description: "Radweg endet hier, Weiterfahrt auf der Straße. Dies ist ein längerer Text.", coordinates: [
      LatLng(53.564517, 9.901752),
    ]),
  ]
);

/// A simple example alternative route.
/// Note that this route was created arbitrarily by hand and contains mock (not actual) information.
/// See: https://www.google.com/maps/dir/53.564789,9.901472/53.5630731,9.9042051/@53.5638537,9.9017505,18z/data=!3m1!4b1!4m2!4m1!3e1
final exampleAltRoute = Route(
  coordinates: const [
    LatLng(53.564813, 9.901410),
    LatLng(53.564292, 9.902202),
    LatLng(53.564018, 9.902728),
    LatLng(53.563837, 9.900824),
    LatLng(53.563655, 9.900540),
    LatLng(53.563064, 9.900553),
    LatLng(53.562924, 9.900878),
    LatLng(53.562951, 9.902093),
    LatLng(53.562838, 9.903034),
    LatLng(53.563088, 9.904270),
  ], 
  duration: 60, 
  distance: 270,
  trafficLights: const [
    LatLng(53.563983, 9.902759),
  ],
  discomforts: const [
    Discomfort(description: "Dieser Wegabschnitt ist unbefestigt.", coordinates: [
      LatLng(53.563983, 9.902759),
      LatLng(53.563605, 9.903354),
    ]),
    Discomfort(description: "Radweg endet hier, Weiterfahrt auf der Straße. Dies ist ein längerer Text.", coordinates: [
      LatLng(53.564517, 9.901752),
    ]),
  ]
);

class MockRoutingService extends RoutingService {
  MockRoutingService() : super(selectedWaypoints: const [
    Waypoint(53.564813, 9.901410, address: "Friedensallee, 22761 Hamburg"),
    Waypoint(53.563083, 9.904235, address: "Friedensallee 361, 22761 Hamburg, Deutschland"),
  ]);

  @override
  loadRoutes() async {
    // Do nothing if the waypoints were already fetched.
    if (fetchedWaypoints == selectedWaypoints) return;
    selectedRoute = exampleRoute;
    altRoutes = [exampleAltRoute];
    fetchedWaypoints = selectedWaypoints;
    notifyListeners();
  }
}
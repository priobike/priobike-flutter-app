
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/v2/common/models/point.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';
import 'package:priobike/v2/routing/models/navigation.dart';
import 'package:priobike/v2/routing/models/route.dart' as r;
import 'package:priobike/v2/routing/models/sg.dart';
import 'package:priobike/v2/routing/models/waypoint.dart';
import 'package:priobike/v2/routing/services/routing.dart';

/// A simple example route.
/// Note that this route was created arbitrarily by hand and contains mock (not actual) information.
/// See: https://www.google.com/maps/dir/53.564789,9.901472/53.5630731,9.9042051/@53.5638537,9.9017505,18z/data=!3m1!4b1!4m2!4m1!3e1
final exampleRoute = r.Route(
  nodes: const [
    NavigationNode(lon: 9.901410, lat: 53.564813, alt: 0),
    NavigationNode(lon: 9.902202, lat: 53.564813, alt: 0),
    NavigationNode(lon: 9.904235, lat: 53.564813, alt: 0),
  ], 
  ascend: 30,
  descend: 10,
  duration: 60, 
  distance: 270,
  sgs: const [
    Sg(id: 'sg-1', label: 'sg-1', position: Point(lat: 53.563983, lon: 9.902759)),
  ],
  discomforts: const [
    Discomfort(description: "Radweg endet, Weiterfahrt auf der Straße.", coordinates: [
      LatLng(53.564517, 9.901752),
    ]),
    Discomfort(description: "Unbefestigter Abschnitt.", coordinates: [
      LatLng(53.563983, 9.902759),
      LatLng(53.563605, 9.903354),
    ]),
  ]
);

/// A simple example alternative route.
/// Note that this route was created arbitrarily by hand and contains mock (not actual) information.
/// See: https://www.google.com/maps/dir/53.564789,9.901472/53.5630731,9.9042051/@53.5638537,9.9017505,18z/data=!3m1!4b1!4m2!4m1!3e1
final exampleAltRoute = r.Route(
  nodes: const [
    NavigationNode(lon: 9.901410, lat: 53.564813, alt: 0),
    NavigationNode(lon: 53.564292, lat: 9.902202, alt: 0),
    NavigationNode(lon: 53.564018, lat: 9.902728, alt: 0),
    NavigationNode(lon: 53.563837, lat: 9.900824, alt: 0),
    NavigationNode(lon: 53.563655, lat: 9.900540, alt: 0),
    NavigationNode(lon: 53.563064, lat: 9.900553, alt: 0),
    NavigationNode(lon: 53.562924, lat: 9.900878, alt: 0),
    NavigationNode(lon: 53.562951, lat: 9.902093, alt: 0),
    NavigationNode(lon: 53.562838, lat: 9.903034, alt: 0),
    NavigationNode(lon: 53.563088, lat: 9.904270, alt: 0),
  ], 
  duration: 100, 
  ascend: 30,
  descend: 20,
  distance: 400,
  sgs: const [],
  discomforts: const [
    Discomfort(description: "Radweg endet hier, Weiterfahrt auf der Straße.", coordinates: [
      LatLng(53.564517, 9.901752),
    ]),
  ]
);

const exampleWaypoints = [
  Waypoint(53.564813, 9.901410, address: "Friedensallee, 22761 Hamburg"),
  Waypoint(53.563083, 9.904235, address: "Friedensallee 361, 22761 Hamburg, Deutschland"),
];

class MockRoutingService extends RoutingService {
  MockRoutingService() : super(
    selectedWaypoints: exampleWaypoints,
    selectedRoute: exampleRoute,
    altRoutes: [exampleAltRoute],
    fetchedWaypoints: exampleWaypoints,
  );

  @override
  loadRoutes(BuildContext context) async {
    // Do nothing if the waypoints were already fetched.
    if (fetchedWaypoints == selectedWaypoints) return;
    selectedRoute = exampleRoute;
    altRoutes = [exampleAltRoute];
    fetchedWaypoints = selectedWaypoints;
    notifyListeners();
  }
}
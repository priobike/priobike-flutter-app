import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/services/routing_poi.dart';

class POIInfo extends StatefulWidget {
  const POIInfo({super.key});

  @override
  POIInfoState createState() => POIInfoState();
}

class POIInfoState extends State<POIInfo> {
  /// The associated routing service, which is injected by the provider.
  late RoutingPOI routingPOI;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated routing service, which is injected by the provider.
  late Positioning positioning;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routingPOI = getIt<RoutingPOI>();
    routingPOI.addListener(update);
    routing = getIt<Routing>();
    positioning = getIt<Positioning>();
  }

  @override
  void dispose() {
    routingPOI.removeListener(update);
    super.dispose();
  }

  /// The callback that is executed when the button is pressed.
  void onPressed() {
    if (routingPOI.selectedPOI == null) return;
    // Add POI to routing and fetch route.
    final waypoint =
        Waypoint(routingPOI.selectedPOI!.lat, routingPOI.selectedPOI!.lon, address: routingPOI.selectedPOI!.name);
    final waypoints = routing.selectedWaypoints ?? [];

    // Add the own location as a start point to the route, if the waypoint selected in the search is the
    // first waypoint of the route. Thus making it the destination of the route.
    if (waypoints.isEmpty) {
      if (positioning.lastPosition != null) {
        waypoints.add(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
      }
    }
    final newWaypoints = [...waypoints, waypoint];

    routing.selectWaypoints(newWaypoints);
    routing.loadRoutes();
    // Reset selected POI.
    routingPOI.setNeedsResetting();
  }

  @override
  Widget build(BuildContext context) {
    if (routingPOI.selectedPOI == null) return Container();
    final frame = MediaQuery.of(context).size;
    final widgetWidth = frame.width * 0.6;

    return Stack(children: [
      Container(
        // 1 pixel less then the height of the triangle so that the border gets hidden.
        margin: const EdgeInsets.only(top: 15),
        width: widgetWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(width: 1, color: Theme.of(context).colorScheme.onTertiary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Small(
              text: routingPOI.selectedPOI!.typeDescription,
              context: context,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 2,
            ),
            BoldSmall(
              text: routingPOI.selectedPOI!.name,
              context: context,
              textAlign: TextAlign.center,
            ),
            const SmallVSpace(),
            IconTextButtonPrimary(
              label: "Hier hin routen",
              onPressed: onPressed,
              boxConstraints: BoxConstraints(minWidth: frame.width, minHeight: 28.0),
            )
          ],
        ),
      ),
      Positioned(
        // Container width half minus half paint width to center paint.
        left: widgetWidth * 0.5 - 10,
        child: CustomPaint(
          painter: TrianglePainter(
            context: context,
          ),
          child: const SizedBox(
            height: 16,
            width: 20,
          ),
        ),
      ),
    ]);
  }
}

class TrianglePainter extends CustomPainter {
  final BuildContext context;

  TrianglePainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Theme.of(context).colorScheme.background;

    Paint sidePaint = Paint()
      ..color = Theme.of(context).colorScheme.onTertiary
      ..strokeWidth = 1;

    // Draw the background;
    canvas.drawPath(getTrianglePath(size.width, size.height), backgroundPaint);
    // Draw border lines to the top.
    canvas.drawLine(Offset(0, size.height), Offset(size.width / 2, 0), sidePaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width / 2, 0), sidePaint);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..moveTo(0, y)
      ..lineTo(x / 2, 0)
      ..lineTo(x, y)
      ..lineTo(0, y);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return false;
  }
}

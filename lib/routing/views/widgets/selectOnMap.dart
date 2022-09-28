import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/services/mapcontroller.dart';
import 'package:priobike/routing/views/widgets/ZoomInAndOutButton.dart';
import 'package:priobike/routing/views/widgets/compassButton.dart';
import 'package:priobike/routing/views/widgets/gpsButton.dart';
import 'package:provider/provider.dart';

class SelectOnMapView extends StatefulWidget {
  const SelectOnMapView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SelectOnMapViewState();
}

class SelectOnMapViewState extends State<SelectOnMapView> {
  /// The associated routingOLD service, which is injected by the provider.
  late Routing routingService;

  /// The associated shortcuts service, which is injected by the provider.
  late MapController mapControllerService;

  /// The associated geosearch service, which is injected by the provider.
  late Geosearch geosearch;

  /// The stream that receives notifications when the bottom sheet is dragged.
  final sheetMovement = StreamController<DraggableScrollableNotification>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await routingService.loadRoutes(context);
    });
  }

  @override
  void didChangeDependencies() {
    routingService = Provider.of<Routing>(context);
    mapControllerService = Provider.of<MapController>(context);
    geosearch = Provider.of<Geosearch>(context);

    super.didChangeDependencies();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Tile(
          fill: Theme.of(context).colorScheme.background,
          content: Center(
            child: SizedBox(
              height: 86,
              width: 256,
              child: Column(children: [
                const CircularProgressIndicator(),
                const VSpace(),
                BoldContent(text: "Lade...", maxLines: 1, context: context),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Private ZoomIn Function which calls mapControllerService
  void _zoomIn() {
    mapControllerService.zoomIn();
  }

  /// Private ZoomOut Function which calls mapControllerService
  void _zoomOut() {
    mapControllerService.zoomOut();
  }

  /// Private GPS Centralization Function which calls mapControllerService
  void _gpsCentralization() {
    mapControllerService.setMyLocationTrackingModeTracking();
  }

  /// Private Center North Function which calls mapControllerService
  void _centerNorth() {
    mapControllerService.centerNorth();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            width: frame.size.width,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: 'appBackButton',
                        child: AppBackButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: () => Navigator.pop(context),
                            elevation: 5),
                      ),
                      const SizedBox(width: 16),
                      Center(
                        child: SubHeader(
                            text: "Standort auf Karte wählen",
                            context: context),
                      ),
                      const SizedBox(width: 5),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          primary: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          print("close select view and overgive location");
                          print(mapControllerService.getCameraPosition());
                        },
                        child: Content(text: "Fertig", context: context, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                    ]),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RoutingMapView(sheetMovement: sheetMovement.stream),
                if (routingService.isFetchingRoute) renderLoadingIndicator(),
                Padding(
                  /// Align with FAB
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CompassButton(centerNorth: _centerNorth),
                        ZoomInAndOutButton(zoomIn: _zoomIn, zoomOut: _zoomOut),
                      ]),
                ),
                Center(
                  child: Icon(Icons.location_on, size: 34, color: Theme.of(context).colorScheme.primary,),
                ),
              ],
            ),
          ),
        ]),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GPSButton(
                myLocationTrackingMode:
                    mapControllerService.myLocationTrackingMode,
                gpsCentralization: _gpsCentralization),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  @override
  void dispose() {
    sheetMovement.close();
    super.dispose();
  }
}

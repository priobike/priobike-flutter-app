import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:provider/provider.dart';

class RoutingView extends StatefulWidget {
  const RoutingView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingViewState();
}

class RoutingViewState extends State<RoutingView> {
  /// The associated routing service, which is injected by the provider.
  RoutingService? s;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await s?.loadRoutes(context);
    });
  }

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  void onStartRide() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      // Avoid navigation back, only allow stop button to be pressed.
      // Note: Don't use pushReplacement since this will call
      // the result handler of the RouteView's host.
      return WillPopScope(
        onWillPop: () async => false,
        child: const RideView(),
      );
    }));
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Tile(
        content: Center(child: SizedBox(
          height: 86, 
          width: 256, 
          child: Column(children: [
            const CircularProgressIndicator(),
            const VSpace(),
            BoldContent(text: "Lade Route...", maxLines: 1),
          ])
        ))
      )),
    ]);
  }

  /// Render a try again button.
  Widget renderTryAgainButton() {
    return SafeArea(child: Pad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Tile(
        content: Center(child: SizedBox(
          height: 128, 
          width: 256, 
          child: Column(children: [
            BoldContent(text: "Fehler beim Laden der Route.", maxLines: 1),
            const VSpace(),
            BigButton(label: "Erneut Laden", onPressed: () async {
              await s?.loadRoutes(context);
            }),
          ])
        ))
      )),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    if (s!.hadErrorDuringFetch) return renderTryAgainButton();
  
    final frame = MediaQuery.of(context);

    return Scaffold(body: Stack(children: [
      const RoutingMapView(),

      if (s!.isFetchingRoute) renderLoadingIndicator(),
      
      // Top Bar
      SafeArea(
        minimum: const EdgeInsets.only(top: 64),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 16),
          SizedBox( // Avoid expansion of alerts view.
            width: frame.size.width - 80, 
            child: const AlertsView(),
          )
        ]),
      ),

      RouteDetailsBottomSheet(onSelectStartButton: onStartRide),
    ]));
  }
}

import 'package:flutter/material.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
import 'package:priobike/session/services/session.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:provider/provider.dart';

/// Debug these views.
void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<RoutingService>(
      create: (context) => MockRoutingService(),
    ),
  ],
  child: const RoutingView(),
));

class RoutingView extends StatefulWidget {
  const RoutingView({Key? key}) : super(key: key);

  /// Create the view with necessary providers from the app view hierarchy.
  static Widget withinAppHierarchy(BuildContext context) {
    // Fetch the necessary view models from the build context.
    final ss = Provider.of<ShortcutsService>(context, listen: false);

    return Scaffold(body: MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionService>(create: (c) => SessionService()),
        ChangeNotifierProvider<RoutingService>(create: (c) => RoutingService(
          selectedWaypoints: ss.selectedShortcut?.waypoints
        )),
      ],
      child: const RoutingView(),
    ));
  }

  @override
  State<StatefulWidget> createState() => RoutingViewState();
}

class RoutingViewState extends State<RoutingView> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService s;

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);

    // Load the routes, once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      s.loadRoutes(context);
    });

    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  void onStartRide() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return RideView.withinAppHierarchy(context);
    }));
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Stack(children: [
      const RoutingMapView(),
      
      // Top Bar
      SafeArea(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppBackButton(icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 16),
          SizedBox( // Avoid expansion of alerts view.
            width: frame.size.width - 80, 
            child: AlertsView(discomforts: s.selectedRoute?.discomforts),
          )
        ]),
      ),

      RouteDetailsBottomSheet(onSelectStartButton: onStartRide),
    ]);
  }
}

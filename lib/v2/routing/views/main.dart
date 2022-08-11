
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/layout/buttons.dart';
import 'package:priobike/v2/routing/services/mock.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:priobike/v2/routing/views/alerts.dart';
import 'package:priobike/v2/routing/views/map.dart';
import 'package:priobike/v2/routing/views/sheet.dart';
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

      const RouteDetailsBottomSheet(),
    ]);
  }
}

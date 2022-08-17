import 'package:flutter/material.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/mock.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/alerts.dart';
import 'package:priobike/routing/views/map.dart';
import 'package:priobike/routing/views/sheet.dart';
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

  /// A callback that is fired when the ride is started.
  void onStartRide() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) {
      return const Scaffold(body: RideView());
    }));
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return SafeArea(child: Pad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ])));
  }

  @override
  Widget build(BuildContext context) {
    if (s.isFetchingRoute) return renderLoadingIndicator();
  
    final frame = MediaQuery.of(context);

    return Stack(children: [
      const RoutingMapView(),
      
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
    ]);
  }
}

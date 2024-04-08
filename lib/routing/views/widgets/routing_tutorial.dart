import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/map_legend.dart';
import 'package:priobike/tutorial/service.dart';

/// The routing tutorial view that is shown when first creating a route.
class RoutingTutorialView extends StatefulWidget {
  const RoutingTutorialView({super.key});

  @override
  State<StatefulWidget> createState() => RoutingTutorialViewState();
}

class RoutingTutorialViewState extends State<RoutingTutorialView> {
  /// The associated Tutorial service, which is injected by the provider.
  late Tutorial tutorial;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The begin opacity of the icon.
  double beginOpacity = 0.5;

  /// The end opacity of the icon.
  double endOpacity = 1.0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    tutorial = getIt<Tutorial>();
    tutorial.addListener(update);

    routing = getIt<Routing>();
    routing.addListener(update);
  }

  @override
  void dispose() {
    tutorial.removeListener(update);
    routing.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedRoute == null) return Container();
    // TODO check this with fresh app.
    if (tutorial.isCompleted("priobike.tutorial.routing.info") == null) return Container();
    if (tutorial.isCompleted("priobike.tutorial.routing.info")!) return Container();

    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withOpacity(0.33),
      child: const Stack(
        children: [
          // Side Bar right
          Positioned(
            right: 8,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: MapLegend(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

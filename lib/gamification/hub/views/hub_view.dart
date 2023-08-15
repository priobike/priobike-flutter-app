import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/hub/services/game_service.dart';
import 'package:priobike/gamification/hub/views/hub_element.dart';
import 'package:priobike/gamification/hub/views/total.dart';
import 'package:priobike/main.dart';

class GamificationHubView extends StatefulWidget {
  const GamificationHubView({
    Key? key,
  }) : super(key: key);

  @override
  GamificationHubViewState createState() => GamificationHubViewState();
}

class GamificationHubViewState extends State<GamificationHubView> with TickerProviderStateMixin {
  late GameService _gameService;

  final List<AnimationController> _openAnimationControllers = [];

  List<RideSummary> rides = [];

  RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  Map<String, Widget> get mappedHubElements => {
        GameService.prefsRideSummariesKey: generateRideList(),
      };

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  void _createAndStartAnimationControllers() async {
    for (int i = 0; i < 3; i++) {
      var controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _openAnimationControllers.add(controller);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    for (int i = 0; i < _openAnimationControllers.length; i++) {
      var controller = _openAnimationControllers[i];
      if (i > 1) {
        var prevController = _openAnimationControllers[i - 1];
        prevController.addListener(() {
          if (prevController.value > 0.5) controller.forward();
        });
      } else {
        controller.forward();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _gameService.addListener(update);
    _createAndStartAnimationControllers();
    rideDao.streamAllObjects().listen((update) {
      setState(() {
        rides = update;
      });
    });
  }

  @override
  void dispose() {
    _gameService.removeListener(update);
    for (var controller in _openAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),
                        const HSpace(),
                        Expanded(
                          child: FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _openAnimationControllers.first,
                              curve: Curves.easeIn,
                            ),
                            child: SubHeader(text: "Spiel", context: context),
                          ),
                        ),
                      ],
                    ),
                    GamificationHubElement(
                      controller: _openAnimationControllers[1],
                      content: TotalStatisticsView(),
                    ),
                  ] +
                  _gameService.userPrefs
                      .map(
                        (key) => GamificationHubElement(
                          controller: _openAnimationControllers[_gameService.userPrefs.indexOf(key) + 2],
                          content: mappedHubElements[key]!,
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget generateRideList() {
    return Column(
      children: rides
          .map(
            (ride) => Container(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onDoubleTap: () {
                  rideDao.deleteObject(ride);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("id: ${ride.id},"),
                    Text("dis: ${ride.distanceMetres.toInt()},"),
                    Text("dur: ${ride.durationSeconds.toInt()},"),
                    Text("avg: ${ride.averageSpeedKmh.toInt()},"),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

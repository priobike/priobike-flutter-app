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

/// This view is the center point of the gamification functionality. It provides the user with all the information about
/// their profile, their progress, and all the game components.
class GamificationHubView extends StatefulWidget {
  const GamificationHubView({
    Key? key,
  }) : super(key: key);

  @override
  GamificationHubViewState createState() => GamificationHubViewState();
}

class GamificationHubViewState extends State<GamificationHubView> with TickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late UserProfileService _profileService;

  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  /// List of controllers which control the animation whith which the displayed widgets appear after opening the view.
  final List<AnimationController> _openAnimationControllers = [];

  /// A map which maps the keys of possible gamification components to corresponding views.
  /// This map is needed to decide which views to display to the user.
  Map<String, Widget> get mappedHubElements => {
        UserProfileService.prefsRideSummariesKey: generateRideList(),
      };

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    _profileService = getIt<UserProfileService>();
    _profileService.addListener(update);
    _createAndStartAnimationControllers();
    rideDao.streamAllObjects().listen((update) {
      setState(() {
        rides = update;
      });
    });
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    for (var controller in _openAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// This function initializes the required number of animation controllers and starts them one by one in specified
  /// intervals to create a smooth opening animation.
  void _createAndStartAnimationControllers() async {
    /// Create for each component which the user activated one controller, plus a controller for the profile card
    /// and a controller for the header at the top.
    for (int i = 0; i < _profileService.userPrefs.length + 2; i++) {
      var controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _openAnimationControllers.add(controller);
    }

    /// Start animation with a short delay to make it smoother.
    await Future.delayed(const Duration(milliseconds: 400));

    /// Start the animations one by one to create the smooth look.
    for (int i = 0; i < _openAnimationControllers.length; i++) {
      var controller = _openAnimationControllers[i];
      if (i > 1) {
        /// Start animating a widget, when the animation of the previous widget in the list is halfway finished.
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
                  _profileService.userPrefs
                      .map(
                        (key) => GamificationHubElement(
                          controller: _openAnimationControllers[_profileService.userPrefs.indexOf(key) + 2],
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

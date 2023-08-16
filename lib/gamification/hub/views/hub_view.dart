import 'package:collection/collection.dart';
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

class GamificationHubViewState extends State<GamificationHubView> with SingleTickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late UserProfileService _profileService;

  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  /// A map which maps the keys of possible gamification components to corresponding views.
  /// This map is needed to decide which views to display to the user.
  Map<String, Widget> get mappedHubElements => {
        UserProfileService.prefsRideSummariesKey: generateRideList(),
      };

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      );

  @override
  void initState() {
    super.initState();
    _profileService = getIt<UserProfileService>();
    _profileService.addListener(update);
    // Init animation controller and start the animation after a short delay, to let the view load first.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(const Duration(milliseconds: 200)).then(
      (value) => _animationController.forward(),
    );
    //_createAndStartAnimationControllers();
    rideDao.streamAllObjects().listen((update) {
      setState(() {
        rides = update;
      });
    });
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    _animationController.dispose();
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
                        AppBackButton(
                          onPressed: () {
                            _animationController.duration = const Duration(milliseconds: 500);
                            _animationController.reverse().then((value) => Navigator.pop(context));
                          },
                        ),
                        const HSpace(),
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SubHeader(
                              text: "PrioBike Challenge",
                              context: context,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const HSpace(),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SmallIconButton(
                              icon: Icons.settings,
                              onPressed: () {
                                _animationController.duration = const Duration(milliseconds: 500);
                                _animationController.reverse();
                                // TODO: Navigator.push(SETTINGS)
                              },
                              fill: Theme.of(context).colorScheme.background,
                              splash: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GamificationHubElement(
                      start: 0,
                      end: 0.4,
                      controller: _animationController,
                      content: TotalStatisticsView(),
                    ),
                  ] +
                  // Create a hub element for each game component the user has selected in their prefs.
                  _profileService.userPrefs
                      .mapIndexed(
                        (i, key) => GamificationHubElement(
                          start: 0.2 + (i * 0.2),
                          end: 0.6 + (i * 0.2),
                          controller: _animationController,
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

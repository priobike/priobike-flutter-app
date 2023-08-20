import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/ride_summary/ride_summary.dart';
import 'package:priobike/gamification/hub/services/profile_service.dart';
import 'package:priobike/gamification/hub/views/animation_wrapper.dart';
import 'package:priobike/gamification/hub/views/cards/stats_card.dart';
import 'package:priobike/gamification/hub/views/cards/user_profile.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/gamification/settings/views/settings_view.dart';
import 'package:priobike/main.dart';

/// This view is the center point of the gamification functionality. It provides the user with all the information about
/// their profile, their progress, and all the game components.
class GameHubView extends StatefulWidget {
  const GameHubView({
    Key? key,
  }) : super(key: key);

  @override
  GameHubViewState createState() => GameHubViewState();
}

class GameHubViewState extends State<GameHubView> with SingleTickerProviderStateMixin {
  /// The service which manages and provides the user profile.
  late GameProfileService _profileService;

  late GameSettingsService _settingsService;

  /// Ride DAO required to load the rides from the db.
  final RideSummaryDao rideDao = AppDatabase.instance.rideSummaryDao;

  /// Loaded rides in a list.
  List<RideSummary> rides = [];

  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  /// A map which maps the keys of possible gamification components to corresponding views.
  /// This map is needed to decide which views to display to the user.
  Map<String, Widget> get mappedHubElements => {
        GameSettingsService.gameFeatureStatisticsKey: RideStatisticsCard(openView: openPage),
      };

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    super.initState();
    _settingsService = getIt<GameSettingsService>();
    _settingsService.addListener(update);

    /// Listen to changes in the user profile.
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    // Init animation controller and start the animation after a short delay, to let the view load first.
    _animationController = AnimationController(
      vsync: this,
      duration: LongTransitionDuration(),
    );
    Future.delayed(ShortTransitionDuration()).then(
      (value) => _animationController.forward(),
    );
    // Listen to ride data and update local list accordingly.
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

  /// This function navigates to a new page by pushing it on top of the hub view. It also handles the transition
  /// animation of the hub view, both when opening the page and when returning to the hub.
  Future openPage(Widget view) {
    _animationController.duration = ShortTransitionDuration();
    return _animationController
        .reverse()
        .then(
          (value) => Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) => view,
            ),
          ),
        )
        .then(
          (value) => Future.delayed(
            const Duration(milliseconds: 300),
          ).then(
            (value) => _animationController.forward(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GameHubPage(
      animationController: _animationController,
      title: 'PrioBike Challenge',
      featureButtonIcon: Icons.settings,
      featureButtonCallback: () => openPage(const GameSettingsView()),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
              GameHubAnimationWrapper(
                start: 0,
                end: 0.4,
                controller: _animationController,
                child: UserProfileCard(),
              ),
            ] +
            // Create a hub element for each game feature the user has enabled.
            _settingsService.enabledFeatures
                .mapIndexed(
                  (i, key) => GameHubAnimationWrapper(
                    start: 0.2 + (i * 0.2),
                    end: 0.6 + (i * 0.2),
                    controller: _animationController,
                    child: mappedHubElements[key]!,
                  ),
                )
                .toList() +
            [const SmallVSpace()],
      ),
    );
  }
}

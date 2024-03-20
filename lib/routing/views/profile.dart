import 'package:flutter/material.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/routing/services/routing.dart';

class ProfileSelectionSheet extends StatefulWidget {
  final Color onPrimary;

  final Color onBackground;

  const ProfileSelectionSheet({super.key, required this.onPrimary, required this.onBackground});

  @override
  ProfileSelectionSheetState createState() => ProfileSelectionSheetState();
}

class ProfileSelectionSheetState extends State<ProfileSelectionSheet> {
  /// The associated profile service, which is injected by the provider.
  late Profile profileService;

  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  /// The loading state of the images.
  final List<bool> imageLoadingState = List.empty(growable: true);

  /// The images of the bike types.
  final List<Image> bikeTypeImages = List.empty(growable: true);

  /// The future of the image precaching.
  List<Future<void>> imagePrecaching = List.empty(growable: true);

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    profileService = getIt<Profile>();
    profileService.addListener(update);
    routingService = getIt<Routing>();

    for (var index = 0; index < BikeType.values.length; index++) {
      bikeTypeImages.add(Image.asset(
        BikeType.values[index].iconAsString(),
        color: BikeType.values[index] == profileService.bikeType ? widget.onPrimary : widget.onBackground,
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    for (var index = 0; index < bikeTypeImages.length; index++) {
      imageLoadingState.add(false);
      precacheImage(bikeTypeImages[index].image, context).then((_) {
        imageLoadingState[index] = true;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    profileService.removeListener(update);
    for (final future in imagePrecaching) {
      future.ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 64),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
              child: BoldContent(
                text: "Fahrradtyp auswählen",
                context: context,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
              child: Small(
                text: "Dein gewählter Fahrradtyp beeinflusst das Routing. Starke Anstiege werden immer vermieden.",
                context: context,
              ),
            ),
            for (var index = 0; index < BikeType.values.length; index++)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Tile(
                  fill: BikeType.values[index] == profileService.bikeType
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  onPressed: () {
                    final newBikeType = BikeType.values[index];
                    profileService.bikeType = newBikeType;
                    profileService.store();
                    routingService.loadRoutes();
                    // Close the modal.
                    Navigator.of(context).pop();
                  },
                  content: Row(
                    children: [
                      Flexible(
                        fit: FlexFit.tight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldContent(
                              text: BikeType.values[index].description(),
                              context: context,
                              color: BikeType.values[index] == profileService.bikeType
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onBackground,
                            ),
                            const SizedBox(height: 2),
                            Small(
                              text: BikeType.values[index].explanation,
                              context: context,
                              color: BikeType.values[index] == profileService.bikeType
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onBackground,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: bikeTypeImages[index],
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class ProfileButton extends StatefulWidget {
  const ProfileButton({super.key});

  @override
  ProfileButtonState createState() => ProfileButtonState();
}

class ProfileButtonState extends State<ProfileButton> {
  /// The associated profile service, which is injected by the provider.
  late Profile profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    profileService = getIt<Profile>();
    profileService.addListener(update);
  }

  @override
  void dispose() {
    profileService.removeListener(update);
    super.dispose();
  }

  void showSelectionDialog() {
    showAppSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ProfileSelectionSheet(
          onPrimary: Theme.of(context).colorScheme.onPrimary,
          onBackground: Theme.of(context).colorScheme.onBackground,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Tile(
        fill: Theme.of(context).colorScheme.surfaceVariant,
        onPressed: showSelectionDialog,
        content: Image(
          image: AssetImage(profileService.bikeType.iconAsString()),
          color: Theme.of(context).colorScheme.onBackground,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        ),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return const HPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tile(
            content: Center(
              child: SizedBox(
                height: 86,
                width: 86,
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

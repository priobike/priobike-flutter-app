import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';

class ProfileElementButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final Color? backgroundColor;
  final Color? touchColor;
  final void Function()? onPressed;

  const ProfileElementButton({
    Key? key,
    required this.icon,
    required this.title,
    this.color,
    this.backgroundColor,
    this.touchColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tile(
          fill: backgroundColor ?? theme.colorScheme.background,
          splash: touchColor ?? CI.blue,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          padding: const EdgeInsets.all(8),
          showShadow: false,
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: constraints.maxWidth * 0.4, color: color ?? theme.colorScheme.onBackground),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Small(
                        text: title,
                        color: color ?? theme.colorScheme.onBackground,
                        context: context,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onPressed: onPressed,
        );
      },
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  /// The associated profile service, which is injected by the provider.
  late Profile profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  bool bikeSelectionActive = false;
  bool preferenceSelectionActive = false;
  bool activitySelectionActive = false;

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

  void toggleBikeSelection() {
    // Tell the tutorial that the user has seen a profile selection.
    getIt<Tutorial>().complete("priobike.tutorial.configure-profile");

    setState(
      () {
        bikeSelectionActive = !bikeSelectionActive;
        preferenceSelectionActive = false;
        activitySelectionActive = false;
      },
    );
  }

  void togglePreferenceSelection() {
    // Tell the tutorial that the user has seen a profile selection.
    getIt<Tutorial>().complete("priobike.tutorial.configure-profile");

    setState(
      () {
        bikeSelectionActive = false;
        preferenceSelectionActive = !preferenceSelectionActive;
        activitySelectionActive = false;
      },
    );
  }

  void toggleActivitySelection() {
    // Tell the tutorial that the user has seen a profile selection.
    getIt<Tutorial>().complete("priobike.tutorial.configure-profile");

    setState(
      () {
        bikeSelectionActive = false;
        preferenceSelectionActive = false;
        activitySelectionActive = !activitySelectionActive;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!profileService.hasLoaded) renderLoadingIndicator();
    return renderProfileSelection();
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

  Widget renderProfileSelection() {
    return HPad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TutorialView(
            id: "priobike.tutorial.configure-profile",
            text:
                'Unten kannst du dein Profil konfigurieren. Diese Informationen werden für die Berechnung der Route verwendet. Du kannst sie jederzeit ändern.',
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
          Tile(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            fill: Theme.of(context).colorScheme.background,
            content: Column(
              children: [
                const SizedBox(height: 16),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  crossAxisSpacing: 8,
                  crossAxisCount: 3,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: profileService.bikeType == null
                          ? ProfileElementButton(
                              key: const ValueKey<String>("None"),
                              icon: Icons.electric_bike_rounded,
                              title: "Radtyp",
                              color: Theme.of(context).colorScheme.onBackground,
                              backgroundColor: Theme.of(context).colorScheme.background,
                              onPressed: toggleBikeSelection)
                          : ProfileElementButton(
                              key: ValueKey<String>(profileService.bikeType!.description()),
                              icon: profileService.bikeType!.icon(),
                              title: profileService.bikeType!.description(),
                              color: Colors.white,
                              backgroundColor: CI.blue,
                              touchColor: Colors.white,
                              onPressed: toggleBikeSelection,
                            ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: profileService.preferenceType == null
                          ? ProfileElementButton(
                              key: const ValueKey<String>("None"),
                              icon: Icons.thumbs_up_down_rounded,
                              title: "Präferenz",
                              color: Theme.of(context).colorScheme.onBackground,
                              backgroundColor: Theme.of(context).colorScheme.background,
                              onPressed: togglePreferenceSelection,
                            )
                          : ProfileElementButton(
                              key: ValueKey<String>(profileService.preferenceType!.description()),
                              icon: profileService.preferenceType!.icon(),
                              title: profileService.preferenceType!.description(),
                              color: Colors.white,
                              backgroundColor: CI.blue,
                              touchColor: Colors.white,
                              onPressed: togglePreferenceSelection,
                            ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: profileService.activityType == null
                          ? ProfileElementButton(
                              key: const ValueKey<String>("None"),
                              icon: Icons.landscape,
                              title: "Anstieg",
                              color: Theme.of(context).colorScheme.onBackground,
                              backgroundColor: Theme.of(context).colorScheme.background,
                              onPressed: toggleActivitySelection,
                            )
                          : ProfileElementButton(
                              key: ValueKey<String>(profileService.activityType!.description()),
                              icon: profileService.activityType!.icon(),
                              title: profileService.activityType!.description(),
                              color: Colors.white,
                              backgroundColor: CI.blue,
                              touchColor: Colors.white,
                              onPressed: toggleActivitySelection,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedCrossFade(
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 1000),
                  firstChild: Container(),
                  secondChild: renderBikeTypeSelection(),
                  crossFadeState: bikeSelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                ),
                AnimatedCrossFade(
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 1000),
                  firstChild: Container(),
                  secondChild: renderPreferenceTypeSelection(),
                  crossFadeState: preferenceSelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                ),
                AnimatedCrossFade(
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  sizeCurve: Curves.easeInOutCubic,
                  duration: const Duration(milliseconds: 1000),
                  firstChild: Container(),
                  secondChild: renderActivityTypeSelection(),
                  crossFadeState: activitySelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget renderBikeTypeSelection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Content(text: "Radtyp", context: context),
                  const SmallVSpace(),
                  Small(
                      text: "Dein Rad ist so individuell wie du. Wähle den Radtyp, der am besten zu deinem Rad passt.",
                      context: context),
                ],
              ),
            ),
            SmallIconButton(
              icon: Icons.expand_less_rounded,
              onPressed: () {
                toggleBikeSelection();
              },
            )
          ],
        ),
        const VSpace(),
        GridView.count(
          shrinkWrap: true,
          crossAxisSpacing: 8,
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: BikeType.values
                  .map(
                    (bikeType) => ProfileElementButton(
                      icon: bikeType.icon(),
                      title: bikeType.description(),
                      color: Colors.white,
                      backgroundColor: CI.blue,
                      touchColor: Colors.white,
                      onPressed: () {
                        profileService.bikeType = bikeType;
                        profileService.store();
                        toggleBikeSelection();
                      },
                    ),
                  )
                  .toList() +
              [
                ProfileElementButton(
                  icon: Icons.delete_rounded,
                  title: "Löschen",
                  color: Theme.of(context).colorScheme.onBackground,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  touchColor: Theme.of(context).colorScheme.onBackground,
                  onPressed: () {
                    profileService.bikeType = null;
                    profileService.store();
                    toggleBikeSelection();
                  },
                )
              ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget renderPreferenceTypeSelection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Content(text: "Routenpräferenz", context: context),
                  const SmallVSpace(),
                  Small(
                      text: "Wir werden dir Routen vorschlagen, die deinen Präferenzen entsprechen.", context: context),
                ],
              ),
            ),
            const SmallHSpace(),
            SmallIconButton(
              icon: Icons.expand_less_rounded,
              onPressed: () {
                togglePreferenceSelection();
              },
            ),
          ],
        ),
        const VSpace(),
        GridView.count(
          shrinkWrap: true,
          crossAxisSpacing: 8,
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: PreferenceType.values
                  .map(
                    (preferenceType) => ProfileElementButton(
                      icon: preferenceType.icon(),
                      title: preferenceType.description(),
                      color: Colors.white,
                      backgroundColor: CI.blue,
                      touchColor: Colors.white,
                      onPressed: () {
                        profileService.preferenceType = preferenceType;
                        profileService.store();
                        togglePreferenceSelection();
                      },
                    ),
                  )
                  .toList() +
              [
                ProfileElementButton(
                  icon: Icons.delete_rounded,
                  title: "Löschen",
                  color: Theme.of(context).colorScheme.onBackground,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  touchColor: Theme.of(context).colorScheme.onBackground,
                  onPressed: () {
                    profileService.preferenceType = null;
                    profileService.store();
                    togglePreferenceSelection();
                  },
                )
              ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget renderActivityTypeSelection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Content(text: "Anstieg", context: context),
                  const SmallVSpace(),
                  Small(
                      text:
                          "Vermeide Anstiege oder fahre lieber bergauf? Wähle die Option, die am besten zu dir passt.",
                      context: context),
                ],
              ),
            ),
            const SmallHSpace(),
            SmallIconButton(
              icon: Icons.expand_less_rounded,
              onPressed: () {
                toggleActivitySelection();
              },
            )
          ],
        ),
        const VSpace(),
        GridView.count(
          shrinkWrap: true,
          crossAxisSpacing: 8,
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: ActivityType.values
                  .map(
                    (activityType) => ProfileElementButton(
                      icon: activityType.icon(),
                      title: activityType.description(),
                      color: Colors.white,
                      backgroundColor: CI.blue,
                      touchColor: Colors.white,
                      onPressed: () {
                        profileService.activityType = activityType;
                        profileService.store();
                        toggleActivitySelection();
                      },
                    ),
                  )
                  .toList() +
              [
                ProfileElementButton(
                  icon: Icons.delete_rounded,
                  title: "Löschen",
                  color: Theme.of(context).colorScheme.onBackground,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  touchColor: Theme.of(context).colorScheme.onBackground,
                  onPressed: () {
                    profileService.activityType = null;
                    profileService.store();
                    toggleActivitySelection();
                  },
                )
              ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

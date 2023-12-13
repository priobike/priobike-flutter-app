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
  final IconData? icon;
  final String? iconAsString;
  final String title;
  final Color? color;
  final Color? borderColor;
  final Color? backgroundColor;
  final void Function()? onPressed;

  const ProfileElementButton({
    super.key,
    this.icon,
    this.iconAsString,
    required this.title,
    this.color,
    this.borderColor,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tile(
          fill: backgroundColor ?? theme.colorScheme.background,
          splash: theme.colorScheme.surfaceTint,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          padding: const EdgeInsets.all(8),
          borderColor: borderColor,
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
                    if (icon != null)
                      Icon(icon, size: constraints.maxWidth * 0.4, color: color ?? theme.colorScheme.onBackground),
                    if (iconAsString != null)
                      SizedBox(
                        width: constraints.maxWidth * 0.4,
                        child: Image.asset(iconAsString!, color: color),
                      ),
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
  const ProfileView({super.key});

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
      child: Tile(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        fill: Theme.of(context).colorScheme.background,
        borderColor: Colors.grey.withOpacity(0.2),
        content: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoldSubHeader(
                      text: "Routing-Profil",
                      context: context,
                    ),
                    const SizedBox(height: 4),
                    Content(
                      text: "Personalisiere Deine Routenberechnung",
                      context: context,
                      maxLines: 2,
                    ),
                  ],
                ),
              ],
            ),
            const SmallVSpace(),
            const TutorialView(
              id: "priobike.tutorial.configure-profile",
              text:
                  'Hier kannst Du Dein Profil konfigurieren. Diese Informationen werden für die Berechnung der Route verwendet. Du kannst sie jederzeit ändern.',
              padding: EdgeInsets.fromLTRB(6, 0, 16, 6),
            ),
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
                          // icon: Icons.electric_bike_rounded,
                          iconAsString: "assets/icons/fahrrad.png",
                          title: "Radtyp",
                          color: bikeSelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          borderColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              bikeSelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
                          onPressed: toggleBikeSelection)
                      : ProfileElementButton(
                          key: ValueKey<String>(profileService.bikeType!.description()),
                          icon: profileService.bikeType!.icon(),
                          iconAsString: profileService.bikeType!.iconAsString(),
                          title: profileService.bikeType!.description(),
                          color: bikeSelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          borderColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              bikeSelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
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
                          color: preferenceSelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          borderColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              preferenceSelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
                          onPressed: togglePreferenceSelection,
                        )
                      : ProfileElementButton(
                          key: ValueKey<String>(profileService.preferenceType!.description()),
                          icon: profileService.preferenceType!.icon(),
                          title: profileService.preferenceType!.description(),
                          color: preferenceSelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          borderColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              preferenceSelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
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
                          color: activitySelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          borderColor: Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              activitySelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
                          onPressed: toggleActivitySelection,
                        )
                      : ProfileElementButton(
                          key: ValueKey<String>(profileService.activityType!.description()),
                          icon: profileService.activityType!.icon(),
                          title: profileService.activityType!.description(),
                          borderColor: Theme.of(context).colorScheme.primary,
                          color: activitySelectionActive ? Colors.white : Theme.of(context).colorScheme.primary,
                          backgroundColor:
                              activitySelectionActive ? CI.radkulturRed : Theme.of(context).colorScheme.background,
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
                  Content(text: "Radtyp", context: context, color: Theme.of(context).colorScheme.onBackground),
                  const SmallVSpace(),
                  Small(
                      text: "Dein Rad ist so individuell wie Du. Wähle den Radtyp, der am besten zu Deinem Rad passt.",
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground),
                ],
              ),
            ),
            SmallIconButtonTertiary(
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
                      iconAsString: bikeType.iconAsString(),
                      title: bikeType.description(),
                      color: Theme.of(context).colorScheme.tertiary,
                      backgroundColor: profileService.bikeType == bikeType
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.background,
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
                  icon: Icons.cancel_outlined,
                  title: "Auswahl entfernen",
                  color: Theme.of(context).colorScheme.tertiary,
                  backgroundColor: Theme.of(context).colorScheme.background,
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
                  Content(text: "Routenpräferenz", context: context, color: Theme.of(context).colorScheme.onBackground),
                  const SmallVSpace(),
                  Small(
                      text: "Wir werden Dir Routen vorschlagen, die Deinen Präferenzen entsprechen.",
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground),
                ],
              ),
            ),
            const SmallHSpace(),
            SmallIconButtonTertiary(
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
                      color: Theme.of(context).colorScheme.tertiary,
                      backgroundColor: profileService.preferenceType == preferenceType
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.background,
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
                  icon: Icons.cancel_outlined,
                  title: "Auswahl entfernen",
                  color: Theme.of(context).colorScheme.tertiary,
                  backgroundColor: Theme.of(context).colorScheme.background,
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
                  Content(text: "Anstieg", context: context, color: Theme.of(context).colorScheme.onBackground),
                  const SmallVSpace(),
                  Small(
                      text:
                          "Vermeide Anstiege oder fahre lieber bergauf? Wähle die Option, die am besten zu Dir passt.",
                      context: context,
                      color: Theme.of(context).colorScheme.onBackground),
                ],
              ),
            ),
            const SmallHSpace(),
            SmallIconButtonTertiary(
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
                      color: Theme.of(context).colorScheme.tertiary,
                      backgroundColor: profileService.activityType == activityType
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.background,
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
                  icon: Icons.cancel_outlined,
                  title: "Auswahl entfernen",
                  color: Theme.of(context).colorScheme.tertiary,
                  backgroundColor: Theme.of(context).colorScheme.background,
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

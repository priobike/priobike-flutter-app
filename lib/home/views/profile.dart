import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:provider/provider.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      return Tile(
        fill: backgroundColor ?? theme.colorScheme.background,
        splash: touchColor ?? theme.colorScheme.primary,
        padding: const EdgeInsets.all(8),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  size: constraints.maxWidth * 0.4, 
                  color: color ?? theme.colorScheme.onBackground
                ),
                const SmallVSpace(),
                Small(text: title, color: color ?? theme.colorScheme.onBackground, context: context),
              ]
            ),
          ],
        ),
        onPressed: onPressed,
      );
    });
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override 
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  /// The associated profile service, which is injected by the provider.
  late ProfileService s;

  bool bikeSelectionActive = false;
  bool preferenceSelectionActive = false;
  bool activitySelectionActive = false;

  @override
  void didChangeDependencies() {
    s = Provider.of<ProfileService>(context);
    super.didChangeDependencies();
  }

  void toggleBikeSelection() {
    // Tell the tutorial that the user has seen a profile selection.
    Provider.of<TutorialService>(context, listen: false).complete("priobike.tutorial.configure-profile");

    setState(() {
      bikeSelectionActive = !bikeSelectionActive;
      preferenceSelectionActive = false;
      activitySelectionActive = false;
    });
  }

  void togglePreferenceSelection() {
    // Tell the tutorial that the user has seen a profile selection.
    Provider.of<TutorialService>(context, listen: false).complete("priobike.tutorial.configure-profile");

    setState(() {
      bikeSelectionActive = false;
      preferenceSelectionActive = !preferenceSelectionActive;
      activitySelectionActive = false;
    });
  }

  void toggleActivitySelection() {
    // Tell the tutorial that the user has seen a profile selection.
    Provider.of<TutorialService>(context, listen: false).complete("priobike.tutorial.configure-profile");

    setState(() {
      bikeSelectionActive = false;
      preferenceSelectionActive = false;
      activitySelectionActive = !activitySelectionActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!s.hasLoaded) renderLoadingIndicator();
    return renderProfileSelection();
  }

  /// Render a loading indicator.
  Widget renderLoadingIndicator() {
    return HPad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Tile(
        content: Center(child: SizedBox(
          height: 86, 
          width: 86, 
          child: Column(children: const [
            CircularProgressIndicator(),
          ])
        ))
      )
    ]));
  }

  Widget renderProfileSelection() {
    return HPad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const TutorialView(
        id: "priobike.tutorial.configure-profile", 
        text: 'Unten kannst du dein Profil konfigurieren. Diese Informationen werden für die Berechnung der Route verwendet. Du kannst sie jederzeit ändern.',
        padding: EdgeInsets.fromLTRB(0, 0, 0, 24),
      ),
      Tile(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        content: Column(children: [
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
                child: s.bikeType == null 
                  ? ProfileElementButton(
                      key: const ValueKey<String>("None"),
                      icon: Icons.electric_bike, 
                      title: "Radtyp", 
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onPressed: toggleBikeSelection
                    )
                  : ProfileElementButton(
                      key: ValueKey<String>(s.bikeType!.description()),
                      icon: s.bikeType!.icon(), 
                      title: s.bikeType!.description(),
                      color: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      touchColor: Colors.white,
                      onPressed: toggleBikeSelection,
                    )
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: s.preferenceType == null 
                  ? ProfileElementButton(
                      key: const ValueKey<String>("None"),
                      icon: Icons.thumbs_up_down, 
                      title: "Präferenz", 
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onPressed: togglePreferenceSelection,
                    )
                  : ProfileElementButton(
                      key: ValueKey<String>(s.preferenceType!.description()),
                      icon: s.preferenceType!.icon(), 
                      title: s.preferenceType!.description(),
                      color: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      touchColor: Colors.white,
                      onPressed: togglePreferenceSelection,
                    ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: s.activityType == null 
                  ? ProfileElementButton(
                      key: const ValueKey<String>("None"),
                      icon: Icons.home_work, 
                      title: "Aktivität", 
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onPressed: toggleActivitySelection,
                    )
                  : ProfileElementButton(
                      key: ValueKey<String>(s.activityType!.description()),
                      icon: s.activityType!.icon(), 
                      title: s.activityType!.description(),
                      color: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      touchColor: Colors.white,
                      onPressed: toggleActivitySelection,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: Container(),
            secondChild: renderBikeTypeSelection(),
            crossFadeState: bikeSelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: Container(),
            secondChild: renderPreferenceTypeSelection(),
            crossFadeState: preferenceSelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: Container(),
            secondChild: renderActivityTypeSelection(),
            crossFadeState: activitySelectionActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ]),
      ),
    ]));
  }

  Widget renderBikeTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Content(text: "Radtyp", context: context),
            const SmallVSpace(),
            Small(text: "Dein Rad ist so individuell wie du. Wähle den Radtyp, der am besten zu deinem Rad passt.", context: context),
          ],
        )),
        SmallIconButton(icon: Icons.close, onPressed: () {
          toggleBikeSelection();
        })
      ]),
      const VSpace(),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
        padding: EdgeInsets.zero,
        mainAxisSpacing: 8,
        crossAxisCount: 3, 
        physics: const NeverScrollableScrollPhysics(),
        children: BikeType.values.map((bikeType) => ProfileElementButton(
          icon: bikeType.icon(), 
          title: bikeType.description(),
          color: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          touchColor: Colors.white,
          onPressed: () {
            s.bikeType = bikeType;
            s.store();
          },
        )).toList() + [
          ProfileElementButton(
            icon: Icons.delete, 
            title: "Löschen",
            color: Theme.of(context).colorScheme.onBackground,
            backgroundColor: Theme.of(context).colorScheme.background,
            touchColor: Theme.of(context).colorScheme.onBackground,
            onPressed: () {
              s.bikeType = null;
              s.store();
            },
          )
        ],
      ),
      const VSpace(),
    ]);
  }

  Widget renderPreferenceTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Content(text: "Routenpräferenz", context: context),
            const SmallVSpace(),
            Small(text: "Wir werden dir Routen vorschlagen, die deinen Präferenzen entsprechen.", context: context),
          ],
        )),
        const SmallHSpace(),
        SmallIconButton(icon: Icons.close, onPressed: () {
          togglePreferenceSelection();
        })
      ]),
      const VSpace(),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
        padding: EdgeInsets.zero,
        mainAxisSpacing: 8,
        crossAxisCount: 3, 
        physics: const NeverScrollableScrollPhysics(),
        children: PreferenceType.values.map((preferenceType) => ProfileElementButton(
          icon: preferenceType.icon(), 
          title: preferenceType.description(),
          color: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          touchColor: Colors.white,
          onPressed: () {
            s.preferenceType = preferenceType;
            s.store();
          },
        )).toList() + [
          ProfileElementButton(
            icon: Icons.delete, 
            title: "Löschen",
            color: Theme.of(context).colorScheme.onBackground,
            backgroundColor: Theme.of(context).colorScheme.background,
            touchColor: Theme.of(context).colorScheme.onBackground,
            onPressed: () {
              s.preferenceType = null;
              s.store();
            },
          )
        ],
      ),
      const VSpace(),
    ]);
  }

  Widget renderActivityTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Content(text: "Aktivität", context: context),
            const SmallVSpace(),
            Small(text: "Wir können dafür sorgen, dass du nach deiner Fahrt duschen musst, oder nicht.", context: context),
          ],
        )),
        const SmallHSpace(),
        SmallIconButton(icon: Icons.close, onPressed: () {
          toggleActivitySelection();
        })
      ]),
      const VSpace(),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
        padding: EdgeInsets.zero,
        mainAxisSpacing: 8,
        crossAxisCount: 3, 
        physics: const NeverScrollableScrollPhysics(),
        children: ActivityType.values.map((activityType) => ProfileElementButton(
          icon: activityType.icon(), 
          title: activityType.description(),
          color: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          touchColor: Colors.white,
          onPressed: () {
            s.activityType = activityType;
            s.store();
          },
        )).toList() + [
          ProfileElementButton(
            icon: Icons.delete, 
            title: "Löschen",
            color: Theme.of(context).colorScheme.onBackground,
            backgroundColor: Theme.of(context).colorScheme.background,
            touchColor: Theme.of(context).colorScheme.onBackground,
            onPressed: () {
              s.activityType= null;
              s.store();
            },
          )
        ],
      ),
      const VSpace(),
    ]);
  }
}

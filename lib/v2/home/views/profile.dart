

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/layout/buttons.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/common/layout/tiles.dart';
import 'package:priobike/v2/home/models/profile.dart';
import 'package:priobike/v2/home/services/profile.dart';
import 'package:provider/provider.dart';

class ProfileElementButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final Color touchColor;
  final void Function()? onPressed;

  const ProfileElementButton({
    Key? key, 
    required this.icon, 
    required this.title,
    this.color = Colors.grey,
    this.backgroundColor = AppColors.lightGrey,
    this.touchColor = Colors.grey,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tile(
      fill: backgroundColor,
      splash: touchColor,
      padding: const EdgeInsets.all(8),
      content: Column(children: [
        Icon(icon, size: 48, color: color),
        const SmallVSpace(),
        Small(text: title, color: color),
      ]),
      onPressed: onPressed,
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
  late ProfileService s;

  bool bikeSelectionActive = false;
  bool preferenceSelectionActive = false;
  bool activitySelectionActive = false;

  @override
  void didChangeDependencies() {
    s = Provider.of<ProfileService>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      s.loadProfile();
    });

    super.didChangeDependencies();
  }

  void toggleBikeSelection() {
    setState(() {
      bikeSelectionActive = !bikeSelectionActive;
      preferenceSelectionActive = false;
      activitySelectionActive = false;
    });
  }

  void togglePreferenceSelection() {
    setState(() {
      bikeSelectionActive = false;
      preferenceSelectionActive = !preferenceSelectionActive;
      activitySelectionActive = false;
    });
  }

  void toggleActivitySelection() {
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
      Tile(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        content: Column(children: [
          const VSpace(),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            crossAxisSpacing: 8,
            crossAxisCount: 3, 
            children: [
              if (s.bikeType == null) 
                ProfileElementButton(icon: Icons.electric_bike, title: "Radtyp", onPressed: () {
                  toggleBikeSelection();
                }),
              if (s.bikeType != null) 
                ProfileElementButton(
                  icon: s.bikeType!.icon(), 
                  title: s.bikeType!.description(),
                  color: Colors.white,
                  backgroundColor: s.bikeType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    toggleBikeSelection();
                  },
                ),
              if (s.preferenceType == null) 
                ProfileElementButton(icon: Icons.thumbs_up_down, title: "Präferenz", onPressed: () {
                  togglePreferenceSelection();
                }),
              if (s.preferenceType != null) 
                ProfileElementButton(
                  icon: s.preferenceType!.icon(), 
                  title: s.preferenceType!.description(),
                  color: Colors.white,
                  backgroundColor: s.preferenceType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    togglePreferenceSelection();
                  },
                ),
              if (s.activityType == null) 
                ProfileElementButton(icon: Icons.home_work, title: "Aktivität", onPressed: () {
                  toggleActivitySelection();
                }),
              if (s.activityType != null) 
                ProfileElementButton(
                  icon: s.activityType!.icon(), 
                  title: s.activityType!.description(),
                  color: Colors.white,
                  backgroundColor: s.activityType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    toggleActivitySelection();
                  },
                ),
            ],
          ),
          const VSpace(),
          if (bikeSelectionActive) renderBikeTypeSelection(),
          if (preferenceSelectionActive) renderPreferenceTypeSelection(),
          if (activitySelectionActive) renderActivityTypeSelection(),
        ]),
      ),
    ]));
  }

  Widget renderBikeTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Content(text: "Wähle deinen Radtyp")),
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
          backgroundColor: bikeType.color(),
          touchColor: Colors.white,
          onPressed: () {
            s.bikeType = bikeType;
            s.store();
          },
        )).toList(),
      ),
      const VSpace(),
    ]);
  }

  Widget renderPreferenceTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Content(text: "Wähle deine Routenpräferenz")),
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
          backgroundColor: preferenceType.color(),
          touchColor: Colors.white,
          onPressed: () {
            s.preferenceType = preferenceType;
            s.store();
          },
        )).toList(),
      ),
      const VSpace(),
    ]);
  }

  Widget renderActivityTypeSelection() {
    return Column(children: [
      Row(children: [
        Expanded(child: Content(text: "Wähle deine Aktivität")),
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
          backgroundColor: activityType.color(),
          touchColor: Colors.white,
          onPressed: () {
            s.activityType = activityType;
            s.store();
          },
        )).toList(),
      ),
      const VSpace(),
    ]);
  }
}

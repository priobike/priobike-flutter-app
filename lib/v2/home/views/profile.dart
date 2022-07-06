

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/views/buttons.dart';
import 'package:priobike/v2/common/views/spacing.dart';
import 'package:priobike/v2/common/views/text.dart';
import 'package:priobike/v2/common/views/tiles.dart';
import 'package:priobike/v2/home/models/profile.dart';

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
      padding: const EdgeInsets.all(4), 
      content: Tile(
        fill: backgroundColor,
        splash: touchColor,
        padding: const EdgeInsets.all(4),
        content: Column(children: [
          Icon(icon, size: 48, color: color),
          const SmallVSpace(),
          Small(text: title, color: color),
        ]),
        onPressed: onPressed,
      ), 
      fill: Colors.white
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override 
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  bool bikeSelectionActive = false;
  bool preferenceSelectionActive = false;
  bool activitySelectionActive = false;

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
    return FutureBuilder<Profile>(
      future: Profile.load(),
      builder: (BuildContext context, AsyncSnapshot<Profile> snapshot) {
        if (!snapshot.hasData) {
          // Still loading
          return renderLoadingIndicator();
        }
        var profile = snapshot.data!;
        return renderProfileSelection(profile);
      },
    );
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

  Widget renderProfileSelection(Profile profile) {
    return HPad(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Tile(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        content: Column(children: [
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisSpacing: 8,
            crossAxisCount: 3, 
            children: [
              if (profile.bikeType == null) 
                ProfileElementButton(icon: Icons.electric_bike, title: "Radtyp", onPressed: () {
                  toggleBikeSelection();
                }),
              if (profile.bikeType != null) 
                ProfileElementButton(
                  icon: profile.bikeType!.icon(), 
                  title: profile.bikeType!.description(),
                  color: Colors.white,
                  backgroundColor: profile.bikeType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    toggleBikeSelection();
                  },
                ),
              if (profile.preferenceType == null) 
                ProfileElementButton(icon: Icons.thumbs_up_down, title: "Präferenz", onPressed: () {
                  togglePreferenceSelection();
                }),
              if (profile.preferenceType != null) 
                ProfileElementButton(
                  icon: profile.preferenceType!.icon(), 
                  title: profile.preferenceType!.description(),
                  color: Colors.white,
                  backgroundColor: profile.preferenceType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    togglePreferenceSelection();
                  },
                ),
              if (profile.activityType == null) 
                ProfileElementButton(icon: Icons.home_work, title: "Aktivität", onPressed: () {
                  toggleActivitySelection();
                }),
              if (profile.activityType != null) 
                ProfileElementButton(
                  icon: profile.activityType!.icon(), 
                  title: profile.activityType!.description(),
                  color: Colors.white,
                  backgroundColor: profile.activityType!.color(),
                  touchColor: Colors.white,
                  onPressed: () {
                    toggleActivitySelection();
                  },
                ),
            ],
          ),
          if (bikeSelectionActive) renderBikeTypeSelection(profile),
          if (preferenceSelectionActive) renderPreferenceTypeSelection(profile),
          if (activitySelectionActive) renderActivityTypeSelection(profile),
          const VSpace(),
        ]),
      ),
    ]));
  }

  Widget renderBikeTypeSelection(Profile profile) {
    return Column(children: [
      const VSpace(),
      Row(children: [
        Expanded(child: Content(text: "Wähle deinen Radtyp")),
        SmallIconButton(icon: Icons.close, onPressed: () {
          toggleBikeSelection();
        })
      ]),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
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
            profile.bikeType = bikeType;
            setState(() { profile.store(); });
          },
        )).toList(),
      ),
    ]);
  }

  Widget renderPreferenceTypeSelection(Profile profile) {
    return Column(children: [
      const VSpace(),
      Row(children: [
        Expanded(child: Content(text: "Wähle deine Routenpräferenz")),
        SmallIconButton(icon: Icons.close, onPressed: () {
          togglePreferenceSelection();
        })
      ]),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
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
            profile.preferenceType = preferenceType;
            setState(() { profile.store(); });
          },
        )).toList(),
      ),
    ]);
  }

  Widget renderActivityTypeSelection(Profile profile) {
    return Column(children: [
      const VSpace(),
      Row(children: [
        Expanded(child: Content(text: "Wähle deine Aktivität")),
        SmallIconButton(icon: Icons.close, onPressed: () {
          toggleActivitySelection();
        })
      ]),
      GridView.count(
        shrinkWrap: true,
        crossAxisSpacing: 8,
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
            profile.activityType = activityType;
            setState(() { profile.store(); });
          },
        )).toList(),
      ),
    ]);
  }
}

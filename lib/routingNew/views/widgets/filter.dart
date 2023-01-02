import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:provider/provider.dart';

class FilterSelectionView extends StatefulWidget {
  const FilterSelectionView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FilterSelectionViewState();
}

class FilterSelectionViewState extends State<FilterSelectionView> {
  late Profile profile;

  @override
  void didChangeDependencies() {
    profile = Provider.of<Profile>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Show a grid view with all available layers.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Content(text: "Filter", context: context),
          const SmallVSpace(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Content(text: "Fahrradart", context: context),
              BoldContent(text: profile.bikeType?.description() ?? "", context: context),
            ],
          ),
          Container(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      profile.bikeType = null;
                      profile.store();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: profile.bikeType == null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.pedal_bike,
                        color: profile.bikeType == null
                            ? Colors.white
                            : Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      profile.bikeType = BikeType.ebike;
                      profile.store();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: profile.bikeType == BikeType.ebike
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(0),
                      ),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.electric_bike,
                        color: profile.bikeType == BikeType.ebike
                            ? Colors.white
                            : Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      profile.bikeType = BikeType.racingbike;
                      profile.store();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: profile.bikeType == BikeType.racingbike
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(0),
                      ),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.pedal_bike,
                        color: profile.bikeType == BikeType.racingbike
                            ? Colors.white
                            : Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      profile.bikeType = BikeType.mountainbike;
                      profile.store();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: profile.bikeType == BikeType.mountainbike
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(0),
                      ),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.directions_bike_sharp,
                        color: profile.bikeType == BikeType.mountainbike
                            ? Colors.white
                            : Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      profile.bikeType = BikeType.cargobike;
                      profile.store();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: profile.bikeType == BikeType.cargobike
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(Icons.pedal_bike,
                        color: profile.bikeType == BikeType.cargobike
                            ? Colors.white
                            : Theme.of(context).colorScheme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SmallVSpace(),
          Align(
            alignment: Alignment.centerLeft,
            child: Content(text: "Bevorzugter Streckentyp", context: context),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    profile.preferenceType = PreferenceType.fast;
                    profile.store();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: profile.preferenceType == PreferenceType.fast
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                  ),
                  side: const BorderSide(width: 1, color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Content(
                      text: "Schnell",
                      context: context,
                      color: profile.preferenceType == PreferenceType.fast ? Colors.white : null),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    profile.preferenceType = PreferenceType.short;
                    profile.store();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: profile.preferenceType == PreferenceType.short
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(0),
                    ),
                  ),
                  side: const BorderSide(width: 1, color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Content(
                      text: "Kurz",
                      context: context,
                      color: profile.preferenceType == PreferenceType.short ? Colors.white : null),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    profile.preferenceType = PreferenceType.comfortible;
                    profile.store();
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: profile.preferenceType == PreferenceType.comfortible
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                  ),
                  side: const BorderSide(width: 1, color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Content(
                      text: "Bequem",
                      context: context,
                      color: profile.preferenceType == PreferenceType.comfortible ? Colors.white : null),
                ),
              ),
            ),
          ]),
          const SmallVSpace(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Content(text: "Anstiege meiden", context: context),
              Switch(
                value: profile.avoidAscents ?? false,
                onChanged: (value) {
                  profile.avoidAscents = value;
                  profile.store();
                },
              ),
            ],
          ),
          const SmallVSpace(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Content(text: "KFZs meiden", context: context),
            Switch(
              value: profile.avoidTraffic ?? false,
              onChanged: (value) {
                profile.avoidTraffic = value;
                profile.store();
              },
            ),
          ]),
        ]),
      ),
    );
  }
}

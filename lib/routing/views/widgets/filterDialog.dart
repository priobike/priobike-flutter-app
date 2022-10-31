import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';

showFilterDialog(BuildContext context, Profile? profileService) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 25,
                        ),
                        BoldSubHeader(text: "Filter", context: context),
                        Container(width: 50)
                      ],
                    ),
                    Container(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Content(text: "Fahrradart", context: context),
                              BoldContent(
                                  text:
                                      profileService?.bikeType?.description() ??
                                          "",
                                  context: context),
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
                                      profileService?.bikeType = BikeType.bike;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService?.bikeType ==
                                            BikeType.bike
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15)),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.pedal_bike,
                                        color: profileService?.bikeType ==
                                                BikeType.bike
                                            ? Colors.white
                                            : Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.bikeType = BikeType.ebike;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService?.bikeType ==
                                            BikeType.ebike
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(0),
                                      ),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.electric_bike,
                                        color: profileService?.bikeType ==
                                                BikeType.ebike
                                            ? Colors.white
                                            : Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.bikeType =
                                          BikeType.racingbike;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService?.bikeType ==
                                            BikeType.racingbike
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(0),
                                      ),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.pedal_bike,
                                        color: profileService?.bikeType ==
                                                BikeType.racingbike
                                            ? Colors.white
                                            : Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.bikeType =
                                          BikeType.mountainbike;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService?.bikeType ==
                                            BikeType.mountainbike
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(0),
                                      ),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.directions_bike_sharp,
                                        color: profileService?.bikeType ==
                                                BikeType.mountainbike
                                            ? Colors.white
                                            : Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.bikeType =
                                          BikeType.cargobike;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService?.bikeType ==
                                            BikeType.cargobike
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(15),
                                          bottomRight: Radius.circular(15)),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(Icons.pedal_bike,
                                        color: profileService?.bikeType ==
                                                BikeType.cargobike
                                            ? Colors.white
                                            : Theme.of(context)
                                                        .colorScheme
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 25),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Content(
                                text: "Bevorzugter Streckentyp",
                                context: context),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.preferenceType =
                                          PreferenceType.fast;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService
                                                ?.preferenceType ==
                                            PreferenceType.fast
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15)),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Content(
                                        text: "Schnell",
                                        context: context,
                                        color: profileService?.preferenceType ==
                                                PreferenceType.fast
                                            ? Colors.white
                                            : null),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.preferenceType =
                                          PreferenceType.short;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService
                                                ?.preferenceType ==
                                            PreferenceType.short
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(0),
                                      ),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Content(
                                        text: "Kurz",
                                        context: context,
                                        color: profileService?.preferenceType ==
                                                PreferenceType.short
                                            ? Colors.white
                                            : null),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      profileService?.preferenceType =
                                          PreferenceType.comfortible;
                                      profileService?.store();
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: profileService
                                                ?.preferenceType ==
                                            PreferenceType.comfortible
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .background,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(15),
                                          bottomRight: Radius.circular(15)),
                                    ),
                                    side: const BorderSide(
                                        width: 1, color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Content(
                                        text: "Bequem",
                                        context: context,
                                        color: profileService?.preferenceType ==
                                                PreferenceType.comfortible
                                            ? Colors.white
                                            : null),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 25),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Content(
                          //         text: "Ampeln anzeigen", context: context),
                          //     Switch(
                          //       value:
                          //           profileService?.showTrafficLights ?? false,
                          //       onChanged: (value) {
                          //         setState(() {
                          //           profileService?.showTrafficLights = value;
                          //           profileService?.store();
                          //         });
                          //       },
                          //     ),
                          //   ],
                          // ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Content(text: "Ampeln meiden", context: context),
                              Switch(
                                value:
                                    profileService?.avoidTrafficLights ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.avoidTrafficLights = value;
                                    profileService?.store();
                                  });
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Content(
                                  text: "Anstiege meiden", context: context),
                              Switch(
                                value: profileService?.avoidAscents ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.avoidAscents = value;
                                    profileService?.store();
                                  });
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Content(text: "KFZs meiden", context: context),
                              Switch(
                                value: profileService?.avoidTraffic ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.avoidTraffic = value;
                                    profileService?.store();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      });
}

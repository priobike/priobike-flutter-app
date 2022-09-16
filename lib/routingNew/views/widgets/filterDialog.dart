import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/profile.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/settings/models/ride.dart';

showFilterDialog(BuildContext context, ProfileService? profileService) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView(
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
                  Container(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Content(text: "Fahrradart", context: context),
                      BoldContent(text: "E-Bike", context: context),
                    ],
                  ),
                  Container(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor:
                                profileService?.bikeType == BikeType.bike
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15)),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.pedal_bike),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(0),
                              ),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.electric_bike),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(0),
                              ),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.pedal_bike),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(0),
                              ),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.directions_bike_sharp),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.pedal_bike)),
                        ),
                      ),
                    ],
                  ),
                  Container(height: 25),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Content(
                        text: "Bevorzugter Streckentyp", context: context),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15)),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Text("Schnell"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(0),
                              ),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Text("Kurz"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                            ),
                            side:
                                const BorderSide(width: 1, color: Colors.black),
                          ),
                          child: const Text("Bequem"),
                        ),
                      ),
                    ],
                  ),
                  Container(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Content(text: "Ampeln anzeigen", context: context),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Content(text: "Ampeln meiden", context: context),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Content(text: "Anstiege meiden", context: context),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Content(text: "KFZs meiden", context: context),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
}

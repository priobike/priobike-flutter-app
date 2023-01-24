import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/place.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/routing_new/views/widgets/selectOnMap.dart';
import 'package:provider/provider.dart';

class PlacesView extends StatefulWidget {
  const PlacesView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PlacesViewState();
}

class PlacesViewState extends State<PlacesView> {
  /// The associated places service, which is injected by the provider.
  late Places places;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    places = Provider.of<Places>(context);

    super.didChangeDependencies();
  }

  /// A callback that is executed when a place should be deleted.
  Future<void> onDeletePlace(Place place) async {
    if (places.places == null || places.places!.isEmpty) return;

    final newPlaces = places.places!.toList();
    newPlaces.remove(place);

    places.updatePlaces(newPlaces, context);
  }

  /// The widget which displays a place.
  Widget _placeRowItem(Place place) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 20, bottom: 20, right: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: BoldSubHeader(
                  text: place.name,
                  context: context,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 5),
              SmallIconButton(
                icon: Icons.delete,
                onPressed: () {
                  onDeletePlace(place);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Content(
              text: place.waypoint.address ?? "",
              context: context,
              color: Colors.grey,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    List<Widget> placesList = [];
    if (places.places != null) {
      placesList = places.places!.map((entry) => _placeRowItem(entry)).toList();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: BoldSubHeader(
                          text: "Meine Orte",
                          context: context,
                        ),
                      ),
                    ),
                  ),

                  /// To center the text
                  const SizedBox(width: 80),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: placesList,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(children: [
                    Expanded(
                      child: BigButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SelectOnMapView(withName: true)),
                          );
                        },
                        label: 'Ort Hinzufügen',
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

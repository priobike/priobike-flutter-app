import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:provider/provider.dart';

class LayerSelectionView extends StatefulWidget {
  const LayerSelectionView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LayerSelectionViewState();
}

class LayerSelectionViewState extends State<LayerSelectionView> {
  /// The layers service, which is injected by the provider.
  late Layers layers;

  @override
  void didChangeDependencies() {
    layers = Provider.of<Layers>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Show a grid view with all available layers.
    return Padding(padding: const EdgeInsets.all(8), child: GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        // The layer for the elevation.
        LayerSelectionItem(
          icon: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Image.asset("assets/images/rent-light.png")
              : Image.asset("assets/images/rent-dark.png"),
          title: 'Ausleihen',
          selected: layers.showRentalStations,
          onTap: () => layers.setShowRentalStations(!layers.showRentalStations),
        ),
        LayerSelectionItem(
          icon: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Image.asset("assets/images/park-light.png")
              : Image.asset("assets/images/park-dark.png"),
          title: 'Parken',
          selected: layers.showParkingStations,
          onTap: () => layers.setShowParkingStations(!layers.showParkingStations),
        ),
        LayerSelectionItem(
          icon: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Image.asset("assets/images/construction-light.png")
              : Image.asset("assets/images/construction-dark.png"),
          title: 'Baustellen',
          selected: layers.showConstructionSites,
          onTap: () => layers.setShowConstructionSites(!layers.showConstructionSites),
        ),
        LayerSelectionItem(
          icon: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Image.asset("assets/images/air-light.png")
              : Image.asset("assets/images/air-dark.png"),
          title: 'Aufpumpen',
          selected: layers.showAirStations,
          onTap: () => layers.setShowAirStations(!layers.showAirStations),
        ),
        LayerSelectionItem(
          icon: Theme.of(context).colorScheme.brightness == Brightness.light
              ? Image.asset("assets/images/repair-light.png")
              : Image.asset("assets/images/repair-dark.png"),
          title: 'Reparieren',
          selected: layers.showRepairStations,
          onTap: () => layers.setShowRepairStations(!layers.showRepairStations),
        ),
      ],
    ));
  }
}

class LayerSelectionItem extends StatelessWidget {
  final Image icon;
  final String title;
  final bool selected;
  final void Function() onTap;

  const LayerSelectionItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Tile(
        padding: const EdgeInsets.all(0),
        borderRadius: BorderRadius.circular(26),
        splash: Theme.of(context).colorScheme.primary,
        fill: Theme.of(context).colorScheme.surface,
        onPressed: onTap,
        content: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 52),
              BoldSmall(text: title, context: context),
            ],
          ),
          // Draw a blue border around the selected item.
          decoration: selected
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              )
            : BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
        ),
      ),
      IgnorePointer(child: Transform.scale(
        scale: 1.25,
        child: Transform.translate(offset: const Offset(0, 12), child: icon),
      )),
      // Show a checkmark icon if the item is selected.
      if (selected) IgnorePointer(child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      )),
    ]);
  }
}
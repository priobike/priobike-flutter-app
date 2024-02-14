import 'package:flutter/material.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'layout/buttons.dart';
import 'layout/dialog.dart';

class MapboxAttribution extends StatelessWidget {
  /// The top position of the attribution logo.
  final double? top;

  /// The left position of the attribution logo.
  final double? left;

  /// The right position of the attribution logo.
  final double? right;

  /// The bottom position of the attribution logo.
  final double? bottom;

  /// The width of the attribution logo.
  final double width;

  const MapboxAttribution({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width = 32,
  });

  /// Used to show the attribution dialog.
  /// (Only if the battery saving mode is used
  /// because otherwise the Mapbox native dialog is used.)
  /// (In the battery saving mode the Mapbox native dialog can't be used
  /// because it is outside of the visible display area.)
  static showAttribution(BuildContext context) {
    final bool satelliteAttributionRequired = getIt<MapDesigns>().mapDesign.name == 'Satellit';
    final List<Map<String, dynamic>> attributionEntries = [
      {
        'title': 'Mapbox',
        'url': Uri.parse('https://www.mapbox.com/about/maps/'),
      },
      {
        'title': 'OpenStreetMap',
        'url': Uri.parse('https://www.openstreetmap.org/copyright'),
      },
      {
        'title': 'Verbessere diese Karte',
        'url': Uri.parse('https://www.mapbox.com/map-feedback/'),
      },
      if (satelliteAttributionRequired)
        {
          'title': 'Maxar',
          'url': Uri.parse('https://www.maxar.com/'),
        },
    ];
    const title = "Powered by Mapbox Maps";

    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return DialogLayout(
            title: title,
            text: "",
            actions: [
              for (final entry in attributionEntries)
                BigButtonPrimary(
                  label: entry['title']!,
                  onPressed: () async {
                    Navigator.pop(context);
                    await launchUrl(entry['url']!, mode: LaunchMode.externalApplication);
                  },
                  boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
                ),
              BigButtonTertiary(
                label: "Abbrechen",
                onPressed: () => Navigator.pop(context),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: InkWell(
        child: Image.asset(
          'assets/images/mapbox-logo-transparent.png',
          width: width,
        ),
        onTap: () => showAttribution(context),
      ),
    );
  }
}

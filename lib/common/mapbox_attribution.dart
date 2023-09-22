import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/main.dart';
import 'package:url_launcher/url_launcher.dart';

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
    Key? key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.width = 32,
  }) : super(key: key);

  /// Used to show the attribution dialog.
  /// (Only if the battery saving mode is used because otherwise the Mapbox native dialog is used.)
  /// (In the battery saving mode the Mapbox native dialog can't be used because it is outside of the visible display area.)
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
        'title': 'Improve this map',
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
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              BoldContent(
                text: title,
                context: context,
              ),
              for (final entry in attributionEntries)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await launchUrl(entry['url']!, mode: LaunchMode.externalApplication);
                  },
                  child: Text(entry['title']!),
                ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
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

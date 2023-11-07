import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/views/shortcuts/gpx_conversion.dart';

class ImportGpxInfo extends StatefulWidget {
  const ImportGpxInfo({Key? key, required this.convertCallback, required this.gpxConversionNotifier}) : super(key: key);

  final VoidCallback convertCallback;
  final GpxConversion gpxConversionNotifier;

  @override
  ImportGpxInfoState createState() => ImportGpxInfoState();
}

class ImportGpxInfoState extends State<ImportGpxInfo> {
  GpxConversionState loadingState = GpxConversionState.init;

  @override
  void initState() {
    super.initState();
    widget.gpxConversionNotifier.addListener(() {
      setState(() => loadingState = widget.gpxConversionNotifier.loadingState);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          const VSpace(),
          BoldSmall(
            text:
                'Es kann sein dass wir die Route nicht perfekt konvertieren können, da die zugrunde liegenden Kartendaten abweichen können.',
            context: context,
            textAlign: TextAlign.center,
          ),
          const VSpace(),
          if (loadingState == GpxConversionState.init)
            BigButton(
              label: 'Konvertieren',
              onPressed: () => widget.convertCallback.call(),
            ),
          if (loadingState == GpxConversionState.loading) const Center(child: CircularProgressIndicator())
        ],
      ),
    );
  }
}

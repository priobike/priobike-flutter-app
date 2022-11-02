import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:provider/provider.dart';

/// A small view that displays a checkmark and a text,
/// asking the user to send the recorded track.
class SendTrackingView extends StatefulWidget {
  const SendTrackingView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SendTrackingViewState();
}

class SendTrackingViewState extends State<SendTrackingView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (tracking.json == null) return Container();

    final jsonSizeKB = tracking.json!.length / 1000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            child: Content(
          text: "Aufgezeichnete Daten zur Verbesserung der App senden (${jsonSizeKB.toStringAsFixed(1)} KB)",
          context: context,
        )),
        const HSpace(),
        Checkbox(
          value: tracking.willSendTrack,
          onChanged: (value) => tracking.setWillSendTrack(value ?? false),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

class ImportGpxInfo extends StatefulWidget {
  const ImportGpxInfo(
      {Key? key, required this.convertCallback, required this.startedConvertNotifier, required this.convertingNotifier})
      : super(key: key);

  final VoidCallback convertCallback;
  final ValueNotifier<bool> startedConvertNotifier;
  final ValueNotifier<bool> convertingNotifier;

  @override
  ImportGpxInfoState createState() => ImportGpxInfoState();
}

class ImportGpxInfoState extends State<ImportGpxInfo> {
  bool startedConvert = false;
  bool converting = false;

  @override
  void initState() {
    super.initState();
    widget.startedConvertNotifier.addListener(() {
      setState(() => startedConvert = widget.startedConvertNotifier.value);
    });
    widget.convertingNotifier.addListener(() {
      setState(() => converting = widget.convertingNotifier.value);
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
          !startedConvert
              ? BigButton(
                  label: 'Konvertieren',
                  onPressed: () => widget.convertCallback.call(),
                )
              : const SizedBox.shrink(),
          converting ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/main.dart';

class LoadStatusView extends StatefulWidget {
  const LoadStatusView({super.key});

  @override
  LoadStatusViewState createState() => LoadStatusViewState();
}

class LoadStatusViewState extends State<LoadStatusView> {
  /// The associated LoadStatus service.
  late LoadStatus loadStatus;

  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    loadStatus = getIt<LoadStatus>();
  }

  @override
  Widget build(BuildContext context) {
    if (!loadStatus.hasWarning) {
      return Container();
    }

    return BlendIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(40, 24, 36, 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Small(
                text: "Aktuell sind unsere Server außergewöhnlich stark ausgelastet.",
                context: context,
              ),
            ),
            const HSpace(),
            Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.onSurface,
            )
          ],
        ),
      ),
    );
  }
}

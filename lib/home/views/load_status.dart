import 'package:flutter/material.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
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

  /// Alert dialog for location accuracy
  void showMoreInformationDialog() => showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return DialogLayout(
            title: "Vermehrte Anzahl an Nutzenden",
            text: loadStatus.text ?? "",
            actions: [
              BigButtonTertiary(
                label: "Schließen",
                onPressed: () => Navigator.pop(context),
                boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    if (!loadStatus.hasWarning) {
      return Container();
    }

    return BlendIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vermehrte Anzahl an Nutzenden',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            SmallIconButtonSecondary(
              icon: Icons.info,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              splash: Theme.of(context).colorScheme.surfaceTint,
              fill: Colors.transparent,
              borderColor: Theme.of(context).colorScheme.onSurface,
              withBorder: false,
              onPressed: () => showMoreInformationDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
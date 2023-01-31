import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';

/// The gps button.
class GPSButton extends StatelessWidget {
  final Function gpsCentralization;

  const GPSButton({Key? key, required this.gpsCentralization}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: Icons.gps_not_fixed,
        color: Theme.of(context).colorScheme.primary,
        onPressed: () => gpsCentralization(),
      ),
    );
  }
}

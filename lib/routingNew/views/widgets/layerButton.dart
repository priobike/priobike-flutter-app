import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/routingNew/views/layers.dart';

/// The layer button.
class LayerButton extends StatelessWidget {
  const LayerButton({Key? key}) : super(key: key);

  /// A callback that is fired when the user wants to select the displayed layers.
  void onLayerSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      builder: (_) => const LayerSelectionView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: Icons.layers,
        onPressed: () => onLayerSelection(context),
      ),
    );
  }
}

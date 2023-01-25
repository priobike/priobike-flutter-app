import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/routing/views_beta/widgets/filter.dart';

/// The filter button.
class FilterButton extends StatelessWidget {
  const FilterButton({Key? key}) : super(key: key);

  /// A callback that is fired when the user wants to select the filter settings.
  void onFilterSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
      builder: (_) => const FilterSelectionView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: Icons.filter_alt_rounded,
        onPressed: () => onFilterSelection(context),
      ),
    );
  }
}

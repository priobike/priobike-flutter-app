import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routingNew/views/widgets/filterDialog.dart';

/// The filter button.
class FilterButton extends StatelessWidget {
  final Profile? profileService;

  const FilterButton({Key? key, this.profileService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: Icons.filter_alt_rounded,
        onPressed: () {
          showFilterDialog(context, profileService);
        },
      ),
    );
  }
}

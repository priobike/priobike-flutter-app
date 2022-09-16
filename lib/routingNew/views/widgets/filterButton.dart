import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routingNew/views/widgets/filterDialog.dart';

/// A view that displays alerts in the routing context.
class FilterButton extends StatelessWidget {
  final ProfileService? profileService;

  const FilterButton({Key? key, this.profileService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /// 32 + 2*10 padding
      height: 64,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 5,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          child: SmallIconButton(
            icon: Icons.filter_alt_rounded,
            onPressed: () {
              showFilterDialog(context, profileService);
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

/// A button which is used to change route types.
class RouteTypeButton extends StatelessWidget {
  final String routeType;
  final Function changeRouteType;

  const RouteTypeButton(
      {Key? key, required this.routeType, required this.changeRouteType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      color: Theme.of(context).colorScheme.background,
      child: TextButton(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        onPressed: () => changeRouteType(),
        child: SubHeader(context: context, text: routeType, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

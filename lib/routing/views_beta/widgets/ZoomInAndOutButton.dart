import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';

/// A view that displays the zoom in and out button.
class ZoomInAndOutButton extends StatelessWidget {
  final Function zoomIn;
  final Function zoomOut;

  const ZoomInAndOutButton({Key? key, required this.zoomIn, required this.zoomOut}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /// 32 + 2*10 padding
      height: 96,
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(25.0)),
        child: Container(
          width: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SmallIconButton(icon: Icons.add, onPressed: () => zoomIn(), withBorder: false),
              ),
              Container(
                width: 40,
                height: 1,
                color: Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              Expanded(
                child: SmallIconButton(icon: Icons.remove, onPressed: () => zoomOut(), withBorder: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/dangers/views/modal.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/positioning/models/snap.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:provider/provider.dart';

/// A button to report a new danger.
class DangerButton extends StatefulWidget {
  const DangerButton({Key? key}) : super(key: key);

  @override
  DangerButtonState createState() => DangerButtonState();
}

class DangerButtonState extends State<DangerButton> {
  final log = Logger("DangerButtonState");

  /// If the hint is currently shown.
  bool showHint = true;

  /// If the modal is currently shown.
  bool showModal = false;

  /// The snapped danger position for the modal.
  Snap? dangerPosition;

  @override
  initState() {
    super.initState();

    // Hide the hint after a few seconds.
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) {
        Future.delayed(
          const Duration(seconds: 5),
          () {
            if (mounted) {
              setState(
                () {
                  showHint = false;
                },
              );
            }
          },
        );
      },
    );
  }

  /// A callback that is called when the button is tapped.
  Future<void> onTap() async {
    HapticFeedback.lightImpact();
    if (!showModal /* Prepare to show modal. */) {
      log.i("Caching the current position.");
      // Get the current snapped position.
      final snap = Provider.of<Positioning>(context, listen: false).snap;
      if (snap == null) {
        log.w("Cannot report a danger without a current snapped position.");
        return;
      }
      setState(() {
        showHint = false;
        dangerPosition = snap;
        showModal = true;
      });
    } else {
      setState(() {
        showHint = false;
        dangerPosition = null;
        showModal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstCurve: Curves.easeInOutCubicEmphasized,
          secondCurve: Curves.easeInOutCubicEmphasized,
          sizeCurve: Curves.easeInOutCubicEmphasized,
          firstChild: Container(),
          secondChild: DangerModal(
            position: dangerPosition,
            onExit: () {
              setState(() {
                dangerPosition = null;
                showModal = false;
              });
            },
          ),
          crossFadeState: showModal ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        Positioned(
          top: 48, // Below the MapBox attribution.
          left: 0,
          child: SafeArea(
            child: RawMaterialButton(
              elevation: 0, // Hide ugly material shadows.
              fillColor: Theme.of(context).colorScheme.background,
              splashColor: Theme.of(context).colorScheme.surface,
              constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 500),
                firstCurve: Curves.easeInOutCubic,
                secondCurve: Curves.easeInOutCubic,
                sizeCurve: Curves.easeInOutCubic,
                firstChild: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                secondChild: SizedBox(
                  height: 64,
                  width: 200,
                  child: Row(
                    children: [
                      const HSpace(),
                      Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      const SmallHSpace(),
                      Flexible(child: BoldContent(text: "Gefahr melden", context: context, maxLines: 1)),
                    ],
                  ),
                ),
                crossFadeState: showHint ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
              onPressed: onTap,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

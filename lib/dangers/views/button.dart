import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/dangers/services/dangers.dart';
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

  /// If the modal is currently shown.
  bool showModal = false;

  /// The snapped danger position for the modal.
  Snap? dangerPosition;

  /// The danger service, which is injected by the provider.
  late Dangers dangers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dangers = Provider.of<Dangers>(context);
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
        dangerPosition = snap;
        showModal = true;
      });
    } else {
      setState(() {
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
            child: Tile(
              onPressed: onTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              fill: Theme.of(context).colorScheme.background,
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (dangers.previousDangerToVoteFor != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
                      child: Image.asset(
                        dangers.previousDangerToVoteFor!.icon,
                        width: 32,
                        height: 32,
                      ),
                    ),
                    InkWell(
                      onTap: () => dangers.vote(context, dangers.previousDangerToVoteFor!, 1),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: CI.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SmallHSpace(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Small(
                          text: dangers.previousDangerToVoteFor!.description,
                          context: context,
                        ),
                        Small(
                          text: "gesehen?",
                          context: context,
                        ),
                      ],
                    ),
                    const SmallHSpace(),
                    InkWell(
                      onTap: () => dangers.vote(context, dangers.previousDangerToVoteFor!, -1),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: CI.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else if (dangers.upcomingDangerToDisplay != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
                            child: Image.asset(
                              dangers.upcomingDangerToDisplay!.icon,
                              width: 32,
                              height: 32,
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            width: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              value: dangers.distanceToUpcomingDangerToDisplay! / Dangers.distanceThreshold,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                      child: Icon(
                        Icons.warning_rounded,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

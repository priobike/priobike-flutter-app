import 'package:flutter/material.dart';
import 'package:priobike/tracking/models/tap_tracking.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:provider/provider.dart';

class ScreenTrackingView extends StatefulWidget {
  final Widget child;

  const ScreenTrackingView({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ScreenTrackingViewState();
}

class ScreenTrackingViewState extends State<ScreenTrackingView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// Temporary saving tap down X;
  double? tapDownX;

  /// Temporary saving tap down X;
  double? tapDownY;

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    super.didChangeDependencies();
  }

  _onTapDown(PointerEvent details) {
    // Temporary save position.
    tapDownX = details.position.dx;
    tapDownY = details.position.dy;
  }

  _onTapUp(PointerEvent details) {
    // Add tap to tracks.
    if (tapDownX != null && tapDownY != null) {
      tracking.track?.taps.add(
        ScreenTrack(
          tapDownX: tapDownX!.round(),
          tapDownY: tapDownY!.round(),
          tapUpX: details.position.dx.round(),
          tapUpY: details.position.dy.round(),
        ),
      );
    }

    // Rest positions.
    tapDownX = null;
    tapDownY = null;
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context).size;
    return SizedBox(
      width: frame.width,
      height: frame.height,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onTapDown,
        onPointerUp: _onTapUp,
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/tap_tracking.dart';
import 'package:priobike/tracking/services/tracking.dart';

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

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () => setState(() {});
    tracking = getIt<Tracking>();
    tracking.addListener(update);
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    super.dispose();
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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/tracking/models/tapTracking.dart';
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
  void initState() {
    super.initState();

    // Setting the device Size.
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      tracking.deviceSize = MediaQuery.of(context).size;
    });
  }

  @override
  void didChangeDependencies() {
    tracking = Provider.of<Tracking>(context);
    super.didChangeDependencies();
  }

  _onTapDown(TapDownDetails details) {
    print("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
    // Temporary save position.
    setState(() {
      tapDownX = details.globalPosition.dx;
      tapDownY = details.globalPosition.dy;
    });
  }

  _onTapUp(TapUpDetails details) {
  print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
    // Add tap to tracks.
    if (tapDownX != null && tapDownY != null) {
      tracking.addTap(ScreenTrack(
          tapDownX: tapDownX!,
          tapDownY: tapDownY!,
          tapUpX: details.globalPosition.dx,
          tapUpY: details.globalPosition.dy));
    }

    // Rest positions.
    setState(() {
      tapDownX = null;
      tapDownY = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context).size;
    return SizedBox(
      width: frame.width,
      height: frame.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        child: widget.child,
      ),
    );
  }
}

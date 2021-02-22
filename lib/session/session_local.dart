import 'package:priobike/session/session.dart';

class LocalSession extends Session {
  LocalSession() {
    print("local session created");
  }

  @override
  updateRoute(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {}
}

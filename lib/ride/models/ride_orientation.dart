/// The possible orientations of the device during a ride.
enum RideOrientation {
  portrait,
  // there are 2 landscape modes so it can be flipped by 180°
  landscapeLeft,
  landscapeRight,
}

extension QuaterTurns on RideOrientation {
  int getQuaterTurns() {
    switch (this) {
      case RideOrientation.portrait:
        return 0;
      case RideOrientation.landscapeLeft:
        return 1;
      case RideOrientation.landscapeRight:
        return 3;
    }
  }
}

import 'dart:math';

class Approx{
  final List<double> xs;
  final List<double> ys;
  final List<int> indices;

  Approx(this.xs, this.ys, this.indices);
}

double calcAngle(x1, y1, x2, y2) {
  double xDiff = x2 - x1;
  double yDiff = y2 - y1;
  double abs = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
  if (abs == 0) return 0;
  return acos(xDiff / abs);
}

double calcDistance(x1, y1, x2, y2){
  return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}


Approx initialApproximation(List<double> xsGpx, List<double> ysGpx){
  double angle_thrsh = (1 / 10) * pi;
  double d1_thrsh = 10000.0;
  double d2_thrsh = 5000.0;

  double xLast = xsGpx.first;
  double yLast = ysGpx.first;
  double angleLast = 0;
  List<double> xsApprox = [xLast];
  List<double> ysApprox = [yLast];
  List<int> indicesGpx = [0];
  for (int i = 0; i < xsGpx.length; i++) {
    double x = xsGpx[i];
    double y = ysGpx[i];
    double angle = calcAngle(x, y, xLast, yLast);
    double distance = calcDistance(x, y, xLast, yLast);
    if (distance > d1_thrsh || ((angleLast - angle).abs() > angle_thrsh && distance > d2_thrsh)){
      xsApprox.add(x);
      ysApprox.add(y);
      indicesGpx.add(i);
      xLast = x;
      yLast = y;
      angleLast = angle;
    }
  }
  xsApprox.add(xsGpx.last);
  ysApprox.add(ysGpx.last);
  indicesGpx.add(xsGpx.length - 1);
  return Approx(xsApprox, ysApprox, indicesGpx);
}
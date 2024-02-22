import 'dart:math';
import 'dart:ui';

extension FlutterPoint on Point {
  Offset toOffset() {
    return Offset(x.toDouble(), y.toDouble());
  }
}

extension PointForOffset on Offset {
  Point toPoint() {
    return Point(dx, dy);
  }
}

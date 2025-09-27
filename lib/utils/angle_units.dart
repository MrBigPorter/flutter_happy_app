import 'dart:math' as math;

extension AngleUnits on num {
  /// 360度制转0-1之间的小数 360-degree to decimal between 0 and 1
  double get deg => this / 360.0;
  /// 角度转弧度 degree to radian
  double get rad => this * math.pi / 180.0;
}
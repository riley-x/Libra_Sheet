import 'dart:ui';

extension PathUtilsExtension on Path {
  void moveToOffset(Offset x) => moveTo(x.dx, x.dy);
  void lineToOffset(Offset x) => lineTo(x.dx, x.dy);
}

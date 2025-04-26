import 'dart:ui';

extension PathUtilsExtension on Path {
  void moveToOffset(Offset x) => moveTo(x.dx, x.dy);
  void lineToOffset(Offset x) => lineTo(x.dx, x.dy);
  void cubicToOffset(Offset end, Offset c1, Offset c2) =>
      cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
}

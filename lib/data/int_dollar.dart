import 'package:intl/intl.dart';

extension IntDollar on int {
  double asDouble() {
    return toDouble() / 10000;
  }

  String dollarString([int decimals = 2]) {
    final formatter = NumberFormat('\$#,###');
    final integer = formatter.format(this ~/ 10000);
    final int fraction;
    switch (decimals) {
      case 0:
        return integer;
      case 2:
        fraction = (this ~/ 100) % 100;
      case 4:
        fraction = this % 10000;
      default:
        throw UnimplementedError('dollarString() unknown decimals $decimals');
    }
    return "$integer.$fraction";
  }
}

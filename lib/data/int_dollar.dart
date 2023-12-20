import 'package:intl/intl.dart';

extension IntDollar on int {
  double asDollarDouble() {
    return (this ~/ 100).toDouble() / 100;
  }

  String dollarString({int decimals = 2, bool dollarSign = true}) {
    final absVal = abs();
    final formatter = NumberFormat((dollarSign) ? '\$#,###' : '#,###');
    final integer = formatter.format(absVal ~/ 10000);

    final int fraction;
    switch (decimals) {
      case 0:
        return (isNegative) ? "-$integer" : integer;
      case 2:
        fraction = (absVal ~/ 100) % 100;
      case 4:
        fraction = absVal % 10000;
      default:
        throw UnimplementedError('dollarString() unknown decimals $decimals');
    }
    final factionStr = fraction.toString().padLeft(decimals, '0');

    var out = "$integer.$factionStr";
    if (isNegative) return "-$out";
    return out;
  }
}

extension IntDollarDouble on double {
  int? toIntDollar() {
    return toString().toIntDollar();
  }
}

extension IntDollarString on String {
  int? toIntDollar() {
    var str = replaceAll(',', '');
    if (str.isEmpty) return null;

    final parts = str.split('.');
    if (parts.length > 2) return null;

    final intPart = int.tryParse(parts[0]);
    if (intPart == null) return null;

    int fracPart = 0;
    if (parts.length == 2) {
      String paddedStr = parts[1].padRight(4, '0');
      if (paddedStr.length > 4) {
        paddedStr = paddedStr.substring(0, 4);
      }
      final val = int.tryParse(paddedStr);
      if (val == null) return null;
      fracPart = val;
    }

    if (intPart < 0 || (intPart == 0 && str[0] == '-')) {
      return intPart * 10000 - fracPart;
    } else {
      return intPart * 10000 + fracPart;
    }
  }
}

final _format = NumberFormat('#,###');
String formatOrder(double val, int order) {
  return _format.format(val);
}

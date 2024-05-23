import 'package:intl/intl.dart';

extension IntDollar on int {
  double asDollarDouble() {
    return toDouble() / 10000;
  }

  String dollarString({int decimals = 2, bool dollarSign = true, bool commas = true}) {
    final absVal = abs();
    var formatString = commas ? '#,###' : '#';
    if (dollarSign) formatString = '\$$formatString';
    final formatter = NumberFormat(formatString);
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

  /// Default [toString] formats integers as "10.0"
  String toSimpleString() {
    return NumberFormat("#.##").format(this);
  }

  /// Formats [val] with dollar sign and commas. If [order] is not null, omits the dollar sign.
  String formatDollar([int? order]) {
    String out;
    if (order == null) {
      out = NumberFormat('\$#,##0.00').format(this);
    } else {
      out = NumberFormat('#,###').format(this);
    }
    if (out == "-0") out = "0";
    return out;
  }
}

extension IntDollarString on String {
  int? toIntDollar() {
    var str = replaceAll(RegExp(r"\s+|\+|\$|,"), "");

    if (str.isEmpty) return null;

    final isNegative = str[0] == '-';
    if (isNegative) str = str.substring(1);

    final parts = str.split('.');
    if (parts.length > 2) return null;

    final intPart = parts[0].isEmpty ? 0 : int.tryParse(parts[0]);
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

    if (isNegative) {
      return -intPart * 10000 - fracPart;
    } else {
      return intPart * 10000 + fracPart;
    }
  }
}

double getDollarAverage(Iterable<int> vals) {
  if (vals.isEmpty) return 0;
  int sum = 0;
  for (final x in vals) {
    sum += x;
  }
  return sum.asDollarDouble() / vals.length;
}

double getDollarAverage2<T>(Iterable<T> vals, int Function(T) valueMapper) {
  if (vals.isEmpty) return 0;
  int sum = 0;
  for (final x in vals) {
    sum += valueMapper(x);
  }
  return sum.asDollarDouble() / vals.length;
}

/// Formats [val] with dollar sign and commas. If [order] is not null, omits the dollar sign.
String formatDollar(double val, [int? order]) {
  return val.formatDollar(order);
}

String formatPercent(double val) {
  return '${NumberFormat('0.00').format(val * 100)}%';
}

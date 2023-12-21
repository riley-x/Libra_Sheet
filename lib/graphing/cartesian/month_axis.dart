import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_coordinate_space.dart';

final _monthFormat = DateFormat.MMM();
final _yearFormat = DateFormat.y();

class MonthAxis extends CartesianAxis {
  final List<DateTime> dates;
  final String Function(DateTime, bool concise)? dateToString;

  MonthAxis({
    required super.theme,
    required this.dates,
    this.dateToString,
    super.axisLoc,
  }) : super(
          min: -0.5,
          max: dates.length - 0.5,
          valToString: (val, [order = 0]) => _toString(dates, dateToString, val, order),
        );

  /// Prioritizes showing year changes on each January, and formats remaining ticks with a short
  /// month name.
  @override
  List<(double, TextPainter)> autoXLabels(
    CartesianCoordinateSpace coordSpace, [
    double? labelWidthEstimate,
  ]) {
    if (labels != null) return layoutLabels(labels!);
    if (dates.isEmpty) return [];
    if (dates.length <= 2) {
      return [
        for (int i = 0; i < dates.length; i++)
          (i.toDouble(), layoutLabel(_monthFormat.format(dates[i])))
      ];
    }

    /// Get estimate of label widths if not supplied
    labelWidthEstimate ??= layoutLabel("MMM").width;

    /// Get ideal step size
    final idealTickSeparation = labelWidthEstimate + 40;
    var idealNTicks = coordSpace.xAxis.pixelWidth.abs() / idealTickSeparation;
    if (idealNTicks < 2) idealNTicks = 2;
    final idealStepSize = coordSpace.xAxis.userWidth / idealNTicks;

    /// Get the month step size
    final stepSize = _roundToNearest12(idealStepSize);

    /// Find the starting point
    var currIndex = 0;
    while (currIndex < dates.length) {
      if ((dates[currIndex].month - 1) % stepSize == 0) break;
      currIndex++;
    }

    /// Create the labels
    List<(double, TextPainter)> out = [];
    for (currIndex; currIndex < dates.length; currIndex += stepSize) {
      final date = dates[currIndex];
      final text = (date.month == 1) ? _yearFormat.format(date) : _monthFormat.format(date);
      out.add((currIndex.toDouble(), layoutLabel(text)));
    }
    return out;
  }
}

String _toString(
    List<DateTime> dates, String Function(DateTime, bool)? dateToString, double val, int? order) {
  final i = val.round();
  if (i < 0 || i >= dates.length) return '';
  final date = dates[i];
  return dateToString?.call(date, order != null) ??
      (order != null ? DateFormat.yMMM().format(date) : DateFormat.yMMMM().format(date));
}

/// Returns the nearest divisor/multiple of 12.
int _roundToNearest12(double x) => switch (x) {
      <= 4.5 => max(1, x.round()),
      >= 4.5 && <= 8.5 => 6,
      >= 8.5 && <= 18 => 12,
      _ => 12 * ((x + 5) ~/ 12)
    };

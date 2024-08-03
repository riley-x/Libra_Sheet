import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/month_range_dialog.dart';

enum TimeFrameEnum { oneYear, twoYear, all, custom }

/// Class representing a time frame, used in time range selectors throughout the app. The primary
/// field is just a [TimeFrameEnum] in [selection], but includes extra memembers for dealing with
/// custom ranges.
class TimeFrame {
  final TimeFrameEnum selection;

  /// These are only used if [selection] == [TimeFrameEnum.custom]. Otherwise, a change in the
  /// global month list might make the below fields stale if i.e. a new month is added.
  final DateTime? customStart;
  final DateTime? customEndInclusive;

  const TimeFrame(
    this.selection, {
    this.customStart,
    this.customEndInclusive,
  }) : assert(selection != TimeFrameEnum.custom ||
            (customStart != null && customEndInclusive != null));

  /// Returns the start and end (exclusive) indices into [times] that match this time frame. Assumes
  /// that [times] is ordered by time, consists of month intervals, and in the case of
  /// [TimeFrameEnum.custom], that [times] contains [customStart] and [customEndInclusive]. If it
  /// doesn't, will default start to 0 and end to [times.length].
  (int, int) getRange(List<DateTime> times) {
    if (selection != TimeFrameEnum.custom) {
      return switch (selection) {
        TimeFrameEnum.oneYear => (max(0, times.length - 12), times.length),
        TimeFrameEnum.twoYear => (max(0, times.length - 24), times.length),
        TimeFrameEnum.all => (0, times.length),
        TimeFrameEnum.custom => (0, 0), // not entered but compiler dumb
      };
    } else {
      // These form the default values when we can't find the start and end dates.
      // This can happen if i.e. the app month list changes (but the range is not updated).
      int start = 0;
      int end = times.length;
      for (int i = 0; i < times.length; i++) {
        if (times[i].isAtSameMomentAs(customStart!)) start = i;
        if (times[i].isAtSameMomentAs(customEndInclusive!)) end = i + 1;
      }
      return (start, end);
    }
  }

  /// See [getRange], but returns the dates. End is inclusive!!!
  (DateTime?, DateTime?) getDateRange(List<DateTime> times) {
    return switch (selection) {
      TimeFrameEnum.oneYear => (times[max(0, times.length - 12)], null),
      TimeFrameEnum.twoYear => (times[max(0, times.length - 24)], null),
      TimeFrameEnum.all => (null, null),
      TimeFrameEnum.custom => (customStart, customEndInclusive)
    };
  }
}

/// Segmented button for a monthly time frame. Includes a "custom" option that upon clicking will
/// open a dialog to select a custom month range.
class TimeFrameSelector extends StatelessWidget {
  final List<DateTime> months;
  final TimeFrame selected;
  final Function(TimeFrame)? onSelect;
  final ButtonStyle? style;
  final bool enabled;

  const TimeFrameSelector({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
    this.style,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimeFrameEnum>(
      style: style,
      showSelectedIcon: false,
      segments: const <ButtonSegment<TimeFrameEnum>>[
        ButtonSegment(value: TimeFrameEnum.oneYear, label: Text("Year")),
        // ButtonSegment(value: TimeFrameEnum.twoYear, label: Text("2 Years")),
        ButtonSegment(value: TimeFrameEnum.all, label: Text("All")),
        ButtonSegment(value: TimeFrameEnum.custom, icon: Icon(Icons.date_range)),
      ],
      // this enables clicking on the custom button again, but we need to check empty below
      emptySelectionAllowed: true,
      selected: enabled ? {selected.selection} : {},
      onSelectionChanged: enabled
          ? (Set<TimeFrameEnum> newSelection) {
              final TimeFrameEnum it;
              if (newSelection.isEmpty) {
                // If custom, launch again
                if (selected.selection == TimeFrameEnum.custom) {
                  it = TimeFrameEnum.custom;
                }
                // Otherwise we're clicking on the same button, do nothing
                else {
                  return;
                }
              } else {
                // Since multiSelectionAllowed = false, only ever <= 1 elements.
                it = newSelection.first;
              }

              if (it != TimeFrameEnum.custom) {
                onSelect?.call(TimeFrame(it));
              } else {
                showMonthRangeDialog(
                  context: context,
                  months: months,
                  onSelect: (start, endInclusive) => onSelect?.call(TimeFrame(
                    it,
                    customStart: start,
                    customEndInclusive: endInclusive,
                  )),
                );
              }
            }
          : null,
    );
  }
}

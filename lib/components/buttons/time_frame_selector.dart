import 'dart:math';

import 'package:flutter/material.dart';

enum TimeFrameEnum { oneYear, twoYear, all, custom }

class TimeFrame {
  final TimeFrameEnum selection;

  /// These are only used if [selection] == [TimeFrameEnum.custom]. Otherwise, a change in the global
  /// month list might make the below fields stale if i.e. a new month is added.
  final DateTime? customStart;
  final DateTime? customEnd;

  TimeFrame(
    this.selection, {
    this.customStart,
    this.customEnd,
  });

  (int, int) getRange(List<DateTime> times) {
    if (selection != TimeFrameEnum.custom) {
      return switch (selection) {
        TimeFrameEnum.oneYear => (max(0, times.length - 12), times.length),
        TimeFrameEnum.twoYear => (max(0, times.length - 24), times.length),
        TimeFrameEnum.all => (0, times.length),
        TimeFrameEnum.custom => (0, 0),
      };
    } else {
      assert(customStart != null && customEnd != null);
      int start = 0;
      int end = 0;
      for (int i = 0; i < times.length; i++) {
        if (times[i].isAtSameMomentAs(customStart!)) start = i;
        if (times[i].isAtSameMomentAs(customEnd!)) end = i;
      }
      return (start, end);
    }
  }
}

/// Segmented button for a monthly time frame. Includes a "custom" option that upon clicking will
/// open a dialog to select a custom month range.
class TimeFrameSelector extends StatelessWidget {
  final List<DateTime> months;
  final TimeFrame selected;
  final Function(TimeFrame)? onSelect;

  const TimeFrameSelector({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      showSelectedIcon: false,
      segments: const <ButtonSegment<TimeFrameEnum>>[
        ButtonSegment(value: TimeFrameEnum.oneYear, label: Text("Year")),
        // ButtonSegment(value: TimeFrameEnum.twoYear, label: Text("2 Years")),
        ButtonSegment(value: TimeFrameEnum.all, label: Text("All")),
        ButtonSegment(value: TimeFrameEnum.custom, icon: Icon(Icons.date_range)),
      ],
      selected: <TimeFrameEnum>{selected.selection},
      onSelectionChanged: (Set<TimeFrameEnum> newSelection) {
        final it = newSelection.first;
        if (it != TimeFrameEnum.custom) {
          onSelect?.call(TimeFrame(it));
        } else {
          // TODO
        }
      },
    );
  }
}

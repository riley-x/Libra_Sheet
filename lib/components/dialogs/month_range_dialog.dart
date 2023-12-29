import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/date_time_utils.dart';

class MonthRangeDialog extends StatefulWidget {
  const MonthRangeDialog({
    super.key,
    required this.minDate,
    required this.maxDate,
    required this.onConfirmed,
  });

  final DateTime minDate;
  final DateTime maxDate;
  final Function(DateTime start, DateTime endInclusive)? onConfirmed;

  @override
  State<MonthRangeDialog> createState() => _MonthRangeDialogState();
}

class _MonthRangeDialogState extends State<MonthRangeDialog> {
  /// [GestureDetector.onPanStart] still triggers if the mouse moves minisculely during the tap.
  /// So we need to manually track the pointer position instead.
  ///   1. Store [onPointerDown]'s position in [dragStart].
  ///   2. The mouse is currently down and hovering over [dragStart]. We wait for one of the below.
  ///       (a) We receive a tap event; clear the drag and use the tap logic.
  ///       (b) The mouse moves to a different month. We watch this using each month's [onHover].
  ///           Initiate the drag and cancel the tap logic.
  DateTime? dragStart;
  bool dragInitiated = false;

  DateTime? start;
  DateTime? end;

  @override
  void initState() {
    super.initState();
  }

  /// 1. If [start] == [end], the tapped location forms the new end of the range.
  /// 2. Otherwise (nothing selected or a range selected already), set both [start] and [end] to
  ///    [time].
  void onTap(DateTime time) {
    stopDrag();
    setState(() {
      if (start != null && start == end) {
        final ordered = order(start!, time);
        start = ordered.$1;
        end = ordered.$2;
      } else {
        start = time;
        end = time;
      }
    });
  }

  void onPointerDown(PointerDownEvent event, DateTime time) {
    dragStart = time;
  }

  void stopDrag() {
    dragStart = null;
    dragInitiated = false;
  }

  void onHover(bool isHover, DateTime time) {
    if (!isHover || dragStart == null) return;
    if (time != dragStart || dragInitiated) {
      dragInitiated = true;
      final ordered = order(dragStart!, time);
      setState(() {
        start = ordered.$1;
        end = ordered.$2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.only(top: 20, bottom: 10),
      content: SingleChildScrollView(
        reverse: true, // this makes the scroll start at the bottom, doesn't change anything else
        padding: const EdgeInsets.symmetric(horizontal: 20), // so scroll bar is flush with dialog
        child: Column(
          children: [
            for (int year = widget.minDate.year; year <= widget.maxDate.year; year++)
              _YearBlock(year: year, state: this),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (start == null || end == null)
              ? null
              : () {
                  widget.onConfirmed?.call(start!, end!);
                  Navigator.pop(context, 'Ok');
                },
          child: const Text('Ok'),
        ),
      ],
    );
  }
}

class _YearBlock extends StatelessWidget {
  const _YearBlock({
    super.key,
    required this.year,
    required this.state,
  });

  final int year;
  final _MonthRangeDialogState state;

  static const rowHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => DateTime.utc(year, i + 1));
    return Column(
      children: [
        Text('$year', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 3),
        for (int start = 0; start < 12; start += 4)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  for (int i = start; i < start + 4; i++)
                    _MonthEntry(time: months[i], state: state),
                ],
              ),
            ),
          ),
        if (year < state.widget.maxDate.year) const SizedBox(height: 12),
      ],
    );
  }
}

class _MonthEntry extends StatelessWidget {
  const _MonthEntry({
    super.key,
    required this.time,
    required this.state,
  });

  final DateTime time;
  final _MonthRangeDialogState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled =
        time.compareTo(state.widget.minDate) >= 0 && time.compareTo(state.widget.maxDate) <= 0;
    final isStart = state.start == null ? false : time.isAtSameMomentAs(state.start!);
    final isEnd = state.end == null ? false : time.isAtSameMomentAs(state.end!);
    final highlighted = (state.start == null || state.end == null)
        ? false
        : time.compareTo(state.start!) > 0 && time.compareTo(state.end!) < 0;

    final borderRadius = (isStart && isEnd)
        ? BorderRadius.circular(_YearBlock.rowHeight / 2)
        : (isStart)
            ? const BorderRadius.horizontal(left: Radius.circular(_YearBlock.rowHeight / 2))
            : (isEnd)
                ? const BorderRadius.horizontal(right: Radius.circular(_YearBlock.rowHeight / 2))
                : BorderRadius.zero;

    final body = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: (isStart || isEnd)
            ? colorScheme.inversePrimary
            : (highlighted)
                ? colorScheme.inversePrimary.withAlpha(100)
                : null,
      ),
      child: Text(
        DateFormat.MMM().format(time),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: enabled ? colorScheme.onSurface : colorScheme.outline,
            ),
      ),
    );

    if (!enabled) return Expanded(child: body);

    return Expanded(
      child: Listener(
        onPointerDown: (it) => state.onPointerDown(it, time),
        onPointerUp: (it) => state.stopDrag(),
        onPointerCancel: (it) => state.stopDrag(),
        child: InkWell(
          onTap: () => state.onTap(time),
          onHover: (isHover) => state.onHover(isHover, time),
          borderRadius: BorderRadius.circular(_YearBlock.rowHeight / 2),
          child: body,
        ),
      ),
    );
  }
}

void showMonthRangeDialog({
  required BuildContext context,
  required List<DateTime> months,
  Function(bool confirmed)? onClose,
  Function(DateTime start, DateTime endInclusive)? onSelect,
}) {
  if (months.isEmpty) return;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return MonthRangeDialog(minDate: months.first, maxDate: months.last, onConfirmed: onSelect);
    },
  ).then((msg) {
    final confirmed = msg == 'Ok';
    onClose?.call(confirmed);
  });
}

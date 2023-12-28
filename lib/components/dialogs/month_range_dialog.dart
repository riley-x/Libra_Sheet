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
  /// NB: [GestureDetector.onPanStart] still triggers if the mouse moves minisculely during the tap.
  /// So we need to manually track the pointer position instead. We track [onPointerDown]'s position.
  /// If we receive a tap event, clear the drag. If we see the mouse moves to a different month
  /// (using each month's [onHover]), initiate the drag.
  DateTime? dragStart;
  bool dragInitiated = false;

  bool awaitingFirstTap = true;
  DateTime? start;
  DateTime? end;

  @override
  void initState() {
    super.initState();
  }

  /// For taps, the first tap sets the start time, and the second tap sets the end time (or vice
  /// versa).
  ///

  void onTap(DateTime time) {
    stopDrag();
    if (awaitingFirstTap) {
      setState(() {
        start = time;
        end = time;
      });
      awaitingFirstTap = false;
    } else if (start != null) {
      setState(() {
        if (time.compareTo(start!) <= 0) {
          start = time;
        } else {
          end = time;
        }
      });
      awaitingFirstTap = true;
    }
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
      /// Initiate drag; replace tap selection
      awaitingFirstTap = true;
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
      content: SingleChildScrollView(
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
          onPressed: () {
            if (start != null && end != null) {
              widget.onConfirmed?.call(start!, end!);
            }
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

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => DateTime.utc(year, i + 1));
    return Column(
      children: [
        Text('$year', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        for (int start = 0; start < 12; start += 4)
          SizedBox(
            height: 30,
            child: Row(
              children: [
                for (int i = start; i < start + 4; i++) _MonthEntry(time: months[i], state: state),
              ],
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

    final body = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
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
          onTap: (enabled) ? () => state.onTap(time) : null,
          // onTapDown: (it) => print('tap down $time'),
          // onTapCancel: () => print('tap cancel $time'),
          onHover: (enabled) ? (isHover) => state.onHover(isHover, time) : null,
          // child: GestureDetector(
          //   onPanStart: (enabled) ? (it) => state.onDragStart(time) : null,
          //   onPanEnd: (it) => state.onDragEnd(),
          child: body,
          // ),
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

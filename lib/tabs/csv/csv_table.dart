import 'package:flutter/material.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:provider/provider.dart';

class CsvTable extends StatelessWidget {
  const CsvTable({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    if (state.file == null || state.rawLines.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 100 * state.nCols) {
          return _ScrollingTable();
        } else {
          return const _FlexTable();
        }
      },
    );
  }
}

/// Scroll in both vertical and horizontal directions
class _ScrollingTable extends StatelessWidget {
  _ScrollingTable({super.key});

  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        notificationPredicate: (notif) => notif.depth == 1,
        child: SingleChildScrollView(
          controller: _vertical,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: const _Table(
              defaultColumnWidth: FixedColumnWidth(100),
            ),
          ),
        ),
      ),
    );
  }
}

/// Each column will expand to the same width
class _FlexTable extends StatelessWidget {
  const _FlexTable({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: _Table(defaultColumnWidth: FlexColumnWidth()),
    );
  }
}

/// The underlying data table
class _Table extends StatelessWidget {
  const _Table({super.key, required this.defaultColumnWidth});

  final TableColumnWidth defaultColumnWidth;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Table(
      border: TableBorder.all(width: 0.3, color: Theme.of(context).colorScheme.outline),
      defaultColumnWidth: defaultColumnWidth,
      children: [
        TableRow(
          children: [
            for (int i = 0; i < state.nCols; i++) _ColumnHeader(i),
          ],
        ),
        for (int row = 0; row < state.rawLines.length; row++)
          TableRow(
            decoration:
                (state.rowOk[row]) ? BoxDecoration(color: Colors.green.withAlpha(40)) : null,
            children: [
              for (int i = 0; i < state.nCols; i++)
                (i < state.rawLines[row].length)
                    ? _Cell(state.rawLines[row][i], i)
                    : const SizedBox(),
            ],
          ),
      ],
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final int column;

  const _ColumnHeader(this.column, {super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return ExcludeFocus(
      child: LibraDropdownMenu(
        selected: state.columnTypes[column].baseName,
        items: CsvField.fieldBaseNames,
        isDense: true,
        onChanged: (it) {
          if (it == CsvMatch.name) {
            showDialog(
              context: context,
              builder: (BuildContext context) => const _MatchDialog(),
            ).then((value) => (value != null) ? state.setColumn(column, CsvMatch(value)) : null);
          } else {
            state.setColumn(column, CsvField.fromName(it));
          }
        },
        builder: (it) {
          final field = CsvField.fromName(it);
          return Text(
            (field is CsvNone) ? '' : field.title,
            style: Theme.of(context).textTheme.labelMedium,
          );
        },
        selectedBuilder: (context, _) {
          final field = state.columnTypes[column];
          return Text(
            (field is CsvNone) ? '' : field.title,
            style: Theme.of(context).textTheme.labelMedium,
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, this.column, {super.key});

  final String text;
  final int column;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    final color = switch (state.tryParse(text, column)) {
      null => Theme.of(context).colorScheme.onBackground,
      true => Theme.of(context).colorScheme.onBackground,
      false => Theme.of(context).colorScheme.error,
    };
    // Highlighting the background of a cell is really annoying actually, because if every cell is
    // TableCellVerticalAlignment.fill, then the row will have 0 height.
    return TableCell(
      // verticalAlignment: (column > 0) ? TableCellVerticalAlignment.fill : null,
      child: Container(
        padding: const EdgeInsets.all(1),
        // color: color,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _MatchDialog extends StatefulWidget {
  const _MatchDialog({super.key});

  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Match'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, textController.text),
          child: const Text('Ok'),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "Filter for rows where this column matches the below text exactly (or is empty):"),
          const SizedBox(height: 15),
          LibraTextFormField(controller: textController),
        ],
      ),
    );
  }
}

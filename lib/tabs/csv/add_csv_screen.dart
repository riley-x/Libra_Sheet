import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/account_selection_menu.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:libra_sheet/tabs/csv/preview_transactions_screen.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

class AddCsvScreen extends StatelessWidget {
  const AddCsvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddCsvState(context.read<LibraAppState>()),
      builder: (context, child) {
        final state = context.watch<AddCsvState>();
        if (state.transactions.isEmpty) {
          return const _MainScreen();
        } else {
          return const PreviewTransactionsScreen();
        }
      },
    );
  }
}

class _MainScreen extends StatelessWidget {
  const _MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Column(
      children: [
        CommonBackBar(
          leftText: 'Add CSV',
          rightChild: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) => const _InstructionsDialog(),
            ),
            child: const Text(
              "Click Here for Instructions",
            ),
          ),
        ),
        const SizedBox(height: 10),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FixedColumnWidth(300),
          },
          children: [
            labelRow(
              context,
              'CSV File',
              const _FileCard(),
            ),
            rowSpacing,
            labelRow(
              context,
              'Account',
              AccountSelectionMenu(
                height: 35,
                selected: state.account,
                onChanged: state.setAccount,
              ),
              tooltip: "You can only input for one account at a time. If your CSV has\n"
                  "multiple accounts, try filtering your CSV first in Excel.",
            ),
            rowSpacing,
            labelRow(
              context,
              'Date Format',
              SizedBox(
                height: 30,
                child: FocusTextField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  hint: "Default",
                  onChanged: state.setDateFormat,
                ),
              ),
              tooltip: "If the default date parsing doesn't work, you can input\n"
                  "a manual date format here. The format code follows the\n"
                  "Java SimpleDateFormat patterns.",
              // TODO try to link to https://docs.unidata.ucar.edu/tds/4.6/adminguide/reference/collections/SimpleDateFormat.html
              // but richTooltip is possibly bugged?
            ),
            // Invert values
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1),
        const Expanded(child: _CsvGrid()),
        const _BottomBar(),
      ],
    );
  }
}

class _InstructionsDialog extends StatelessWidget {
  const _InstructionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // insetPadding: EdgeInsets.symmetric(horizontal: 80.0, vertical: 40.0),
      title: const Text('CSV Instuctions'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Ok'),
          child: const Text('Ok'),
        ),
      ],
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "After uploading a CSV file, if the app is unable to parse your CSV, you will need to"
                " manually set the column types. Use the drop-down menus at the top of the table."
                " The possible types are:",
              ),
              SizedBox(height: 15),
              _BulletRow(
                  "Name: The name of the transaction. You can have multiple name columns and they will be joined together."),
              _BulletRow(
                  "Date: The transaction date. If this isn't working, please change the format of the dates to MM/dd/yyyy in Excel."),
              _BulletRow(
                  "Amount: The value of the transaction. Make sure this has the correct sign (negative for expenses)."),
              _BulletRow(
                  "Note: You can have multiple note columns and the contents will be saved as a note in the transaction")
            ],
          ),
        ),
      ),
    );
//     Venmo: For Venmo CSVs, set this header on the
//               "Funding Source" column to filter out
//               payments originating from your bank.

// Fields that can't be parsed will be highlighted in red.
// Once you're ready, click the preview button at the
// bottom right.""",
//             child: Icon(Icons.question_mark),
//           ),
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow(this.msg, {super.key});

  final String msg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 40),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.circle, size: 6),
        ),
        const SizedBox(width: 15),
        Expanded(child: Text(msg))
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Container(
      height: 35,
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(70),
      child: Row(
        children: [
          const SizedBox(width: 10),
          if (state.errorMsg.isNotEmpty) ...[
            Icon(
              Icons.report_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              state.errorMsg,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          if (state.errorMsg.isEmpty && state.nRowsOk > 0)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.createTransactions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 5),
                      Text('Preview(${state.nRowsOk})'),
                      const Icon(
                        Icons.navigate_next,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return SizedBox(
      height: 35,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: state.selectFile,
          child: (state.file == null)
              ? Center(
                  child: Text(
                    'Select File',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(state.file!.name),
                ),
        ),
      ),
    );
  }
}

class _CsvGrid extends StatelessWidget {
  const _CsvGrid({super.key});

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
        selected: state.columnTypes[column],
        items: CsvField.fields,
        isDense: true,
        onChanged: (it) => state.setColumn(column, it),
        builder: (it) => Text(
          (it is CsvNone) ? '' : it?.title ?? '',
          style: Theme.of(context).textTheme.labelMedium,
        ),
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

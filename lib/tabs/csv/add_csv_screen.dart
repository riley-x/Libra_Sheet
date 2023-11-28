import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/account_selection_menu.dart';
import 'package:libra_sheet/components/selectors/libra_dropdown_menu.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

class AddCsvScreen extends StatelessWidget {
  const AddCsvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddCsvState(),
      child: const _MainScreen(),
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
        const CommonBackBar(leftText: 'Add CSV'),
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
                  onChanged: (it) => print(it),
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
                  onPressed: () {},
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

    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(width: 0.3),
        // border: TableBorder.all(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
        children: [
          TableRow(
            children: [
              for (int i = 0; i < state.nCols; i++) _ColumnHeader(i),
            ],
          ),
          for (final row in state.rawLines)
            TableRow(
              children: [
                for (int i = 0; i < state.nCols; i++) _Cell(row[i], i),
              ],
            ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final int column;

  const _ColumnHeader(this.column, {super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return LibraDropdownMenu(
      selected: state.columnTypes[column],
      items: CsvField.values,
      isDense: true,
      onChanged: (it) => state.setColumn(column, it),
      builder: (it) => Text(
        (it != CsvField.none) ? it?.title ?? '' : '',
        style: Theme.of(context).textTheme.labelMedium,
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
      null => null,
      true => null,
      false => Colors.red.shade800,
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

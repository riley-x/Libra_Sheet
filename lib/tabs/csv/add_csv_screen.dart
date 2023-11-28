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
        const Expanded(child: _CsvGrid()),
      ],
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
        children: [
          TableRow(
            children: [
              for (int i = 0; i < state.nCols; i++) _ColumnHeader(i),
            ],
          ),
          for (final row in state.rawLines)
            TableRow(
              children: [
                for (final item in row)
                  Padding(
                    padding: const EdgeInsets.all(1),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
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
        it?.name ?? '',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

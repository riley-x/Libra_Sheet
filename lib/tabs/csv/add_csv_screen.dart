import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
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
    return Column(
      children: [
        const CommonBackBar(leftText: 'Add CSV'),
        const SizedBox(height: 15),
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
              _FileCard(),
            ),
            rowSpacing,
          ],
        ),
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

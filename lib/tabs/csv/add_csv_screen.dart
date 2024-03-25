import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/menus/account_selection_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:libra_sheet/tabs/csv/csv_table.dart';
import 'package:libra_sheet/tabs/csv/preview_transactions_screen.dart';
import 'package:libra_sheet/components/table_form_utils.dart';
import 'package:provider/provider.dart';

class AddCsvScreen extends StatelessWidget {
  const AddCsvScreen({super.key, this.initialAccount});

  final Account? initialAccount;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddCsvState(
        appState: context.read<LibraAppState>(),
        account: initialAccount,
      ),
      builder: (context, child) {
        final state = context.watch<AddCsvState>();
        if (state.previewScreen) {
          return const PreviewTransactionsScreen();
        } else {
          return const _MainScreen();
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
            // rowSpacing,
            // labelRow(
            //   context,
            //   'Date Format',
            //   SizedBox(
            //     height: 30,
            //     child: FocusTextField(
            //       style: Theme.of(context).textTheme.bodyMedium,
            //       hint: "Default",
            //       onChanged: state.setDateFormat,
            //     ),
            //   ),
            //   tooltip: "If the default date parsing doesn't work, you can input\n"
            //       "a manual date format here. The format code follows the\n"
            //       "Java SimpleDateFormat patterns.",
            //   // TODO try to link to https://docs.unidata.ucar.edu/tds/4.6/adminguide/reference/collections/SimpleDateFormat.html
            //   // but richTooltip is possibly bugged?
            // ),
            // Invert values
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1),
        const Expanded(child: CsvTable()),
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
                'Click the "Select File" button to upload a CSV! The app will try to automatically parse it.'
                "\n\nIf it is unable to, you will need to manually set the column types. Use the drop-down menus at the top of the table."
                " The possible types are:",
              ),
              SizedBox(height: 20),
              Text("Mandatory columns:"),
              SizedBox(height: 8),
              _BulletRow(
                  "Name: The name of the transaction. You can have multiple name columns and they will be joined together."),
              _BulletRow(
                  "Date: The transaction date. If this isn't working, please change the format of the dates to MM/dd/yyyy in Excel."),
              _BulletRow(
                  "Amount: The value of the transaction. Make sure this has the correct sign (negative for expenses)."),
              _BulletRow(
                  "Negative Amount: The inverted value of the transaction. So expenses are positive and credits are negative (credit card statements often are inverted)."),
              SizedBox(height: 20),
              Text("Utility columns:"),
              SizedBox(height: 8),
              _BulletRow(
                  "Note: You can have multiple note columns and the contents will be saved as a note in the transaction."),
              _BulletRow(
                  "Match: Filter for rows where the column matches a specific string, or is empty."),
              _BulletRow(
                  'Debit/Credit: If your CSV only has positive values and uses a column with "Debit" or "Credit" strings to distinguish transactions, use this column type on that latter column.')
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
          if (state.errorMsg.isEmpty && state.transactions.isNotEmpty)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.previewTransactions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 5),
                      Text('Preview(${state.transactions.length})'),
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
          borderRadius: BorderRadius.circular(8),
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

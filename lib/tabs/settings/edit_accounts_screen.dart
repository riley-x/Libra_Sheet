import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/libra_dropdown_menu.dart';
import 'package:libra_sheet/components/show_color_picker.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:libra_sheet/tabs/settings/settings_tab_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

/// Settings screen for editing accounts. This lists the accounts, and clicking them switches to an
/// editor form.
class EditAccountsScreen extends StatelessWidget {
  const EditAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<EditAccountState>();

    /// The IndexedStack preserves the scroll state of the ListView I think...
    return IndexedStack(
      index: (state.isFocused) ? 0 : 1,
      children: [
        _EditAccount(
          /// this prevents the IndexedStack from reusing the form editor, which causes a flicker
          key: ObjectKey(state.focused),
        ),
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              for (final acc in appState.accounts)
                AccountRow(
                  account: acc,
                  onTap: (it) => state.setFocus(it),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => state.setFocus(null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _EditAccount extends StatelessWidget {
  const _EditAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditAccountState>();
    return Column(
      children: [
        const SizedBox(height: 10),
        Form(
          key: state.formKey,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FixedColumnWidth(250),
            },
            children: [
              labelRow(
                context,
                'Name',
                LibraTextFormField(
                  initial: state.focused?.name,
                  validator: (it) => null,
                  onSave: (it) => state.saveSink.name = it ?? '',
                ),
              ),
              rowSpacing,
              labelRow(
                context,
                'Type',
                LibraDropdownFormField<AccountType>(
                  initial: state.focused?.type,
                  items: AccountType.values,
                  builder: (it) =>
                      Text(it.toString(), style: Theme.of(context).textTheme.bodyMedium),
                  height: 35,
                  onSave: (it) => state.saveSink.type = it!,
                ),
                tooltip: "This is used mostly for organizing similar accounts together."
                    "\nLiability accounts should only have negative values though.",
              ),
              rowSpacing,
              labelRow(
                context,
                'Description',
                LibraTextFormField(
                  initial: state.focused?.description,
                  validator: (it) => null,
                  onSave: (it) => state.saveSink.description = it ?? '',
                ),
              ),
              rowSpacing,
              labelRow(
                context,
                'CSV Format',
                LibraTextFormField(
                  initial: state.focused?.csvFormat,
                  validator: (it) => null,
                  onSave: (it) => state.saveSink.csvFormat = it ?? '',
                ),
                tooltip: "TODO write this tooltip", // TODO
              ),
              rowSpacing,
              labelRow(
                context,
                'Color',
                Container(
                  height: 30,
                  color: state.saveSink.color,
                  child: InkWell(
                    onTap: () => showColorPicker(
                      context: context,
                      initialColor: state.saveSink.color,
                      onColorChanged: (it) => state.saveSink.color = it,
                      onClose: state.notifyListeners,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        FormButtons(
          allowDelete: state.focused != null,
          onCancel: state.clearFocus,
          onReset: state.reset,
          onSave: state.save,
        ),
      ],
    );
  }
}

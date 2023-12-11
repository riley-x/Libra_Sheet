import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/components/dialogs/show_color_picker.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

import '../../components/cards/account_card.dart';

/// State for the accounts submenu in the settings tab
class EditAccountState extends ChangeNotifier {
  final LibraAppState appState;

  EditAccountState(this.appState);

  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;
  Account? focused;

  /// Save sinks for the FormFields
  AccountType type = AccountType.bank;
  String name = "";
  String description = "";

  /// UI states (and save values)
  Color color = Colors.blue;

  void _init() {
    if (focused == null) {
      color = Colors.blue;
    } else {
      /// Only color needs to be set here I think? But just in case the original values get overriden
      type = focused!.type;
      name = focused!.name;
      description = focused!.description;
      color = focused!.color;
    }
  }

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(Account? it) {
    focused = it;
    isFocused = true;
    reset();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void clearFocus() {
    isFocused = false;
    notifyListeners();
  }

  void delete() {
    // TODO
  }

  void save() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      if (focused == null) {
        final acc = Account(type: type, name: name, description: description, color: color);
        appState.accounts.add(acc);
      } else {
        focused!.type = type;
        focused!.name = name;
        focused!.description = description;
        focused!.color = color;
        appState.accounts.notifyUpdate(focused!);
      }
      clearFocus();
    }
  }
}

/// Settings screen for editing accounts. This lists the accounts, and clicking them switches to an
/// editor form.
class EditAccountsScreen extends StatelessWidget {
  const EditAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountState>().list;
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
              for (final acc in accounts)
                AccountCard(
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

/// Account details form
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
                  onSave: (it) => state.name = it ?? '',
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
                  onSave: (it) => state.type = it!,
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
                  onSave: (it) => state.description = it ?? '',
                ),
              ),
              // rowSpacing,
              // labelRow(
              //   context,
              //   'CSV Format',
              //   LibraTextFormField(
              //     initial: state.focused?.csvFormat,
              //     validator: (it) => null,
              //     onSave: (it) => state.saveSink.csvFormat = it ?? '',
              //   ),
              //   tooltip: "Instructions on how to parse the CSV.\n"
              //       "You can leave this blank for new accounts.",
              // ),
              rowSpacing,
              labelRow(
                context,
                'Color',
                Container(
                  height: 30,
                  color: state.color,
                  child: InkWell(
                    onTap: () => showColorPicker(
                      context: context,
                      initialColor: state.color,
                      onColorChanged: (it) => state.color = it,
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
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
          showDelete: state.focused != null,
          onDelete: null, // TODO
          onCancel: state.clearFocus,
          onReset: state.reset,
          onSave: state.save,
        ),
      ],
    );
  }
}

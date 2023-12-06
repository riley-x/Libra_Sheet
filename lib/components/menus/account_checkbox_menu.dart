import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/menus/account_menu_builder.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/title_row.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:provider/provider.dart';

class AccountChips extends StatelessWidget {
  const AccountChips({
    super.key,
    required this.selected,
    this.onChanged,
    this.whenChanged,
    this.style,
  });

  final TextStyle? style;
  final Set<Account> selected;
  final Function(Account, bool?)? onChanged;

  /// Can update [selected] in-place using default behavior. This callback must be set to be
  /// notified of the change, and [onChaged] must be null.
  final Function(Account, bool?)? whenChanged;

  void defaultOnChanged(Account account, bool? val) {
    if (onChanged != null) {
      onChanged!(account, val);
      return;
    }
    if (whenChanged == null) return;
    if (val == true) {
      selected.add(account);
    } else {
      selected.remove(account);
    }
    whenChanged!.call(account, val);
  }

  @override
  Widget build(BuildContext context) {
    assert(onChanged == null || whenChanged == null);
    final accounts = context.watch<LibraAppState>().accounts;
    return Column(
      children: [
        TitleRow(
          title: Text("Accounts", style: style ?? Theme.of(context).textTheme.titleMedium),
          right: AccountCheckboxMenu(
            accounts: accounts,
            isChecked: selected.contains,
            onChanged: defaultOnChanged,
          ),
        ),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(
              'All',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
              // color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        if (selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final acc in selected)
                LibraChip(
                  acc.name,
                  color: acc.color,
                  onTap: () => defaultOnChanged(acc, false),
                ),
            ],
          ),
      ],
    );
  }
}

class AccountCheckboxMenu extends StatelessWidget {
  const AccountCheckboxMenu({
    super.key,
    required this.accounts,
    required this.isChecked,
    required this.onChanged,
  });

  final List<Account> accounts;
  final bool? Function(Account acc)? isChecked;
  final Function(Account acc, bool? val)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownCheckboxMenu<Account>(
      icon: Icons.add,
      items: accounts,
      builder: accountMenuBuilder,
      isChecked: isChecked,
      onChanged: onChanged,
    );
  }
}

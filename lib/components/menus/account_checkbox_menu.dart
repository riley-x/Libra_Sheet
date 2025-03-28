import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/menus/account_menu_builder.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/title_row.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
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
  final Function(AccountOrHeader, bool?)? onChanged;

  /// Can update [selected] in-place using default behavior. This callback must be set to be
  /// notified of the change, and [onChaged] must be null.
  final Function(AccountOrHeader, bool?)? whenChanged;

  @override
  Widget build(BuildContext context) {
    assert(onChanged == null || whenChanged == null);
    final accounts = context.watch<AccountState>().list;

    bool isChecked(AccountOrHeader account) {
      if (account.account != null) {
        return selected.contains(account.account);
      } else {
        return accounts.every((acc) => acc.type != account.header || selected.contains(acc));
      }
    }

    void defaultOnChanged(AccountOrHeader account, bool? val) {
      if (onChanged != null) {
        onChanged!(account, val);
        return;
      }
      if (whenChanged == null) return;

      if (account.header != null) {
        if (isChecked(account)) {
          selected.removeWhere((acc) => acc.type == account.header);
        } else {
          for (final acc in accounts) {
            if (acc.type == account.header) selected.add(acc);
          }
        }
      } else {
        if (val == true) {
          selected.add(account.account!);
        } else {
          selected.remove(account.account!);
        }
      }

      whenChanged!.call(account, val);
    }

    return Column(
      children: [
        TitleRow(
          title: Text("Accounts", style: style ?? Theme.of(context).textTheme.titleMedium),
          right: AccountCheckboxMenu(
            accounts: accounts,
            isChecked: isChecked,
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
                  onTap: () => defaultOnChanged(AccountOrHeader.account(acc), false),
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
  final bool? Function(AccountOrHeader acc)? isChecked;
  final Function(AccountOrHeader acc, bool? val)? onChanged;

  static const groupingMinTotal = 9;
  static const groupingMinPerGroup = 3;

  @override
  Widget build(BuildContext context) {
    final cashAccounts = <Account>[];
    final bankAccounts = <Account>[];
    final investmentAccounts = <Account>[];
    final liabilityAccounts = <Account>[];

    var doGrouping = false;
    if (accounts.length >= groupingMinTotal) {
      for (final account in accounts) {
        final accountList = switch (account.type) {
          AccountType.cash => cashAccounts,
          AccountType.bank => bankAccounts,
          AccountType.investment => investmentAccounts,
          AccountType.liability => liabilityAccounts,
        };
        accountList.add(account);
      }

      final listsWithMin = (cashAccounts.length >= groupingMinPerGroup ? 1 : 0) +
          (bankAccounts.length >= groupingMinPerGroup ? 1 : 0) +
          (investmentAccounts.length >= groupingMinPerGroup ? 1 : 0) +
          (liabilityAccounts.length >= groupingMinPerGroup ? 1 : 0);
      doGrouping = listsWithMin >= 2;
    }

    final items = doGrouping
        ? [
            if (cashAccounts.isNotEmpty) AccountOrHeader.header(AccountType.cash),
            for (final account in cashAccounts) AccountOrHeader.account(account),
            if (bankAccounts.isNotEmpty) AccountOrHeader.header(AccountType.bank),
            for (final account in bankAccounts) AccountOrHeader.account(account),
            if (investmentAccounts.isNotEmpty) AccountOrHeader.header(AccountType.investment),
            for (final account in investmentAccounts) AccountOrHeader.account(account),
            if (liabilityAccounts.isNotEmpty) AccountOrHeader.header(AccountType.liability),
            for (final account in liabilityAccounts) AccountOrHeader.account(account),
          ]
        : [
            for (final account in accounts) AccountOrHeader.account(account),
          ];

    return DropdownCheckboxMenu<AccountOrHeader>(
      icon: Icons.add,
      items: items,
      builder: (context, account) =>
          accountOrHeaderMenuBuilder(context, account, containsHeaders: doGrouping),
      isChecked: isChecked,
      onChanged: onChanged,
    );
  }
}

class AccountOrHeader {
  final Account? account;
  final AccountType? header;

  AccountOrHeader.account(this.account) : header = null;
  AccountOrHeader.header(this.header) : account = null;
}

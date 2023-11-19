import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';

/// Lays out a set of filter chips for each account.
class AccountFilterChips extends StatelessWidget {
  final List<Account> accounts;
  final bool Function(Account account, int index)? selected;
  final Function(Account account, int index, bool selected)? onSelected;

  const AccountFilterChips({
    super.key,
    required this.accounts,
    this.selected,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: <Widget>[
        for (int i = 0; i < accounts.length; i++)
          FilterChip(
            label: Text(accounts[i].name),
            selected: selected?.call(accounts[i], i) ?? false,
            onSelected: (selected) {
              onSelected?.call(accounts[i], i, selected);
            },
            showCheckmark: false,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
      ],
    );
  }
}

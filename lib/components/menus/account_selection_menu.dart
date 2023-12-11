import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/account_menu_builder.dart';
import 'package:libra_sheet/components/menus/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:provider/provider.dart';

/// Dropdown button for filtering by an account
class AccountSelectionMenu extends StatelessWidget {
  final Account? selected;
  final bool includeNone;
  final Function(Account?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  const AccountSelectionMenu({
    super.key,
    this.selected,
    this.onChanged,
    this.includeNone = false,
    this.borderRadius,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    List<Account?> items = context.watch<AccountState>().list;
    if (includeNone) items = [null, ...items];
    return LibraDropdownMenu<Account?>(
      selected: selected,
      items: items,
      builder: (cat) => accountMenuBuilder(context, cat),
      onChanged: onChanged,
      borderRadius: borderRadius,
      height: height,
    );
  }
}

/// Dropdown button for filtering by an account, wrapped in a FormField
class AccountSelectionFormField extends StatelessWidget {
  const AccountSelectionFormField({
    super.key,
    this.initial,
    this.includeNone = false,
    this.borderRadius,
    this.height = 30,
    this.onSave,
  });

  final Account? initial;
  final bool includeNone;
  final Function(Account?)? onSave;
  final BorderRadius? borderRadius;
  final double height;

  @override
  Widget build(BuildContext context) {
    List<Account?> items = context.watch<AccountState>().list;
    if (includeNone) items = [null, ...items];
    return LibraDropdownFormField<Account?>(
      initial: initial,
      items: items,
      builder: (cat) => accountMenuBuilder(context, cat),
      borderRadius: borderRadius,
      height: height,
      onSave: onSave,
    );
  }
}

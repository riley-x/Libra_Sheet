import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/account_menu_builder.dart';
import 'package:libra_sheet/components/menus/dropdown_selector.dart';
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
    return DropdownSelector<Account?>(
      selected: selected,
      items: items,
      builder: (context, cat) => accountMenuBuilder(context, cat),
      onSelected: onChanged,
      borderRadius: borderRadius,
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
    this.nullText,
    this.validator,
  });

  final Account? initial;
  final bool includeNone;
  final Function(Account?)? onSave;
  final BorderRadius? borderRadius;
  final double height;
  final String? nullText;
  final String? Function(Account?)? validator;

  @override
  Widget build(BuildContext context) {
    List<Account?> items = context.watch<AccountState>().list;
    if (includeNone) items = [null, ...items];
    return SizedBox(
      height: height,
      child: LibraDropdownFormField<Account?>(
        initial: initial,
        items: items,
        builder: (context, acc) => accountMenuBuilder(context, acc, nullText: nullText),
        borderRadius: borderRadius,
        onSave: onSave,
        validator: validator,
      ),
    );
  }
}

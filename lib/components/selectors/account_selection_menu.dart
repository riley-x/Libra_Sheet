import 'package:flutter/material.dart';
import 'package:libra_sheet/components/selectors/libra_dropdown_menu.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:provider/provider.dart';

Widget _builder(BuildContext context, Account? acc) {
  return Text(
    acc?.name ?? 'None',
    style: Theme.of(context).textTheme.labelLarge,
  );
}

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
    List<Account?> items = context.watch<LibraAppState>().accounts;
    if (includeNone) items = <Account?>[null] + items;
    return LibraDropdownMenu<Account?>(
      selected: selected,
      items: items,
      builder: (cat) => _builder(context, cat),
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
    List<Account?> items = context.watch<LibraAppState>().accounts;
    if (includeNone) items = <Account?>[null] + items;
    return LibraDropdownFormField<Account?>(
      initial: initial,
      items: items,
      builder: (cat) => _builder(context, cat),
      borderRadius: borderRadius,
      height: height,
      onSave: onSave,
    );
  }
}

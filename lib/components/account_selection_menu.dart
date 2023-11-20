import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

/// Dropdown button for filtering by an account
class AccountSelectionMenu extends StatelessWidget {
  final Account? selected;
  final bool includeNone;
  final Function(Account?)? onChanged;
  const AccountSelectionMenu({
    super.key,
    this.selected,
    this.onChanged,
    this.includeNone = true,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 30),
      child: Theme(
        data: Theme.of(context).copyWith(
          focusColor: Theme.of(context).colorScheme.secondaryContainer,
          hoverColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(128),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Account?>(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            borderRadius: BorderRadius.circular(10),
            focusColor: Theme.of(context).colorScheme.secondaryContainer,
            value: selected,
            items: [
              if (includeNone)
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    'None',
                    style: Theme.of(context).textTheme.labelLarge, // match with SegmentedButton
                  ),
                ),
              for (final account in appState.accounts)
                DropdownMenuItem(
                  value: account,
                  child: Text(
                    account.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

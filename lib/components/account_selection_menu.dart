import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:provider/provider.dart';

/// Dropdown button for filtering by an account
/// P.S. Don't try switching to a DropdownButtonFormField -- a lot of trouble getting the underline
/// hidden.
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
    final appState = context.watch<LibraAppState>();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: Theme(
        data: Theme.of(context).copyWith(
          /// this is the color used for the currently selected item in the menu itself
          focusColor: Theme.of(context).colorScheme.secondaryContainer,
          // hoverColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(128),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Account?>(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            borderRadius: borderRadius ?? BorderRadius.circular(10),
            focusColor: Theme.of(context)
                .colorScheme
                .background, // this is the color of the button when it has keyboard focus
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
    return FormField<Account?>(
      initialValue: initial,
      builder: (state) {
        final widget = AccountSelectionMenu(
          selected: state.value,
          includeNone: includeNone,
          height: height,
          borderRadius: borderRadius,
          onChanged: state.didChange,
        );
        if (state.hasError) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: widget,
          );
        } else {
          return widget;
        }
      },
      validator: (value) => (value == null) ? '' : null,
      onSaved: onSave,
    );
  }
}

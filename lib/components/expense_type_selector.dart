import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';

/// Segmented button for the expense type (income vs expense).
class ExpenseTypeSelector extends StatelessWidget {
  final ExpenseType selected;
  final Function(ExpenseType)? onSelect;

  const ExpenseTypeSelector(this.selected, {super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      showSelectedIcon: false,
      segments: const <ButtonSegment<ExpenseType>>[
        ButtonSegment(value: ExpenseType.income, label: Text("Income")),
        ButtonSegment(value: ExpenseType.expense, label: Text("Expenses")),
      ],
      selected: <ExpenseType>{selected},
      onSelectionChanged: (Set<ExpenseType> newSelection) {
        onSelect?.call(newSelection.first);
      },
    );
  }
}

/// Segmented button for the expense type (income vs expense). Allows selecting both or none.
class ExpenseTypeFilter extends StatelessWidget {
  final Set<ExpenseType> selected;
  final Function(Set<ExpenseType>)? onSelect;

  const ExpenseTypeFilter(
    this.selected, {
    super.key,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      showSelectedIcon: false,
      multiSelectionEnabled: true,
      emptySelectionAllowed: true,
      segments: const <ButtonSegment<ExpenseType>>[
        ButtonSegment(value: ExpenseType.income, label: Text("Income")),
        ButtonSegment(value: ExpenseType.expense, label: Text("Expenses")),
      ],
      selected: selected,
      onSelectionChanged: onSelect,
    );
  }
}

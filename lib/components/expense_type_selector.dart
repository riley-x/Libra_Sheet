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
        ButtonSegment(value: ExpenseType.expense, label: Text("Expense")),
      ],
      selected: <ExpenseType>{selected},
      onSelectionChanged: (Set<ExpenseType> newSelection) {
        onSelect?.call(newSelection.first);
      },
    );
  }
}

/// Segmented button for income , expense, or both.
class ExpenseFilterTypeSelector extends StatelessWidget {
  final ExpenseFilterType selected;
  final Function(ExpenseFilterType)? onSelect;

  const ExpenseFilterTypeSelector(this.selected, {super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      showSelectedIcon: false,
      segments: const <ButtonSegment<ExpenseFilterType>>[
        ButtonSegment(value: ExpenseFilterType.all, label: Text("All")),
        ButtonSegment(value: ExpenseFilterType.income, label: Text("Income")),
        ButtonSegment(value: ExpenseFilterType.expense, label: Text("Expense")),
      ],
      selected: <ExpenseFilterType>{selected},
      onSelectionChanged: (Set<ExpenseFilterType> newSelection) {
        onSelect?.call(newSelection.first);
      },
    );
  }
}

/// Segmented button for the expense type (income vs expense). Allows selecting both or none.
class ExpenseTypeFilter extends StatelessWidget {
  final Set<ExpenseType> selected;
  final Function(Set<ExpenseType>)? onSelect;

  const ExpenseTypeFilter(this.selected, {super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      showSelectedIcon: false,
      multiSelectionEnabled: true,
      emptySelectionAllowed: true,
      segments: const <ButtonSegment<ExpenseType>>[
        ButtonSegment(value: ExpenseType.income, label: Text("Income")),
        ButtonSegment(value: ExpenseType.expense, label: Text("Expense")),
      ],
      selected: selected,
      onSelectionChanged: onSelect,
    );
  }
}

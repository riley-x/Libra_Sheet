import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the category tab.
class CategoryTabFilters extends StatelessWidget {
  const CategoryTabFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "Options",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text("Type"),
        const SizedBox(height: 5),
        const _ExpenseTypeSelector(),

        const SizedBox(height: 15),
        const Text("Time Frame"),
        const SizedBox(height: 5),
        const _TimeFrameSelector(),

        const SizedBox(height: 15),
        const Text("Account"),
        const SizedBox(height: 5),
        const _AccountFilterMenu(),

        // TODO add Tag filter

        const SizedBox(height: 15),
        const Text("Sub-Categories"),
        const SizedBox(height: 5),
        const _SubCategoryChip(),
      ],
    );
  }
}

/// Segmented button for the expense type
class _ExpenseTypeSelector extends StatelessWidget {
  const _ExpenseTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    return SegmentedButton(
      showSelectedIcon: false,
      segments: const <ButtonSegment<ExpenseType>>[
        ButtonSegment(value: ExpenseType.income, label: Text("Income")),
        ButtonSegment(value: ExpenseType.expense, label: Text("Expenses")),
      ],
      selected: <ExpenseType>{state.expenseType},
      onSelectionChanged: (Set<ExpenseType> newSelection) {
        state.setExpenseType(newSelection.first);
      },
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    return SegmentedButton<CategoryTabTimeFrame>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<CategoryTabTimeFrame>>[
        ButtonSegment<CategoryTabTimeFrame>(
          value: CategoryTabTimeFrame.current,
          label: Text('Month'),
        ),
        ButtonSegment<CategoryTabTimeFrame>(
          value: CategoryTabTimeFrame.oneYear,
          label: Text('Year'),
        ),
        ButtonSegment<CategoryTabTimeFrame>(
          value: CategoryTabTimeFrame.all,
          label: Text('All'),
        ),
      ],
      selected: <CategoryTabTimeFrame>{state.timeFrame},
      onSelectionChanged: (Set<CategoryTabTimeFrame> newSelection) {
        state.setTimeFrame(newSelection.first);
      },
    );
  }
}

/// Dropdown button for filtering by an account
class _AccountFilterMenu extends StatelessWidget {
  const _AccountFilterMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final categoryTabState = context.watch<CategoryTabState>();
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
            value: categoryTabState.account,
            items: [
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
            onChanged: (Account? value) {
              categoryTabState.setAccount(value);
            },
          ),
        ),
      ),
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  const _SubCategoryChip({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTabState = context.watch<CategoryTabState>();
    return FilterChip(
      label: const Text('Show'),
      selected: categoryTabState.showSubCategories,
      onSelected: categoryTabState.shouldShowSubCategories,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

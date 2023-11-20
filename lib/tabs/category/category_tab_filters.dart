import 'package:flutter/material.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

import '../../components/account_selection_menu.dart';

/// Creates the column that holds all the option selectors for the category tab.
class CategoryTabFilters extends StatelessWidget {
  const CategoryTabFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
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
        ExpenseTypeSelector(
          state.expenseType,
          onSelect: (it) {
            state.setExpenseType(it);
          },
        ),

        const SizedBox(height: 15),
        const Text("Time Frame"),
        const SizedBox(height: 5),
        const _TimeFrameSelector(),

        const SizedBox(height: 15),
        const Text("Account"),
        const SizedBox(height: 5),
        AccountSelectionMenu(
          includeNone: true,
          selected: state.account,
          onChanged: (Account? value) {
            state.setAccount(value);
          },
        ),

        // TODO add Tag filter

        const SizedBox(height: 15),
        const Text("Show Sub-Categories"),
        const SizedBox(height: 5),
        const _SubCategorySwitch(),
      ],
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

class _SubCategorySwitch extends StatelessWidget {
  const _SubCategorySwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTabState = context.watch<CategoryTabState>();
    return Switch(
      value: categoryTabState.showSubCategories,
      onChanged: categoryTabState.shouldShowSubCategories,
      activeColor: Theme.of(context).colorScheme.surfaceTint,
      activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}


  // @override
  // Widget build(BuildContext context) {
  //   final categoryTabState = context.watch<CategoryTabState>();
  //   return FilterChip(
  //     label: const Text('Show'),
  //     selected: categoryTabState.showSubCategories,
  //     onSelected: categoryTabState.shouldShowSubCategories,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //   );
  // }

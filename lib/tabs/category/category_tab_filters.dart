import 'package:flutter/material.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/components/selectors/account_checkbox_menu.dart';
import 'package:libra_sheet/components/selectors/tag_checkbox_menu.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the category tab.
class CategoryTabFilters extends StatelessWidget {
  const CategoryTabFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CategoryTabState>();
    return Column(
      children: [
        /// Title
        const SizedBox(height: 10),
        Text(
          "Options",
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        /// Type
        const SizedBox(height: 10),
        const Text("Type"),
        const SizedBox(height: 5),
        ExpenseTypeSelector(
          state.expenseType,
          onSelect: (it) {
            state.setExpenseType(it);
          },
        ),

        /// Time frame
        const SizedBox(height: 15),
        const Text("Time Frame"),
        const SizedBox(height: 5),
        const _TimeFrameSelector(),

        /// Accounts
        const SizedBox(height: 15),
        AccountChips(
          selected: state.accounts,
          style: Theme.of(context).textTheme.bodyMedium,
          whenChanged: (_, __) => state.loadValues(),
        ),

        /// Tags
        // TODO not trivial
        // const SizedBox(height: 15),
        // TagFilterSection(
        //   selected: state.tags,
        //   headerStyle: Theme.of(context).textTheme.bodyMedium,
        //   whenChanged: (_, __) => state.loadValues(),
        // ),

        /// Sub-cats switch
        const SizedBox(height: 20),
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

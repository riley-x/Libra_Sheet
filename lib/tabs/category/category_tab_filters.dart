import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
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
        const Row(
          children: [
            Expanded(child: Text("Show Sub-Categories")),
            _SubCategorySwitch(),
          ],
        ),

        // Averages switch
        const SizedBox(height: 5),
        const Row(
          children: [
            Expanded(child: Text("Show Averages")),
            _AveragesSwitch(),
          ],
        ),
      ],
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});
  static final _format = DateFormat.yMMM();

  @override
  Widget build(BuildContext context) {
    final monthList = context.watch<LibraAppState>().monthList;
    final state = context.watch<CategoryTabState>();

    String getText() {
      if (state.timeFrameMonths == null) return '';
      if (state.timeFrameMonths!.$1.isAtSameMomentAs(state.timeFrameMonths!.$2)) {
        return _format.format(state.timeFrameMonths!.$1);
      } else {
        return "${_format.format(state.timeFrameMonths!.$1)} - ${_format.format(state.timeFrameMonths!.$2)}";
      }
    }

    return Column(
      children: [
        TimeFrameSelector(
          months: monthList,
          selected: state.timeFrame,
          onSelect: state.setTimeFrame,
        ),
        const SizedBox(height: 3),
        Text(getText(), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SubCategorySwitch extends StatelessWidget {
  const _SubCategorySwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTabState = context.watch<CategoryTabState>();
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: categoryTabState.showSubCategories,
        onChanged: categoryTabState.shouldShowSubCategories,
        activeColor: Theme.of(context).colorScheme.surfaceTint,
        activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}

class _AveragesSwitch extends StatelessWidget {
  const _AveragesSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTabState = context.watch<CategoryTabState>();
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: categoryTabState.showAverages,
        onChanged: categoryTabState.shouldShowAverages,
        activeColor: Theme.of(context).colorScheme.surfaceTint,
        activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}

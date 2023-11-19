import 'package:flutter/material.dart';
import 'package:libra_sheet/components/account_filter_chips.dart';
import 'package:libra_sheet/components/category_filter_chips.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the category tab.
class TransactionTabFilters extends StatelessWidget {
  const TransactionTabFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "Filter",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text("Type", style: textStyle),
        const SizedBox(height: 5),
        ExpenseTypeFilter(
          state.expenseFilterSelected,
          onSelect: state.setExpenseFilter,
        ),

        const SizedBox(height: 15),
        Text("Time Frame", style: textStyle),
        const SizedBox(height: 5),
        // TODO ,

        const SizedBox(height: 15),
        Text("Value", style: textStyle),
        const SizedBox(height: 5),
        // TODO value filter

        const SizedBox(height: 15),
        Text("Account", style: textStyle),
        const SizedBox(height: 5),
        const _AccountChips(),

        // TODO add Tag filter

        const SizedBox(height: 15),
        Text("Category", style: textStyle),
        const SizedBox(height: 5),
        const _CategoryChips(),
        // const _SubCategorySwitch(),
      ],
    );
  }
}

class _AccountChips extends StatelessWidget {
  const _AccountChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    final accounts = context.select<LibraAppState, List<Account>>((it) => it.accounts);
    return AccountFilterChips(
      accounts: accounts,
      selected: (account, i) => state.accountFilterSelected.contains(account.key),
      onSelected: (account, i, selected) => state.setAccountFilter(account, selected),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    final categories = context.select<LibraAppState, List<Category>>((it) => it.categories);
    return CategoryFilterChips(
      categories: categories,
      selected: (cat) => state.categoryFilterSelected.contains(cat.key),
      onSelected: (cat, selected) => state.setCategoryFilter(cat, selected),
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
  // }

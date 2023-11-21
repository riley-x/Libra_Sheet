import 'package:flutter/material.dart';
import 'package:libra_sheet/components/account_filter_chips.dart';
import 'package:libra_sheet/components/category_filter_chips.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the category tab.
class TransactionTabFilters extends StatelessWidget {
  /// Padding to be applied to the central column. Don't use padding outside the Scroll class, or
  /// else the scroll bar is oddly offset.
  final EdgeInsetsGeometry? interiorPadding;

  const TransactionTabFilters({super.key, this.interiorPadding});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: interiorPadding ?? EdgeInsets.zero,
          child: Column(
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
              Text("Date", style: textStyle),
              const SizedBox(height: 5),
              const _DateFilter(),

              const SizedBox(height: 15),
              Text("Value", style: textStyle),
              const SizedBox(height: 5),
              const _ValueRange(),

              const SizedBox(height: 15),
              Text("Account", style: textStyle),
              const SizedBox(height: 5),
              const _AccountChips(),

              const SizedBox(height: 15),

              const SizedBox(height: 5),
              const _CategoryChips(),

              // TODO add Tag filter
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
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
    var categories =
        context.select<LibraAppState, List<Category>>((it) => it.flattenedCategories());
    categories = [ignoreCategory, incomeCategory, expenseCategory] + categories;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            const Spacer(),
            Text("Category", style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            DropdownCheckboxMenu<Category>(
              items: categories,
              builder: dropdownCategoryBuilder,
              isChecked: (cat) =>
                  state.categoryFilterSelected[cat.key] ?? (cat.hasSubCats() ? null : false),
              isTristate: (cat) => cat.hasSubCats(),
              onChanged: (cat, i, selected) => state.setCategoryFilter(cat, selected),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final cat in categories)
              if (state.categoryFilterSelected[cat.key] ?? cat.hasSubCats())
                LibraChip(
                  cat.name,
                  onTap: () => state.setCategoryFilter(cat, false),
                )
          ],
        )
      ],
    );
  }
}

class _ValueRange extends StatelessWidget {
  const _ValueRange({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FocusTextField(
          label: 'Min',
          active: state.minValue != null,
          error: state.minValueError,
          onChanged: state.setMinValue,
        ),
        const SizedBox(width: 5),
        Container(
          width: 20,
          height: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 5),
        FocusTextField(
          label: 'Max',
          active: state.maxValue != null,
          error: state.maxValueError,
          onChanged: state.setMaxValue,
        ),
      ],
    );
  }
}

class _DateFilter extends StatelessWidget {
  const _DateFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FocusTextField(
          label: 'Start',
          active: state.startTime != null,
          error: state.startTimeError,
          hint: 'MM/DD/YY',
          onChanged: state.setStartTime,
        ),
        const SizedBox(width: 5),
        Container(
          width: 20,
          height: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 5),
        FocusTextField(
          label: 'End',
          active: state.endTime != null,
          error: state.endTimeError,
          hint: 'MM/DD/YY',
          onChanged: state.setEndTime,
        ),
      ],
    );
  }
}

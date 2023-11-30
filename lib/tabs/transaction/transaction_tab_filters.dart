// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/selectors/account_checkbox_menu.dart';
import 'package:libra_sheet/components/selectors/category_checkbox_menu.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/title_row.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the transaction tab.
class TransactionTabFilters extends StatelessWidget {
  /// Padding to be applied to the central column. Don't use padding outside the Scroll class, or
  /// else the scroll bar is oddly offset.
  final EdgeInsetsGeometry? interiorPadding;

  const TransactionTabFilters({super.key, this.interiorPadding});

  @override
  Widget build(BuildContext context) {
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
              // const SizedBox(height: 10),
              // Text("Type", style: textStyle),
              // const SizedBox(height: 5),
              // ExpenseTypeFilter(
              //   state.expenseFilterSelected,
              //   onSelect: state.setExpenseFilter,
              // ),

              /// Date
              const SizedBox(height: 15),
              Text("Date", style: textStyle),
              const SizedBox(height: 5),
              const _DateFilter(),

              /// Value
              const SizedBox(height: 15),
              Text("Value", style: textStyle),
              const SizedBox(height: 5),
              const _ValueRange(),

              /// Account
              const SizedBox(height: 15),
              const _AccountChips(),

              /// Category
              const SizedBox(height: 15),
              const _CategoryChips(),

              /// Tags
              const SizedBox(height: 15),
              const _TagSelector(),
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
    return AccountChips(
      selected: state.accountFilterSelected,
      whenChanged: (_, __) => state.loadTransactions(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    var categories =
        context.select<LibraAppState, List<Category>>((it) => it.categories.flattenedCategories());
    categories = [Category.ignore, Category.income, Category.expense] + categories;
    return Column(
      children: [
        TitleRow(
          title: Text("Category", style: Theme.of(context).textTheme.titleMedium),
          right: CategoryCheckboxMenu(
            categories: categories,
            map: state.categoryFilterSelected,
            notify: state.loadTransactions,
          ),
        ),
        const SizedBox(height: 5),
        CategoryFilterChips(
          categories: categories,
          map: state.categoryFilterSelected,
          notify: state.loadTransactions,
        ),
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
          active: state.filters.minValue != null,
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
          active: state.filters.maxValue != null,
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
          active: state.filters.startTime != null,
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
          active: state.filters.endTime != null,
          error: state.endTimeError,
          hint: 'MM/DD/YY',
          onChanged: state.setEndTime,
        ),
      ],
    );
  }
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    return Column(
      children: [
        TitleRow(
          title: Text("Tags", style: Theme.of(context).textTheme.titleMedium),
          right: DropdownCheckboxMenu<Tag>(
            icon: Icons.add,
            items: context.watch<LibraAppState>().tags.list,
            builder: (context, tag) => Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            isChecked: (it) => state.tags.contains(it),
            onChanged: state.onTagChanged,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final tag in state.tags)
              LibraChip(
                tag.name,
                color: tag.color,
                onTap: () => state.onTagChanged(tag, false),
              ),
          ],
        ),
      ],
    );
  }
}

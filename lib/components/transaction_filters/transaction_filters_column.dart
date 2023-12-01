// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/components/menus/category_checkbox_menu.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/tag_checkbox_menu.dart';
import 'package:libra_sheet/components/title_row.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for filtering transactions. Relies on having
/// a TransactionFilterState provided in the Widget tree, which holds the UI state for the column
/// and is linked on all the callbacks.
///
/// This class is used both in the transaction tab's main screen, as well as [TransactionFilterDialog].
class TransactionFiltersColumn extends StatelessWidget {
  /// Padding to be applied to the central column. Don't use padding outside the Scroll class, or
  /// else the scroll bar is oddly offset.
  final EdgeInsetsGeometry? interiorPadding;

  final bool showConfirmationButtons;
  final Function()? onReset;
  final Function()? onCancel;
  final Function()? onSave;

  const TransactionFiltersColumn({
    super.key,
    this.interiorPadding,
    this.showConfirmationButtons = false,
    this.onCancel,
    this.onReset,
    this.onSave,
  });

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
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Title
              const SizedBox(height: 10),
              Text(
                "Filter",
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              /// Not needed? Since already have a value filter
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

              /// Confirmation Buttons
              if (showConfirmationButtons) ...[
                const SizedBox(height: 30),
                FormButtons(
                  showDelete: false,
                  onCancel: onCancel,
                  onReset: onReset,
                  onSave: onSave,
                )
              ]
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
    final state = context.watch<TransactionFilterState>();
    return AccountChips(
      selected: state.filters.accounts,
      whenChanged: (_, __) => state.loadTransactions(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();
    var categories =
        context.select<LibraAppState, List<Category>>((it) => it.categories.flattenedCategories());
    categories = [Category.ignore, Category.income, Category.expense] + categories;
    return Column(
      children: [
        TitleRow(
          title: Text("Category", style: Theme.of(context).textTheme.titleMedium),
          right: CategoryCheckboxMenu(
            categories: categories,
            map: state.filters.categories,
            notify: state.loadTransactions,
          ),
        ),
        const SizedBox(height: 5),
        CategoryFilterChips(
          categories: categories,
          map: state.filters.categories,
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
    final state = context.watch<TransactionFilterState>();
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
    final state = context.watch<TransactionFilterState>();
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
    final state = context.watch<TransactionFilterState>();
    return TagFilterSection(
      selected: state.filters.tags,
      whenChanged: (_, __) => state.loadTransactions(),
    );
  }
}

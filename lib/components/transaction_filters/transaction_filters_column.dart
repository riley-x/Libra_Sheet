// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
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

  const TransactionFiltersColumn({
    super.key,
    this.interiorPadding,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return LimitedBox(
      maxWidth: 300,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: interiorPadding ?? EdgeInsets.zero,
          child: FocusScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Title
                const SizedBox(height: 10),
                Text(
                  "Filter",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                /// Text
                const SizedBox(height: 15),
                Text("Description", style: textStyle),
                const SizedBox(height: 5),
                const _NameFilter(),

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
                const ExcludeFocus(child: _AccountChips()),

                /// Category
                const SizedBox(height: 15),
                const ExcludeFocus(child: _CategoryChips()),

                /// Tags
                const SizedBox(height: 15),
                const ExcludeFocus(child: _TagSelector()),

                /// Checkboxes
                const SizedBox(height: 25),
                Text("Other", style: textStyle),
                const _AllocationCheckbox(),
                const _ReimbursementCheckbox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameFilter extends StatelessWidget {
  const _NameFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextFormField(
        controller: state.nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          isDense: true,
        ),
        onChanged: state.setName,
        maxLines: 1,
        // style: widget.style,
      ),
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
          controller: state.startDateController,
          label: 'Start',
          active: state.filters.startTime != null,
          error: state.startTimeError,
          hint: 'MM/DD/YY',
          onChanged: state.parseStartTime,
        ),
        const SizedBox(width: 5),
        Container(
          width: 20,
          height: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 5),
        FocusTextField(
          controller: state.endDateController,
          label: 'End',
          active: state.filters.endTime != null,
          error: state.endTimeError,
          hint: 'MM/DD/YY',
          onChanged: state.parseEndTime,
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
          controller: state.minValueController,
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
          controller: state.maxValueController,
          label: 'Max',
          active: state.filters.maxValue != null,
          error: state.maxValueError,
          onChanged: state.setMaxValue,
        ),
      ],
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
    var categories = context.watch<LibraAppState>().categories.flattenedCategories();
    categories = [Category.empty, Category.ignore, Category.other] + categories;
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
        CategoryFilterChips(
          categories: categories,
          map: state.filters.categories,
          notify: state.loadTransactions,
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

class _AllocationCheckbox extends StatelessWidget {
  const _AllocationCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();

    /// Careful! We need to map the checkbox tristate (null = dash, false = off) to the state tristate
    /// (null = off, false = dash).
    return Row(
      children: [
        const SizedBox(width: 10),
        const Expanded(child: Text("Has allocations")),
        Checkbox(
          // tristate: true,
          value: state.filters.hasAllocation == true,
          onChanged: (bool? value) => state.setHasAllocation((value == true) ? true : null),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _ReimbursementCheckbox extends StatelessWidget {
  const _ReimbursementCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();

    /// Careful! We need to map the checkbox tristate (null = dash, false = off) to the state tristate
    /// (null = off, false = dash).
    return Row(
      children: [
        const SizedBox(width: 10),
        const Expanded(child: Text("Has reimbursements")),
        Checkbox(
          // tristate: true,
          value: state.filters.hasReimbursement == true,
          onChanged: (bool? value) => state.setHasReimbursement((value == true) ? true : null),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

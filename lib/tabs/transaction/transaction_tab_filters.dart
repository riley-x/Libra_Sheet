import 'package:flutter/material.dart';
import 'package:libra_sheet/components/account_filter_chips.dart';
import 'package:libra_sheet/components/category_filter_chips.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/test_state.dart';
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
              Text("Category", style: textStyle),
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
    final categories = context.select<LibraAppState, List<Category>>((it) => it.categories);
    return CategoryFilterChips(
      categories: categories,
      selected: (cat) => state.categoryFilterSelected.contains(cat.key),
      onSelected: (cat, selected) => state.setCategoryFilter(cat, selected),
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
        _TextField(
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
        _TextField(
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
        _TextField(
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
        _TextField(
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

class _TextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final bool error;
  final bool active;
  final Function(String?)? onChanged;

  const _TextField({
    super.key,
    this.label,
    this.hint,
    this.error = false,
    this.active = false,
    this.onChanged,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  final FocusNode _focus = FocusNode();
  String? text;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      widget.onChanged?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: TextField(
        decoration: InputDecoration(
          filled: widget.active && !widget.error,
          fillColor: Theme.of(context).colorScheme.secondaryContainer,
          errorText: (widget.error) ? '' : null, // setting this to not null shows the error border
          errorStyle: const TextStyle(height: 0),
          border: const OutlineInputBorder(), // this sets the shape, but the color is not used
          hintText: widget.hint,
          hintStyle: Theme.of(context).textTheme.bodySmall,
          labelText: widget.label,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          isDense: true,
        ),
        onChanged: (it) => text = it,
        focusNode: _focus,
      ),
    );
  }
}

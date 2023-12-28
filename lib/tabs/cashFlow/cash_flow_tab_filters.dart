import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:provider/provider.dart';

/// Creates the column that holds all the option selectors for the cash flow tab.
class CashFlowTabFilters extends StatelessWidget {
  const CashFlowTabFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
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
        const Text("Display"),
        const SizedBox(height: 5),
        const _TypeSelector(),

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
          whenChanged: (_, __) => state.load(),
        ),

        /// Sub-cats switch
        const SizedBox(height: 20),
        const Text("Show Sub-Categories"),
        const SizedBox(height: 5),
        const _SubCategorySwitch(),

        /// Tags
        // TODO not trivial
        // const SizedBox(height: 15),
        // TagFilterSection(
        //   selected: state.tags,
        //   headerStyle: Theme.of(context).textTheme.bodyMedium,
        //   whenChanged: (_, __) => state.loadValues(),
        // ),
      ],
    );
  }
}

/// Segmented button for the type
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    return SegmentedButton<CashFlowType>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<CashFlowType>>[
        ButtonSegment<CashFlowType>(
          value: CashFlowType.categories,
          label: Text('Categories'),
        ),
        ButtonSegment<CashFlowType>(
          value: CashFlowType.net,
          label: Text('Net Change'),
        ),
      ],
      selected: <CashFlowType>{state.type},
      onSelectionChanged: (Set<CashFlowType> newSelection) => state.setType(newSelection.first),
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final monthList = context.watch<LibraAppState>().monthList;
    final state = context.watch<CashFlowState>();
    return TimeFrameSelector(
      months: monthList,
      selected: state.timeFrame,
      onSelect: state.setTimeFrame,
    );
  }
}

class _SubCategorySwitch extends StatelessWidget {
  const _SubCategorySwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CashFlowState>();
    return Switch(
      value: state.showSubCategories,
      onChanged: state.shouldShowSubCategories,
      activeColor: Theme.of(context).colorScheme.surfaceTint,
      activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

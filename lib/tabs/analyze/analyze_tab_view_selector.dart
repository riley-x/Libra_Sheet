import 'package:flutter/material.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:provider/provider.dart';

class AnalyzeTabViewSelector extends StatelessWidget {
  const AnalyzeTabViewSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Button(text: 'Income & Expenses', view: AnalyzeTabView.doubleStack, width: 240, top: true),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Button(text: 'Net Totals', view: AnalyzeTabView.netIncome, width: 120, left: true),
            _Button(text: 'Other', view: AnalyzeTabView.other, width: 120),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Button(
                text: 'Expense Pie', view: AnalyzeTabView.expenseHeatmap, width: 120, left: true),
            _Button(text: 'Income Pie', view: AnalyzeTabView.incomeHeatmap, width: 120),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Button(
              text: 'Expense Flow',
              view: AnalyzeTabView.expenseFlow,
              width: 120,
              left: true,
              bottom: true,
            ),
            _Button(
              text: 'Income Flow',
              view: AnalyzeTabView.incomeFlow,
              width: 120,
              bottom: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.text,
    required this.view,
    required this.width,
    this.top = false,
    this.left = false,
    this.bottom = false,
  });

  static const double height = 30;

  final String text;
  final AnalyzeTabView view;
  final double width;
  final bool top;
  final bool left;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    bool selected = context.select<AnalyzeTabState, bool>((state) => state.currentView == view);

    const radius = Radius.circular(12);
    var borderRadius = top
        ? const BorderRadius.vertical(top: radius)
        : bottom && left
            ? const BorderRadius.only(bottomLeft: radius)
            : bottom && !left
                ? const BorderRadius.only(bottomRight: radius)
                : BorderRadius.zero;
    var borderSide = BorderSide(color: Theme.of(context).colorScheme.outline);

    return Container(
      width: width,
      height: height,
      // color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
        border: top
            ? Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              )
            : Border(
                right: left ? BorderSide.none : borderSide,
                left: borderSide,
                bottom: borderSide,
              ),
        borderRadius: borderRadius,
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => context.read<AnalyzeTabState>().setView(view),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

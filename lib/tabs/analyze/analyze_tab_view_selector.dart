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
        _Button(text: 'Income & Expenses', type: DoubleStackView, width: 240, top: true),
        _Button(text: 'Net Income', type: NetIncomeView, width: 240),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Button(text: 'Expense Flow', type: ExpenseFlowsView, width: 120, left: true),
            _Button(text: 'Income Flow', type: IncomeFlowsView, width: 120),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Button(
              text: 'Expense Pie',
              type: ExpenseHeatmapView,
              width: 120,
              left: true,
              bottom: true,
            ),
            _Button(text: 'Income Pie', type: IncomeHeatmapView, width: 120, bottom: true),
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
    required this.type,
    required this.width,
    this.top = false,
    this.left = false,
    this.bottom = false,
  });

  static const double height = 30;

  final String text;
  final Type type;
  final double width;
  final bool top;
  final bool left;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    bool selected =
        context.select<AnalyzeTabState, bool>((state) => state.viewState.runtimeType == type);

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
        onTap: () {},
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

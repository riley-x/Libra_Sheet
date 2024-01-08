import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/color_indicator_card.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';

class AllocationCard extends StatelessWidget {
  final Allocation allocation;
  final Function(Allocation)? onTap;

  const AllocationCard(
    this.allocation, {
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = (allocation.category?.level == 0) ? null : allocation.category?.color;

    bool isUncategorized =
        allocation.category == Category.income || allocation.category == Category.expense;
    bool isInvestment = allocation.category == Category.investment;

    return ColorIndicatorCard(
      color: color,
      borderColor: (isUncategorized)
          ? Theme.of(context).colorScheme.error
          : (isInvestment)
              ? Theme.of(context).colorScheme.primary
              : null,
      onTap: onTap == null ? null : () => onTap!.call(allocation),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allocation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  allocation.category?.name ?? '',
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(
            allocation.value.dollarString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

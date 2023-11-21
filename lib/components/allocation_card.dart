import 'package:flutter/material.dart';
import 'package:libra_sheet/data/allocation.dart';
import 'package:libra_sheet/data/int_dollar.dart';

class AllocationCard extends StatelessWidget {
  final Allocation? allocation;
  final Function(Allocation?)? onTap;

  const AllocationCard(
    this.allocation, {
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (allocation == null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 5, height: 30),
          Text(
            'Add an allocation',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    } else {
      content = LimitedBox(
        maxWidth: 300,
        child: Row(
          children: [
            Expanded(
              child: Text(
                allocation!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  allocation!.value.dollarString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  allocation!.category?.name ?? '',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: (onTap == null) ? null : () => onTap!.call(allocation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: content,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/account.dart';

/// This callback is used to draw a single account row in dropdown menus.
Widget accountMenuBuilder(BuildContext context, Account? account) {
  return LimitedBox(
    maxWidth: 200,
    child: Row(
      children: [
        Container(
          width: 4,
          height: 30,
          color: account?.color,
        ),
        const SizedBox(width: 7),
        // This is necessary to make sure the text clips properly
        Flexible(
          child: Text(
            account?.name ?? 'None',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        )
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/account.dart';

/// This callback is used to draw a single account row in dropdown menus.
Widget accountMenuBuilder(BuildContext context, Account? account) {
  return LimitedBox(
    /// For some reason the DropdownButton doesn't pass its constraints to the builder. Hard-coded
    /// for now to match the width of the table forms (this excludes the space added by the dropdown
    /// button).
    maxWidth: 200,
    child: Row(
      children: [
        Container(
          width: 4,
          height: 30,
          color: account?.color,
        ),
        const SizedBox(width: 7),
        Text(
          account?.name ?? 'None',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge,
        )
      ],
    ),
  );
}

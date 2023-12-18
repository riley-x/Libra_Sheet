import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/category.dart';

/// This callback is used to draw a single category row in dropdown menus.
///
/// Set [selected] for when the row is in the actively selected position as opposed to in the dropdown
/// list.
Widget categoryMenuBuilder(
  BuildContext context,
  Category? cat, {
  bool superAsNone = false,
  bool selected = false,
}) {
  var style = Theme.of(context).textTheme.labelLarge;
  var text = cat?.name ?? 'None';
  var color = cat?.color;
  if (cat == null || (superAsNone && cat.level == 0)) {
    text = 'None';
    style = style?.copyWith(fontStyle: FontStyle.italic);
    color = null;
  }

  return LimitedBox(
    maxWidth: 200,
    child: Row(
      children: [
        if ((cat?.level ?? 0) > 1 && !selected) const SizedBox(width: 20),
        Container(color: color, width: 4, height: 24),
        const SizedBox(width: 6),

        /// This is necessary to make sure the text clips properly
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    ),
  );
}

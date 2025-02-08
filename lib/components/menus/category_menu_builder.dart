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
  bool indentSubcats = true,
  String? nullText,
}) {
  var style = Theme.of(context).textTheme.labelLarge;
  var text = cat?.name;
  var color = cat?.color;
  if (superAsNone && cat?.level == 0) {
    text = 'None';
    style = style?.copyWith(fontStyle: FontStyle.italic);
    color = null;
  }
  if (cat == null) {
    style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor);
  }

  final textWidget = Text(
    text ?? nullText ?? '',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: style,
  );

  return LimitedBox(
    maxWidth: 400, // prevent errors from [Flexible] below
    child: Row(
      children: [
        if (indentSubcats && (cat?.level ?? 0) > 1 && !selected) const SizedBox(width: 20),
        Container(color: color, width: 4, height: 24),
        SizedBox(width: (cat == null) ? 0 : 6),
        Flexible(child: textWidget), // Necessary to make sure the text clips properly
      ],
    ),
  );
}

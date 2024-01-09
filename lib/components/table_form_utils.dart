/// Utilities for the two-column table form format
import 'package:flutter/material.dart';

TableRow labelRow(
  BuildContext context,
  String label,
  Widget? right, {
  TableCellVerticalAlignment? labelAlign,
  String? tooltip,
  InlineSpan? richTooltip,

  /// This replaces the label and tooltip if not null
  Widget? labelCustom,
}) {
  var content = labelCustom;
  if (content == null) {
    content = Text(
      label,
      style: Theme.of(context).textTheme.titleSmall,
    );
    if (tooltip != null) {
      content = Tooltip(
        message: tooltip,
        // POSSIBLE BUG? This doesn't work, maybe because inside the table/tablerow/tablecell?
        richMessage: richTooltip,
        textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
              fontSize: 14,
            ),
        child: content,
      );
    }
  }

  return TableRow(
    children: [
      TableCell(
        verticalAlignment: labelAlign,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: content,
          ),
        ),
      ),
      if (right != null) right,
    ],
  );
}

const rowSpacing = TableRow(children: [
  SizedBox(
    height: 8,
  ),
  SizedBox(
    height: 8,
  )
]);

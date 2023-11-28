/// Utilities for the two-column table form format
import 'package:flutter/material.dart';

TableRow labelRow(
  BuildContext context,
  String label,
  Widget? right, {
  TableCellVerticalAlignment? labelAlign,
  String? tooltip,
  InlineSpan? richTooltip,
}) {
  Widget text = Text(
    label,
    style: Theme.of(context).textTheme.titleMedium,
  );
  return TableRow(
    children: [
      TableCell(
        verticalAlignment: labelAlign,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: (tooltip != null)
                ? Tooltip(
                    message: tooltip,
                    richMessage:
                        richTooltip, // POSSIBLE BUG? This doesn't work, maybe because inside the table/tablerow/tablecell?
                    textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontSize: 14,
                        ),
                    child: text,
                  )
                : text,
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

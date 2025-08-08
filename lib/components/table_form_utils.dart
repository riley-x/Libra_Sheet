/// Utilities for the two-column table form format
import 'package:flutter/material.dart';

TableRow labelRow(
  BuildContext context,
  String label,
  Widget right, {
  TableCellVerticalAlignment? labelAlign,
  String? tooltip,
  InlineSpan? richTooltip,

  /// This replaces the label and tooltip if not null
  Widget? labelCustom,
}) {
  var content = labelCustom;

  if (content == null) {
    final theme = Theme.of(context);
    content = Text(label, style: theme.textTheme.titleSmall);
    if (tooltip != null || richTooltip != null) {
      content = Tooltip(
        message: tooltip,
        // POSSIBLE BUG? This doesn't work, maybe because inside the table/tablerow/tablecell?
        richMessage: richTooltip,
        textStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onInverseSurface,
          fontSize: 14,
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline, width: 1)),
          ),
          child: content,
        ),
      );
    }
  }

  return TableRow(
    children: [
      TableCell(
        verticalAlignment: labelAlign,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(padding: const EdgeInsets.only(right: 20), child: content),
        ),
      ),
      right,
    ],
  );
}

const rowSpacing = TableRow(children: [SizedBox(height: 8), SizedBox(height: 8)]);

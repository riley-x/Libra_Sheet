/// Utilities for the two-column table form format
import 'package:flutter/material.dart';

TableRow labelRow(
  BuildContext context,
  String label,
  Widget? right, {
  TableCellVerticalAlignment? labelAlign,
}) {
  return TableRow(
    children: [
      TableCell(
        verticalAlignment: labelAlign,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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

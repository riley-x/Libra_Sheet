import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';

class Category {
  final int key;
  final String name;
  final Color? color;

  const Category({this.key = 0, required this.name, this.color});
}

class CategoryHistory {
  final Category category;
  final List<TimeValue> values;

  const CategoryHistory(
    this.category,
    this.values,
  );
}

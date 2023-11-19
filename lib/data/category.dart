import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';

class Category<T extends Category<dynamic>> {
  final int key;
  final String name;
  final Color? color;
  final List<T>? subCats;

  Category({this.key = 0, required this.name, this.color, this.subCats});
}

class CategoryValue extends Category<CategoryValue> {
  CategoryValue({super.key, required super.name, super.color, super.subCats, required this.value});
  final int value;
}

class CategoryHistory {
  final Category category;
  final List<TimeValue> values;

  const CategoryHistory(
    this.category,
    this.values,
  );
}

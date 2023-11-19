import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/data/transaction.dart';

class Category<T extends Category<dynamic>> {
  final int key;
  final String name;
  final Color? color;
  final List<T>? subCats;

  const Category({this.key = 0, required this.name, this.color, this.subCats});

  Category.copy(Category<T> other)
      : key = other.key,
        name = other.name,
        color = other.color,
        subCats = other.subCats;

  bool hasSubCats() {
    return subCats != null && subCats!.isNotEmpty;
  }
}

class CategoryValue extends Category<CategoryValue> {
  const CategoryValue({
    super.key,
    required super.name,
    super.color,
    super.subCats,
    required this.value,
  });
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

// class CategoryWithTransactions extends Category<CategoryWithTransactions> {
//   final List<Transaction> transactions;

//   const CategoryWithTransactions({
//     super.key,
//     required super.name,
//     super.color,
//     super.subCats,
//     required this.transactions,
//   });

//   CategoryWithTransactions.fromCategory(other, {required this.transactions})
//       : super(key: other.key, color: other.color, name: other.name);
// }

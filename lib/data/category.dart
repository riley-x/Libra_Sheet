import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';

class Category {
  final int key;
  final String name;
  final Color? color;
  final List<Category>? subCats;

  const Category({this.key = 0, required this.name, this.color, this.subCats});

  Category.copy(Category other)
      : key = other.key,
        name = other.name,
        color = other.color,
        subCats = other.subCats;

  bool hasSubCats() {
    return subCats != null && subCats!.isNotEmpty;
  }
}

final incomeCategory = Category(
  key: -1,
  name: 'Income',
  color: Color(0xFF004940),
  subCats: [],
);

final expenseCategory = Category(
  key: -2,
  name: 'Expense',
  color: Color(0xFF5C1604),
  subCats: [],
);

final ignoreCategory = Category(
  key: -3,
  name: 'Ignore',
  color: Color(0),
);

class CategoryValue extends Category {
  const CategoryValue({
    super.key,
    required super.name,
    super.color,
    this.subCats,
    required this.value,
  });
  final int value;

  @override
  final List<CategoryValue>? subCats;
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

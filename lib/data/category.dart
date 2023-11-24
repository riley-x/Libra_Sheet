import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';

class Category {
  final int key;
  final String name;
  final Color? color;
  final List<Category>? subCats;
  final Category? parent;

  /// Level of category
  ///   0: fixed categories (income/expense/ignore)
  ///   1: top-level user categories
  ///   2: user subCategories
  ///   3+: not implemented
  final int level;

  const Category(
      {this.key = 0,
      required this.name,
      this.color,
      this.subCats,
      this.parent,
      required this.level});

  Category.copy(Category other)
      : key = other.key,
        name = other.name,
        color = other.color,
        level = other.level,
        parent = other.parent,
        subCats = List.from(other.subCats ?? []);

  static const empty = Category(
    key: 0,
    level: 0,
    name: '',
    color: Colors.transparent,
  );

  // ignore: prefer_const_constructors
  static final income = Category(
    key: -1,
    level: 0,
    name: 'Income',
    color: const Color(0xFF004940),
    subCats: [],
  );

  // ignore: prefer_const_constructors
  static final expense = Category(
    key: -2,
    level: 0,
    name: 'Expense',
    color: const Color(0xFF5C1604),
    subCats: [],
  );

  static const ignore = Category(
    key: -3,
    level: 0,
    name: 'Ignore',
    color: Colors.transparent,
  );

  bool hasSubCats() {
    return subCats != null && subCats!.isNotEmpty;
  }

  @override
  String toString() {
    return "Category($key: $name)";
  }
}

class CategoryValue extends Category {
  const CategoryValue({
    super.key,
    required super.name,
    required super.level,
    super.parent,
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

/// A tristate map for checkboxes. Categories can have three states:
///       - checked (map true, returns true)
///       - dashed (map false, returns null)
///       - off (map null, returns false)
/// Only categories with children can have the dashed state. Selecting the checked state for such
/// categories will automatically add all its children, while switching to the dashed state will
/// remove the children.
class CategoryTristateMap {
  Map<int, bool> _map = {};

  void set(Category cat, bool? selected) {
    if (selected == true) {
      _map[cat.key] = true;
      for (final subCat in cat.subCats ?? []) {
        _map[subCat.key] = true;
      }
    } else if (selected == null) {
      _map[cat.key] = false;
      for (final subCat in cat.subCats ?? []) {
        _map.remove(subCat.key);
      }
    } else {
      _map.remove(cat.key);
    }
  }

  bool? get(Category cat) {
    final val = _map[cat.key];
    if (val == true) {
      return true;
    } else if (val == false) {
      return null;
    } else {
      return false;
    }
  }
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

extension CategoryList on List<Category> {
  int countFlattened() {
    int out = length;
    forEach((it) {
      out += it.subCats?.length ?? 0;
    });
    return out;
  }
}

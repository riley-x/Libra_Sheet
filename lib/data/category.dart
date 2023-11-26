import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/time_value.dart';

class CategoryBase {}

class Category {
  final int key;
  String name;
  Color? color;
  final List<Category> subCats = [];

  /// Parent category for nested categories. All level > 0 categories must have a valid parent.
  /// DO NOT replace the parent category without updating this field! Consider using [copyFrom] to
  /// in-place update the parent instead;
  Category? parent;

  /// This must be consistent with parent!
  late final ExpenseType type;

  /// Level of category. Should be [parent.level] + 1.
  ///   0: fixed categories (income/expense/ignore)
  ///   1: top-level user categories
  ///   2: user subCategories
  ///   3+: not implemented
  late final int level;

  Category({
    this.key = 0,
    required this.name,
    this.color,
    this.parent,
    int? level,
    ExpenseType? type,
    List<Category>? subCats,
  }) {
    if (subCats != null) {
      this.subCats.addAll(subCats);
    }

    /// Type and level from parent
    if (parent != null) {
      assert(type == null || type == parent!.type);
      assert(level == null || level == parent!.level + 1);
      this.type = parent!.type;
      this.level = parent!.level + 1;
    } else {
      assert(type != null && level != null);
      this.type = type!;
      this.level = level!;
    }
  }

  Category.copy(Category other)
      : key = other.key,
        name = other.name,
        color = other.color,
        level = other.level,
        parent = other.parent,
        type = other.type {
    subCats.addAll(other.subCats);
  }

  /// Update current fields from [other].
  void copySoftFieldsFrom(Category other) {
    assert(other.parent == parent);
    name = other.name;
    color = other.color;
  }

  Category copyWith({
    int? key,
    String? name,
    Color? color,
    int? level,
    Category? parent,
    ExpenseType? type,
    List<Category>? subCats,
  }) {
    return Category(
        key: key ?? this.key,
        name: name ?? this.name,
        color: color ?? this.color,
        level: level ?? this.level,
        parent: parent ?? this.parent,
        type: type ?? this.type,
        subCats: subCats ?? this.subCats);
  }

  static final empty = Category(
    key: 0,
    level: 0,
    name: '',
    color: Colors.transparent,
    type: ExpenseType.expense,
  );

  /// The main super-category corresponding to income transactions. This category includes all
  /// un-categorized transactions with positive value. Note that all income categories must refer
  /// to this as parent, and must be added to its subCats list.
  static final income = Category(
    key: -1,
    level: 0,
    name: 'Income',
    color: const Color(0xFF004940),
    subCats: const [],
    type: ExpenseType.income,
  );

  /// The main super-category corresponding to expense transactions. This category includes all
  /// un-categorized transactions with negative value. Note that all expense categories must refer
  /// to this as parent, and must be added to its subCats list.
  static final expense = Category(
    key: -2,
    level: 0,
    name: 'Expense',
    color: const Color(0xFF5C1604),
    subCats: [],
    type: ExpenseType.expense,
  );

  static final ignore = Category(
    key: -3,
    level: 0,
    name: 'Ignore',
    color: Colors.transparent,
    type: ExpenseType.expense,
  );

  @override
  String toString() {
    return "Category($key: $name 0x${(color?.value ?? 0).toRadixString(16)} parent=${parent?.name})";
  }

  Map<String, dynamic> toMap({int? listIndex}) {
    assert(parent != null);
    final out = {
      'name': name,
      'colorLong': color?.value ?? 0,
      'parentKey': parent!.key,
    };

    /// For auto-incrementing keys, make sure they are NOT in the map supplied to sqflite.
    if (key != 0) {
      out['key'] = key;
    }
    if (listIndex != null) {
      out['listIndex'] = listIndex;
    }
    return out;
  }
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
      for (final subCat in cat.subCats) {
        _map[subCat.key] = true;
      }
    } else if (selected == null) {
      _map[cat.key] = false;
      for (final subCat in cat.subCats) {
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
      out += it.subCats.length;
    });
    return out;
  }
}

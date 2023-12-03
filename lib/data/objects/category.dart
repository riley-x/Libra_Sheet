import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/time_value.dart';

class CategoryBase {}

class Category {
  int key;
  String name;
  Color color;

  /// Parent category for nested categories. All level > 0 categories must have a valid parent.
  /// DO NOT replace the parent category!
  Category? parent;
  final List<Category> subCats = [];

  /// This must be consistent with parent!
  final ExpenseFilterType type;

  /// Level of category. Should be [parent.level] + 1.
  ///   0: fixed categories (income/expense/ignore)
  ///   1: top-level user categories
  ///   2: user subCategories
  ///   3+: not implemented
  int level;

  Category({
    this.key = 0,
    required this.name,
    required Category this.parent,
    required this.color,
    List<Category>? subCats,
  })  : type = parent.type,
        level = parent.level + 1 {
    assert(parent != Category.empty);
    if (subCats != null) {
      this.subCats.addAll(subCats);
    }
  }

  Category._manual({
    required this.key,
    required this.name,
    required this.color,
    required this.type,
    required this.level,
  });

  /// Placeholder for initializing non-null fields, and also to indicate an uncategorized entity.
  /// I.e. it stands in for [income] or [expense] when the value is not known. This is also shown in
  /// the UI in preference of [income] and [expense], since those two can be a bit confusing.
  ///
  /// WARNING objects like [Transaction] and [Category.parent] should not reference [empty], it
  /// should only be used in filter menus.
  static final empty = Category._manual(
    key: 0,
    name: 'Uncategorized',
    color: Colors.transparent,
    type: ExpenseFilterType.all,
    level: 0,
  );

  /// The main super-category corresponding to income transactions. This category includes all
  /// un-categorized transactions with positive value. Note that all income categories must refer
  /// to this as parent, and must be added to its subCats list.
  static final income = Category._manual(
    key: -1,
    name: 'Uncategorized',
    color: const Color(0xFF004940),
    type: ExpenseFilterType.income,
    level: 0,
  );

  /// The main super-category corresponding to expense transactions. This category includes all
  /// un-categorized transactions with negative value. Note that all expense categories must refer
  /// to this as parent, and must be added to its subCats list.
  static final expense = Category._manual(
    key: -2,
    name: 'Uncategorized',
    color: const Color(0xFF5C1604),
    type: ExpenseFilterType.expense,
    level: 0,
  );

  static final ignore = Category._manual(
    key: -3,
    name: 'Ignore',
    color: Colors.transparent,
    type: ExpenseFilterType.all,
    level: 0,
  );

  @override
  String toString() {
    return "Category($key: $name 0x${color.value.toRadixString(16)} parent=${parent?.name})";
  }

  Map<String, dynamic> toMap({int? listIndex}) {
    assert(parent != null);
    final out = {
      'name': name,
      'colorLong': color.value,
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
  final List<TimeIntValue> values;

  const CategoryHistory(
    this.category,
    this.values,
  );
}

/// A tristate map for checkboxes. Categories can have three states:
///       - checked (_map true, returns true)
///       - dashed (_map false, returns null)
///       - off (_map null, returns false)
/// Only categories with children can have the dashed state. Selecting the checked state for such
/// categories will automatically add all its children, while switching to the dashed state will
/// remove the children.
///
/// This makes it easy to test for inclusion in the filter just by using contains().
class CategoryTristateMap {
  /// [initial]: An initial set of categories to be marked as selected.
  /// [withSubcats]: If true, automatically adds the subcats of [initial] too.
  CategoryTristateMap([Iterable<Category> initial = const {}, bool withSubcats = true]) {
    for (final cat in initial) {
      if (withSubcats) {
        set(cat, true);
      } else {
        _map[cat.key] = !isTristate(cat);
      }
    }
  }

  final Map<int, bool> _map = {};

  void set(Category cat, bool? selected) {
    if (selected == true) {
      _map[cat.key] = true;
      if (isTristate(cat)) {
        for (final subCat in cat.subCats) {
          _map[subCat.key] = true;
        }
      }
    } else if (selected == null) {
      _map[cat.key] = false;
      if (cat.level == 1) {
        for (final subCat in cat.subCats) {
          _map.remove(subCat.key);
        }
      }
    } else {
      _map.remove(cat.key);
    }
  }

  bool? checkboxState(Category cat) {
    final val = _map[cat.key];
    if (val == true) {
      return true;
    } else if (val == false) {
      return null;
    } else {
      return false;
    }
  }

  bool isActive(Category cat) {
    return _map.containsKey(cat.key);
  }

  bool isTristate(Category cat) {
    return cat.level == 1 && cat.subCats.isNotEmpty;
  }

  Iterable<int> activeKeys() {
    return _map.keys;
  }
}

extension CategoryList on List<Category> {
  int countFlattened() {
    int out = length;
    forEach((it) {
      out += it.subCats.length;
    });
    return out;
  }

  void _addToKeyMap(Map<int, Category> map) {
    forEach((cat) {
      map[cat.key] = cat;
      cat.subCats._addToKeyMap(map);
    });
  }

  Map<int, Category> createKeyMap() {
    final out = <int, Category>{};
    _addToKeyMap(out);
    return out;
  }
}

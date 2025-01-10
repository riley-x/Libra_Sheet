import 'package:flutter/material.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
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
  ///   0: fixed categories defined below (income/expense/ignore/other)
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

  /// This is a special category used to ignore the transaction value. It is also used for reimbursements
  /// to store the reimbursed amounts.
  static final ignore = Category._manual(
    key: -3,
    name: 'Ignore',
    color: Colors.transparent,
    type: ExpenseFilterType.all,
    level: 0,
  );

  /// This is a special category like [ignore] but the values here are separated in the category
  /// history table for plotting.
  static final other = Category._manual(
    key: -4,
    name: 'Other',
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

  bool get isUncategorized =>
      this == Category.empty || this == Category.expense || this == Category.income;

  bool get isOther => this == Category.other || parent == Category.other;

  bool get predefined => isUncategorized || this == Category.ignore || this == Category.other;
}

class CategoryHistoryEntry {
  final Category category;
  final List<int> values;

  const CategoryHistoryEntry(this.category, this.values);
}

/// Utility class for aggregating category histories for bar charts. Only add entries using
/// [addIndividual] or [addCumulative] to ensure that the value lists are aligned with [times].
class CategoryHistory {
  final bool invertExpenses;
  final bool cumulateTimeValues;

  /// DO NOT modify [times] after adding entries!
  final List<DateTime> times;
  final List<CategoryHistoryEntry> categories;

  CategoryHistory(
    this.times, {
    this.invertExpenses = true,
    this.cumulateTimeValues = false,
  }) : categories = [];

  /// This constructor applies no checks on whether [categories] aligns with [times].
  /// [invertExpenses] and [cumulateTimeValues] are not used.
  const CategoryHistory.fromList(
    this.times,
    this.categories, {
    this.invertExpenses = true,
    this.cumulateTimeValues = false,
  });

  static const empty = CategoryHistory.fromList([], []);

  //-----------------------------------------------------------
  // Adding entries
  //-----------------------------------------------------------
  List<int>? _fixVals(Category category, List<TimeIntValue>? values) {
    if (values == null) return null;
    final vals = values.alignValues(times, cumulate: cumulateTimeValues);
    if (invertExpenses && category.type == ExpenseFilterType.expense) {
      for (int i = 0; i < vals.length; i++) {
        vals[i] = -vals[i];
      }
    }
    return vals;
  }

  /// Adds a single [category] from [data] to the stored collection in [categories], with values
  /// padded to align with [times].
  ///
  /// This function does not cumulate values from sub categories (and so just contains the amounts
  /// in the parent category). But if [recurseSubcats], will recurse to add all subcats of
  /// [category] too (still no cumulate).
  void addIndividual(
    Category category,
    Map<int, List<TimeIntValue>> data, {
    bool recurseSubcats = true,
  }) {
    /// This entry
    final vals = _fixVals(category, data[category.key]);
    if (vals != null) {
      categories.add(CategoryHistoryEntry(category, vals));
    }

    /// Recurse subcats
    if (recurseSubcats) {
      for (final subCat in category.subCats) {
        addIndividual(subCat, data);
      }
    }
  }

  /// Adds only [category] to [categories], but iterates through the subcats to cumulate their values
  /// togther.
  void addCumulative(Category category, Map<int, List<TimeIntValue>> data) {
    var vals = _fixVals(category, data[category.key]);

    /// We only recurse once since max level = 2.
    for (final subCat in category.subCats) {
      final subCatVals = _fixVals(subCat, data[subCat.key]);
      if (vals == null) {
        vals = subCatVals;
      } else if (subCatVals != null) {
        vals.addElementwise(subCatVals);
      }
    }

    if (vals != null) {
      categories.add(CategoryHistoryEntry(category, vals));
    }
  }

  //-----------------------------------------------------------
  // Utils
  //-----------------------------------------------------------
  List<int> getMonthlyTotals([(int, int)? range]) {
    range ??= (0, times.length);
    final out = List.filled(range.$2 - range.$1, 0);
    for (final cat in categories) {
      for (int i = range.$1; i < range.$2; i++) {
        out[i - range.$1] += cat.values[i];
      }
    }
    return out;
  }

  double getDollarAverageMonthlyTotal([(int, int)? range]) {
    return getDollarAverage(getMonthlyTotals(range));
  }

  Map<int, int> getCategoryTotals([(int, int)? range, bool absolute = false]) {
    range ??= (0, times.length);
    final out = <int, int>{};
    for (final cat in categories) {
      var total = 0;
      for (int i = range.$1; i < range.$2; i++) {
        total += cat.values[i];
      }
      out[cat.category.key] = absolute ? total.abs() : total;
    }
    return out;
  }
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
  final Map<int, bool> _map;

  /// [initial]: An initial set of categories to be marked as selected.
  /// [withSubcats]: If true, automatically adds the subcats of [initial] too.
  CategoryTristateMap([Iterable<Category> initial = const {}, bool withSubcats = true])
      : _map = {} {
    for (final cat in initial) {
      if (withSubcats) {
        set(cat, true);
      } else {
        _map[cat.key] = !isTristate(cat);
      }
    }
  }

  CategoryTristateMap._internal(this._map);

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
      if (isTristate(cat)) {
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

  bool get isEmpty => _map.isEmpty;

  bool isActive(Category cat) {
    return _map.containsKey(cat.key);
  }

  bool isTristate(Category cat) {
    return cat.level == 1 && cat.subCats.isNotEmpty;
  }

  Iterable<int> activeKeys() {
    return _map.keys;
  }

  void clear() => _map.clear();

  CategoryTristateMap copy() => CategoryTristateMap._internal(Map.from(_map));
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

  List<Category> flattened() {
    final out = <Category>[];
    for (final cat in this) {
      out.addAll(cat.subCats);
      out.add(cat);
    }
    return out;
  }
}

import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';

class CategoryRule {
  final int key;
  String pattern;
  Category? category; // TODO make these non-nullable, but forms need to remain nullable
  Account? account;

  /// We need to store this separately from the category because of generic super categories like
  /// Category.ignore.
  ExpenseType type;

  CategoryRule({
    this.key = 0,
    required this.pattern,
    required this.category,
    required this.type,
    this.account,
  }) {
    assert(category == null || category!.level == 0 || type == category!.type);
  }

  static final empty = CategoryRule(
    pattern: "",
    category: Category.empty,
    type: ExpenseType.expense,
  );

  CategoryRule copyWith({required int key}) {
    return CategoryRule(
      key: key,
      pattern: pattern,
      category: category,
      type: type,
      account: account,
    );
  }
}

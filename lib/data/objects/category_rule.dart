import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';

class CategoryRule {
  final int key;
  final ExpenseType type;
  String pattern;
  Category? category;
  Account? account;

  CategoryRule({
    this.key = 0,
    required this.type,
    required this.pattern,
    required this.category,
    this.account,
  });

  static final empty = CategoryRule(
    type: ExpenseType.expense,
    pattern: "",
    category: null,
  );
}

import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';

class CategoryRule {
  final int key;
  String pattern;
  Category? category;
  Account? account;

  CategoryRule({
    this.key = 0,
    required this.pattern,
    required this.category,
    this.account,
  });

  static final empty = CategoryRule(
    pattern: "",
    category: null,
  );

  CategoryRule copyWith({required int key}) {
    return CategoryRule(
      key: key,
      pattern: pattern,
      category: category,
      account: account,
    );
  }
}

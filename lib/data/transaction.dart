import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/tag.dart';

class Transaction {
  const Transaction({
    this.key = -1,
    required this.name,
    required this.date,
    required this.value,
    this.categoryKey,
    this.category,
    this.accountKey,
    this.account,
    this.note = "",
    this.reimbursements,
    this.tags,
  });

  final int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final int? accountKey;
  final Account? account;
  final int? categoryKey;
  final Category? category;

  // final List<Allocation> allocations;
  final List<Tag>? tags;
  final List<Transaction>? reimbursements;
}

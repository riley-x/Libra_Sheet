import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/allocation.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/reimbursement.dart';
import 'package:libra_sheet/data/tag.dart';

class Transaction {
  const Transaction({
    this.key = -1,
    required this.name,
    required this.date,
    required this.value,
    this.category,
    this.account,
    this.note = "",
    this.allocations,
    this.reimbursements,
    this.tags,
  });

  final int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final Account? account;
  final Category? category;

  final List<Tag>? tags;
  final List<Allocation>? allocations;
  final List<Reimbursement>? reimbursements;
}

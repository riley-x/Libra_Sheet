import 'package:libra_sheet/data/account.dart';

class Transaction {
  const Transaction({
    required this.name,
    required this.date,
    required this.value,
    this.categoryKey,
    this.category,
    this.accountKey,
    this.account,
    this.note = "",
    this.reimbursements = const [],
  });

  final String name;
  final DateTime date;
  final int value;
  final String note;

  final int? accountKey;
  final Account? account;
  final int? categoryKey;
  final int? category;

  // final List<Allocation> allocations;
  // final List<Tag> tags;
  final List<Transaction> reimbursements;
}

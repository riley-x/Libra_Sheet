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

  @override
  String toString() {
    var out = "Transaction($key): $value $date"
        "\n\t$name"
        "\n\t$account"
        "\n\t$category";
    if (note.isNotEmpty) {
      out += "\n\t$note";
    }
    out += "\n\ttags=${tags?.length ?? 0}"
        " alloc=${allocations?.length ?? 0}"
        " reimb=${reimbursements?.length ?? 0}";
    return out;
  }
}

final dummyTransaction = Transaction(name: '___TEST___', date: DateTime(1987), value: 10000);

import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';

class Transaction {
  Transaction({
    this.key = 0,
    required this.name,
    required this.date,
    required this.value,
    this.category,
    this.account,
    this.note = "",
    this.allocations,
    this.reimbursements,
    this.tags,
    this.nAllocations = 0,
  });

  int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final Account? account;
  final Category? category;

  final List<Tag>? tags;
  final List<Allocation>? allocations;
  final List<Reimbursement>? reimbursements;

  /// We don't load all the allocations with the transaction in list view, but we do count how many
  /// there are. This field is equal to allocations.length when [allocations] is not null.
  int nAllocations;

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

  bool relationsAreLoaded() {
    if (account == null) return false;
    if (category == null) return false;
    if (tags == null) return false;
    if (allocations == null) return false;
    if (reimbursements == null) return false;
    if (nAllocations != allocations!.length) return false;
    return true;
  }
}

final dummyTransaction = Transaction(name: '___TEST___', date: DateTime(1987), value: 10000);

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
    nAllocations = 0,
  }) : _nAllocations = nAllocations;

  int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final Account? account;
  final Category? category;

  final List<Tag>? tags;
  List<Allocation>? allocations;
  List<Reimbursement>? reimbursements;

  /// We don't load all the allocations with the transaction in list view, but we do count how many
  /// there are. This field is not used when [allocations] is not null.
  final int _nAllocations;
  int get nAllocations {
    if (allocations == null) return _nAllocations;
    return allocations!.length;
  }

  @override
  String toString() {
    var out = "Transaction($key): $value $date"
        "\n\t$name"
        "\n\t$account"
        "\n\t$category";
    if (note.isNotEmpty) {
      out += "\n\t$note";
    }
    out += "\n\ttags=${tags?.length}"
        " alloc=${allocations?.length}"
        " reimb=${reimbursements?.length}";
    return out;
  }

  bool relationsAreLoaded() {
    if (account == null) return false;
    if (category == null) return false;
    if (tags == null) return false;
    if (allocations == null) return false;
    if (reimbursements == null) return false;
    return true;
  }
}

final dummyTransaction = Transaction(name: '___TEST___', date: DateTime(1987), value: 10000);

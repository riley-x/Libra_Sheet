import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';

/// Transactions should not be updated in-place, but passed to TransactionServices.update().
/// Pointers to transactions should not be kept in memory outside of UI state. Data processing
/// should always be retrieved through the database.
///
/// However, we do update the [allocations] and [reimbursements] lists after creation, because
/// transactions are not initally loaded with them. Instead [nAllocations] and [nReimbursements]
/// are used in the interim. These are shown in the [TransactionCard]s, while the actual allocs/
/// reimbs are only shown and loaded in the [TransactionDetailsEditor].
class Transaction {
  Transaction({
    this.key = 0,
    required this.name,
    required this.date,
    required this.value,
    required Category category,
    this.account,
    this.note = "",
    this.allocations,
    this.reimbursements,
    List<Tag>? tags,
    int nAllocations = 0,
    int totalReimbusrements = 0,
  })  : category = (category != Category.empty)
            ? category
            : (value > 0)
                ? Category.income
                : Category.expense,
        tags = (tags == null) ? [] : tags,
        _nAllocations = nAllocations,
        _reimbTotal = totalReimbusrements;

  int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final Account? account;
  final Category category;

  final List<Tag> tags;
  List<Allocation>? allocations;
  List<Reimbursement>? reimbursements;

  /// We don't load all the allocations with the transaction in list view, but we do count how many
  /// there are. This field is not used when [allocations] is not null.
  final int _nAllocations;
  int get nAllocations {
    if (allocations == null) return _nAllocations;
    return allocations!.length;
  }

  /// Similarly, we don't load all the reimbursements with the transaction in the list view, but
  /// we do get the total value. This field is not used when [reimbursements] is not null.
  final int _reimbTotal;
  int get totalReimbusrements {
    if (reimbursements == null) return _reimbTotal;
    return reimbursements!.fold(0, (cum, e) => cum + e.value);
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
    out += "\n\ttags=${tags.length}"
        " alloc=${allocations?.length}"
        " reimb=${reimbursements?.length}";
    return out;
  }

  bool relationsAreLoaded() {
    if (allocations == null) return false;
    if (reimbursements == null) return false;
    return true;
  }

  Transaction copyWith({
    Category? category,
  }) {
    return Transaction(
      key: key,
      name: name,
      date: date,
      value: value,
      category: category ?? this.category,
      account: account,
      note: note,
      allocations: allocations,
      reimbursements: reimbursements,
      tags: tags,
      nAllocations: nAllocations,
      totalReimbusrements: totalReimbusrements,
    );
  }
}

final dummyTransaction =
    Transaction(name: '___TEST___', date: DateTime(1987), value: 10000, category: Category.income);

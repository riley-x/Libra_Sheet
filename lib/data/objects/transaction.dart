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
/// transactions are not initally loaded with them. Instead [softAllocations] and [nReimbursements]
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
    List<SoftAllocation> softAllocations = const [],
    int totalReimbusrements = 0,
  })  : category = (category != Category.empty)
            ? category
            : (value > 0)
                ? Category.income
                : Category.expense,
        tags = (tags == null) ? [] : tags,
        _softAllocations = softAllocations,
        _reimbTotal = totalReimbusrements;

  int key;
  final String name;
  final DateTime date;
  final int value;
  final String note;

  final Account? account;
  Category category;

  final List<Tag> tags;
  List<Allocation>? allocations;
  List<Reimbursement>? reimbursements;

  /// We don't load all the allocations with the transaction in list view, (although maybe we could),
  /// and instead load some soft fields. This field is not used when [allocations] is not null.
  final List<SoftAllocation> _softAllocations;

  Iterable<SoftAllocation> get softAllocations {
    if (allocations == null) return _softAllocations;
    return [
      for (final alloc in allocations!)
        SoftAllocation(
          category: alloc.category ?? Category.empty,
          value: alloc.value,
        )
    ];
  }

  int get nAllocations => allocations?.length ?? _softAllocations.length;

  /// Returns the total value of allocations. Remember this is always a positive value, and should
  /// be less than the value of the transaction itself.
  int totalAllocations() {
    int sum = 0;
    if (allocations == null) {
      for (final alloc in _softAllocations) {
        sum += alloc.value;
      }
    } else {
      for (final alloc in allocations!) {
        sum += alloc.value;
      }
    }
    return sum;
  }

  /// Similarly, we don't load all the reimbursements with the transaction in the list view, but
  /// we do get the total value. This field is not used when [reimbursements] is not null.
  final int _reimbTotal;

  /// Remember that reimbursements are always stored as positive value. See [adjustedValue]
  /// for a signed value.
  int get totalReimbusrements {
    if (reimbursements == null) return _reimbTotal;
    return reimbursements!.fold(0, (cum, e) => cum + e.value);
  }

  /// Returns the value after adjustments for reimbursements and allocations. Should be the same
  /// sign but smaller in magnitude than the original value.
  int adjustedValue() {
    if (value < 0) {
      return value + totalReimbusrements + totalAllocations();
    } else {
      return value - totalReimbusrements - totalAllocations();
    }
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
}

class SoftAllocation {
  final Category category;
  final int value;

  SoftAllocation({required this.category, required this.value});
}

final dummyTransaction =
    Transaction(name: '___TEST___', date: DateTime(1987), value: 10000, category: Category.income);

class CsvAllocation {
  final String name;
  final String category;
  final int value;

  CsvAllocation({required this.name, required this.category, required this.value});

  @override
  String toString() {
    return "$name: $category $value";
  }
}

class TransactionWithSoftRelations {
  Transaction t;
  List<(int, int)> reimbs; // (target key, value)
  List<CsvAllocation> allocs;

  TransactionWithSoftRelations(this.t, this.allocs, this.reimbs);
}

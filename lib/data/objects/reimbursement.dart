import 'package:libra_sheet/data/objects/transaction.dart';

/// WARNING [target] should not be used beyond basic UI info. Transactions are not stored uniquely in memory,
/// so modifying [target] will not propogate to other instances correctly.
class Reimbursement {
  final Transaction target;
  final int value;

  /// Helper field to test if this reimbursement was newly added or has been commited to the
  /// database already. So reimbursements loaded from the database will have [commitedValue] = [value],
  /// while those in memory will have this at 0. Generally [Reimbursement] should not be kept alive
  /// in memory for that long though; this is only really used when editing a transaction.
  ///
  /// All transactions should be reloaded when any other transaction is changed too to reload the
  /// reimbursements.
  int commitedValue;

  Reimbursement({
    required this.target,
    required this.value,
    required this.commitedValue,
  });
}

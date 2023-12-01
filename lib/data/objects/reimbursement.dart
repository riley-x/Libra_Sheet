import 'package:libra_sheet/data/objects/transaction.dart';

/// WARNING [target] should not be used beyond basic UI info. Transactions are not stored uniquely in memory,
/// so modifying [target] will not propogate to other instances correctly.
class Reimbursement {
  final Transaction target;
  final int value;

  const Reimbursement({
    required this.target,
    required this.value,
  });
}

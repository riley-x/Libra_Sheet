import 'package:libra_sheet/data/objects/transaction.dart';

class Reimbursement {
  /// WARNING this can be null for newly added transactions!
  final Transaction? target;
  final int value;

  const Reimbursement({
    required this.target,
    required this.value,
  });
}

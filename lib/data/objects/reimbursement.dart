import 'package:libra_sheet/data/objects/transaction.dart';

class Reimbursement {
  /// WARNING this can be null for newly added transactions!
  final Transaction? parentTransaction;
  final Transaction? otherTransaction;
  final int value;

  const Reimbursement({
    required this.parentTransaction,
    required this.otherTransaction,
    required this.value,
  });
}

class MutableReimbursement implements Reimbursement {
  @override
  Transaction? parentTransaction;
  @override
  Transaction? otherTransaction;
  @override
  int value;

  MutableReimbursement({
    // this.parentTransaction,
    this.otherTransaction,
    this.value = 0,
  });

  Reimbursement freeze() => Reimbursement(
        parentTransaction: parentTransaction,
        otherTransaction: otherTransaction,
        value: value,
      );
}

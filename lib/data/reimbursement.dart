import 'package:libra_sheet/data/transaction.dart';

class Reimbursement {
  final Transaction parentTransaction;
  final Transaction otherTransaction;
  final int value;

  const Reimbursement({
    required this.parentTransaction,
    required this.otherTransaction,
    required this.value,
  });
}

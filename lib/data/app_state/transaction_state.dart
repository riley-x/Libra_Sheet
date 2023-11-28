import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// Helper class for managing transactions
class TransactionState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  TransactionState(this.appState);

  //----------------------------------------------------------------------------
  // Database Interface
  //----------------------------------------------------------------------------
  Future<void> saveAll(List<Transaction> transactions) async {}
}

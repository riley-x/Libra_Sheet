import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum TransactionDetailActiveFocus { none, allocation, reimbursement }

/// This state handles the TransactionDetailsEditor, allowing editing the state of a single
/// transaction.
class TransactionDetailsState extends ChangeNotifier {
  TransactionDetailsState(this.seed, {this.onSave, this.onDelete}) {
    _init();
  }

  final Function(Transaction)? onSave;
  final Function(Transaction)? onDelete;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> allocationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> reimbursementFormKey = GlobalKey<FormState>();

  /// Initial values for the respective editors. Don't edit these; they're used to reset.
  Transaction? seed;
  Allocation? focusedAllocation;
  Reimbursement? focusedReimbursement;

  /// Updated values for the respective editors. These are used to save the values retrieved from
  /// the various FormFields' onSave methods. They don't contain any UI state, so don't need to
  /// notifyListeners.
  /// TODO replace these with the now non-const version of the class
  final MutableAllocation updatedAllocation = MutableAllocation();
  final MutableReimbursement updatedReimbursement = MutableReimbursement();

  /// These variables are saved to by the relevant FormFields. Don't need to notifyListeners.
  Account? account;
  String? name;
  DateTime? date;
  int? value;
  Category? category;
  String? note;

  /// These variables are the state for the relevant fields
  ExpenseFilterType expenseType = ExpenseFilterType.all;
  final List<Tag> tags = [];
  final List<Allocation> allocations = [];
  final List<Reimbursement> reimbursements = [];
  TransactionDetailActiveFocus focus = TransactionDetailActiveFocus.none;

  /// Active target of the reimbursement editor
  Transaction? reimburseTarget;

  void _init() {
    if (seed != null) {
      expenseType = _valToFilterType(seed?.value);
      tags.insertAll(0, seed?.tags ?? const []);
      allocations.insertAll(0, seed?.allocations ?? const []);
      reimbursements.insertAll(0, seed?.reimbursements ?? const []);
    }
  }

  void replaceSeed(Transaction? t) {
    seed = t;
    reset();
  }

  void reset() {
    formKey.currentState?.reset();
    tags.clear();
    allocations.clear();
    reimbursements.clear();
    clearFocus();
    _init();
    notifyListeners();
  }

  void save() {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      if (name == null || date == null || value == null || note == null) {
        debugPrint("TransactionDetailsState:save() ERROR found null values!");
        return;
      }
      var t = Transaction(
        key: seed?.key ?? 0,
        name: name!,
        date: date!,
        value: value!,
        category: category,
        account: account,
        note: note!,
        allocations: allocations,
        reimbursements: reimbursements,
        tags: tags,
      );
      onSave?.call(t);
      // TODO save transaction; remember this state is used from the CSV screen too.
    }
  }

  void delete() {
    if (seed != null) onDelete?.call(seed!);
    // TODO remember this state is used from the CSV screen too.
  }

  void onValueChanged(int? val) {
    var newType = _valToFilterType(val);
    if (newType != expenseType) {
      expenseType = newType;
      notifyListeners();
    }
  }

  void onTagChanged(Tag tag, bool? selected) {
    if (selected == true) {
      tags.add(tag);
    } else {
      tags.remove(tag);
    }
    notifyListeners();
  }

  ExpenseFilterType _valToFilterType(int? val) {
    if (val == null || val == 0) {
      return ExpenseFilterType.all;
    } else if (val > 0) {
      return ExpenseFilterType.income;
    } else {
      return ExpenseFilterType.expense;
    }
  }

  void clearFocus() {
    focusedAllocation = null;
    focusedReimbursement = null;
    reimburseTarget = null;
    focus = TransactionDetailActiveFocus.none;
    notifyListeners();
  }

  void focusAllocation(Allocation? alloc) {
    if (focus == TransactionDetailActiveFocus.reimbursement) {
      focusedReimbursement = null;
    }
    focusedAllocation = alloc;
    focus = TransactionDetailActiveFocus.allocation;
    resetAllocation();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void saveAllocation() {
    if (allocationFormKey.currentState?.validate() ?? false) {
      allocationFormKey.currentState?.save();
      if (focusedAllocation == null) {
        allocations.add(updatedAllocation.freeze());
      } else {
        for (int i = 0; i < allocations.length; i++) {
          if (allocations[i] == focusedAllocation) {
            allocations[i] = updatedAllocation.freeze(allocations[i].key);
            break;
          }
        }
      }
      clearFocus();
    }
  }

  void deleteAllocation() {
    allocations.remove(focusedAllocation);
    clearFocus();
  }

  void resetAllocation() {
    allocationFormKey.currentState?.reset();
    notifyListeners();
  }

  void setReimbursementTarget(Transaction? it) {
    reimburseTarget = it;
    notifyListeners();
  }

  void focusReimbursement(Reimbursement? it) {
    if (focus == TransactionDetailActiveFocus.allocation) {
      focusedAllocation = null;
    }
    focusedReimbursement = it;
    reimburseTarget = it?.otherTransaction;
    focus = TransactionDetailActiveFocus.reimbursement;
    notifyListeners();
  }

  bool validateReimbursement() {
    bool out = reimbursementFormKey.currentState?.validate() ?? false;
    return out && reimburseTarget != null;
  }

  void saveReimbursement() {
    if (validateReimbursement()) {
      reimbursementFormKey.currentState?.save();
      updatedReimbursement.otherTransaction = reimburseTarget;
      updatedReimbursement.parentTransaction = seed;

      if (focusedReimbursement == null) {
        reimbursements.add(updatedReimbursement);
      } else {
        for (int i = 0; i < reimbursements.length; i++) {
          if (reimbursements[i] == focusedReimbursement) {
            reimbursements[i] = updatedReimbursement.freeze();
            break;
          }
        }
      }
      clearFocus();
    }
  }

  void deleteReimbursement() {
    reimbursements.remove(focusedReimbursement);
    reimburseTarget = null;
    clearFocus();
  }

  void resetReimbursement() {
    reimbursementFormKey.currentState?.reset();
    reimburseTarget = focusedReimbursement?.otherTransaction;
  }
}

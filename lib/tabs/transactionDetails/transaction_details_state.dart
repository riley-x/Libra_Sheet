import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum TransactionDetailActiveFocus { none, allocation, reimbursement }

/// This state handles the TransactionDetailsEditor, allowing editing the state of a single
/// transaction. Fields are initialized to [seed]. If null, assumes we're creating a new transaction
/// and fields are empty. If not null, assumes we're editing a transaction and fields are initialized
/// to the values in [seed].
class TransactionDetailsState extends ChangeNotifier {
  TransactionDetailsState(
    this.seed, {
    required this.appState,
    this.onSave,
    this.onDelete,
  }) {
    _init();
  }

  //---------------------------------------------------------------------------------------------
  // Config
  //---------------------------------------------------------------------------------------------
  final LibraAppState appState;
  final Function(Transaction?, Transaction)? onSave;
  final Function(Transaction)? onDelete;

  //---------------------------------------------------------------------------------------------
  // Form keys. These enable callbacks to the form state, like calling save() and reset().
  //---------------------------------------------------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> allocationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> reimbursementFormKey = GlobalKey<FormState>();

  //---------------------------------------------------------------------------------------------
  // Initial values for the respective editors. Don't edit these; they're used to reset.
  //---------------------------------------------------------------------------------------------
  Transaction? seed;
  Allocation? focusedAllocation;
  Reimbursement? focusedReimbursement;

  //---------------------------------------------------------------------------------------------
  // Updated values for the respective forms. These are used to save the values retrieved from
  // the various FormFields' onSave methods. They don't contain any UI state, so don't need to
  // notifyListeners.
  //---------------------------------------------------------------------------------------------
  /// Transaction editor
  Account? account;
  String? name;
  DateTime? date;
  int? value;
  Category? category;
  String? note;

  /// Reimbursement editor
  int reimbursementValue = 0;

  /// Allocation editor
  final MutableAllocation updatedAllocation =
      MutableAllocation(); // TODO replace these with the now non-const version of the class

  //---------------------------------------------------------------------------------------------
  // These variables are the UI state for the relevant fields. They are used to finalize the output
  // transaction too. Must notifyListeners() on update.
  //---------------------------------------------------------------------------------------------

  /// This is used to determine which categories to show in the dropdown lists, and the intial
  /// filter state of the reimbursement targets. It is set on each [onValueChanged].
  ExpenseFilterType expenseType = ExpenseFilterType.all;
  TransactionDetailActiveFocus focus = TransactionDetailActiveFocus.none;
  String? errorMessage;
  String? reimbursementError;
  bool saveAsRule = false;

  final List<Tag> tags = [];
  final List<Allocation> allocations = [];
  final List<Reimbursement> reimbursements = [];

  /// Current reimbursement target selected in the reimbursement editor.
  Transaction? reimburseTarget;

  //---------------------------------------------------------------------------------------------
  // Inits and resets
  //---------------------------------------------------------------------------------------------
  void _init() async {
    if (seed != null) {
      if (!seed!.relationsAreLoaded()) {
        await appState.transactions.loadRelations(seed!);
      }
      expenseType = _valToFilterType(seed?.value);
      tags.insertAll(0, seed?.tags ?? const []);
      allocations.insertAll(0, seed?.allocations ?? const []);
      reimbursements.insertAll(0, seed?.reimbursements ?? const []);
      notifyListeners();
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

  /// Reset just the allocation editor
  void resetAllocation() {
    allocationFormKey.currentState?.reset();
    notifyListeners();
  }

  /// Reset just the reimbursement editor
  void resetReimbursement() {
    reimbursementFormKey.currentState?.reset();
    reimburseTarget = focusedReimbursement?.target;
    reimbursementError = null;
    notifyListeners();
  }

  //---------------------------------------------------------------------------------------------
  // Deleting
  //---------------------------------------------------------------------------------------------
  void delete() {
    if (seed != null) onDelete?.call(seed!);
  }

  void deleteAllocation() {
    allocations.remove(focusedAllocation);
    clearFocus();
  }

  void deleteReimbursement() {
    reimbursements.remove(focusedReimbursement);
    reimburseTarget = null;
    clearFocus();
  }

  //---------------------------------------------------------------------------------------------
  // Saving
  //---------------------------------------------------------------------------------------------
  String? _validate() {
    if (formKey.currentState?.validate() != true) return "";
    // Need to save the form first to get the values. This doesn't do anything other than set the
    // save sink members above.
    formKey.currentState?.save();

    if (name == null ||
        date == null ||
        value == null ||
        note == null ||
        category == null ||
        account == null) {
      debugPrint("TransactionDetailsState:_validate() ERROR found null values!");
      return "Null values";
    }

    // Same category type
    if (!expenseType.inclusiveEqual(category!.type)) {
      return "Specified value does not have the correct sign for category ${category!.name}.";
    }

    // Here we check to make sure the allocations and reimbursements don't exceed the total value,
    // or otherwise lead to negative category values.
    var totalAdjustments = 0;
    for (final alloc in allocations) {
      if (!expenseType.inclusiveEqual(alloc.category!.type)) {
        return "Allocation ${alloc.name} must be an ${expenseType.name} category.";
      }
      totalAdjustments += alloc.value;
    }
    for (final reimb in reimbursements) {
      if (reimb.target.value * value! > 0) {
        const maxNameLength = 30;
        var name = reimb.target.name;
        if (name.length > maxNameLength) {
          name = '${name.substring(0, maxNameLength)}...';
        }
        return "Reimbursement $name must have a value of the opposite sign.";
      }
      totalAdjustments += reimb.value;
    }
    if (totalAdjustments > value!.abs()) {
      return "Total allocations and reimbursements (${totalAdjustments.dollarString()}) exceeds transaction value.";
    }

    return null;
  }

  void save() {
    String? err = _validate();
    if (err != null) {
      errorMessage = err;
      notifyListeners();
    } else {
      var t = Transaction(
        key: seed?.key ?? 0,
        name: name!,
        date: date!,
        value: value!,
        category: category ?? Category.empty,
        account: account,
        note: note!,
        allocations: List.from(allocations),
        reimbursements: List.from(reimbursements),
        tags: List.from(tags),
      );
      if (saveAsRule) {
        appState.rules.add(
          CategoryRule(
            pattern: t.name,
            category: category,
            type: ExpenseType.from(value!),
          ),
        );
      }
      onSave?.call(seed, t);
    }
  }

  /// Save a single allocation from the allocation editor in [allocations]
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

  /// Validates the form for the reimbursement editor only. Returns an error message, or null on
  /// success.
  String? validateReimbursement() {
    if (reimbursementFormKey.currentState?.validate() != true) return '';

    /// Need to save the form first to get the values. This doesn't do anything other than set the
    /// save sink members above.
    reimbursementFormKey.currentState?.save();

    if (reimburseTarget == null) {
      return "Please select a target transaction.";
    }
    if (_valToFilterType(reimburseTarget!.value) == expenseType) {
      return "Selected transaction must have the opposite sign.";
    }
    if (reimbursementValue > reimburseTarget!.value.abs()) {
      return "Value is greater than the selected transaction's value.";
    }
    // p.s. We check the current transaction's value on the global validate().

    /// Check to make sure the reimbursement value doesn't cause the other transaction to become
    /// negative
    if (reimburseTarget!.totalReimbusrements > 0) {
      final valueRemaining = reimburseTarget!.value.abs() - reimburseTarget!.totalReimbusrements;
      if (focusedReimbursement?.target == reimburseTarget) {
        // We're updating an existing reimbursement, so add back original value
        valueRemaining + focusedReimbursement!.commitedValue;
      }
      if (reimbursementValue > valueRemaining) {
        return "Total reimbursements on the selected transaction exceeds its value.";
      }
    }

    return null;
  }

  /// Save a single reimbursement from the allocation editor in [reimbursements]
  void saveReimbursement() {
    reimbursementError = validateReimbursement();
    if (reimbursementError == null) {
      final reimb = Reimbursement(
        target: reimburseTarget!,
        value: reimbursementValue,
        commitedValue: 0,
      );

      if (focusedReimbursement == null) {
        reimbursements.add(reimb);
      } else {
        for (int i = 0; i < reimbursements.length; i++) {
          if (reimbursements[i] == focusedReimbursement) {
            reimbursements[i] = reimb;
            break;
          }
        }
      }
      clearFocus();
    }
    notifyListeners();
  }

  //---------------------------------------------------------------------------------------------
  // Navigation
  //---------------------------------------------------------------------------------------------
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

  void focusReimbursement(Reimbursement? it) {
    if (focus == TransactionDetailActiveFocus.allocation) {
      focusedAllocation = null;
    }
    focusedReimbursement = it;
    reimburseTarget = it?.target;
    focus = TransactionDetailActiveFocus.reimbursement;
    resetReimbursement();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  //---------------------------------------------------------------------------------------------
  // Callbacks
  //---------------------------------------------------------------------------------------------
  ExpenseFilterType _valToFilterType(int? val) {
    if (val == null || val == 0) {
      return ExpenseFilterType.all;
    } else if (val > 0) {
      return ExpenseFilterType.income;
    } else {
      return ExpenseFilterType.expense;
    }
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

  void setReimbursementTarget(Transaction? it) {
    reimburseTarget = it;
    notifyListeners();
  }

  void toggleSaveRule() {
    saveAsRule = !saveAsRule;
    notifyListeners();
  }
}

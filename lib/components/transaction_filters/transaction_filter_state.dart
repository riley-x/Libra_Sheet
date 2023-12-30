import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// This class stores the common state for a TransactionFilterColumn and its corresponding transactions.
/// It handles the loading of the transactions and the UI state of the filter fields.
class TransactionFilterState extends ChangeNotifier {
  TransactionFilterState(
    this.service, {
    TransactionFilters? initialFilters,
    this.doLoads = true,
  }) : initialFilters = initialFilters ?? TransactionFilters() {
    filters = this.initialFilters.copy();
    service.addListener(loadTransactions);
    loadTransactions();
  }

  //----------------------------------------------------------------------
  // Config
  //----------------------------------------------------------------------
  /// Initial filters passed to the state on creation. Used for resetting.
  final TransactionFilters initialFilters;
  final TransactionService service;
  final bool doLoads;

  final TextEditingController nameController = TextEditingController();

  //----------------------------------------------------------------------
  // Overrides
  //----------------------------------------------------------------------
  /// This is necessary because the [TransactionFilterState] is often disposed when navigating between
  /// different screent that use a [TransactionFilterGrid], so [notifyListeners] might be called
  /// after being disposed.
  ///
  /// TODO this might just be because forgot to [removeListener]? Still needed?
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    service.removeListener(loadTransactions);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  //----------------------------------------------------------------------
  // UI State
  //----------------------------------------------------------------------

  /// Mutable filter list
  TransactionFilters filters = TransactionFilters();

  /// Error state for the text boxes
  bool startTimeError = false;
  bool endTimeError = false;
  bool minValueError = false;
  bool maxValueError = false;

  /// Loaded transactions
  List<Transaction> transactions = [];

  void loadTransactions() async {
    notifyListeners(); // for the UI form state
    if (!doLoads) return;
    transactions = await service.load(filters);
    notifyListeners();
  }

  //----------------------------------------------------------------------
  // Form callbacks
  //----------------------------------------------------------------------

  void setName(String? text) {
    filters.name = text;
    loadTransactions();
  }

  void setMinValue(String? text) {
    int? value;
    if (text == null || text.isEmpty) {
      value = null;
      minValueError = false;
    } else {
      value = text.toIntDollar();
      minValueError = value == null;
    }
    if (!minValueError) {
      filters.minValue = value;
      loadTransactions();
    } else {
      notifyListeners();
    }
  }

  void setMaxValue(String? text) {
    int? value;
    if (text == null || text.isEmpty) {
      value = null;
      maxValueError = false;
    } else {
      value = text.toIntDollar();
      maxValueError = value == null;
    }
    if (!maxValueError) {
      filters.maxValue = value;
      loadTransactions();
    } else {
      notifyListeners();
    }
  }

  (DateTime?, bool) _parseDate(String? text) {
    DateTime? time;
    bool error = false;
    if (text == null || text.isEmpty) {
      // pass
    } else {
      try {
        final format = DateFormat('MM/dd/yy');
        time = format.parse(text, true);
      } on FormatException {
        error = true;
      }
    }
    debugPrint('TransactionTabState::_parseDate() text:$text time=$time error=$error');
    return (time, error);
  }

  void setStartTime(DateTime? time, [bool load = true]) {
    filters.startTime = time;
    if (load) loadTransactions();
  }

  void setEndTime(DateTime? time, [bool load = true]) {
    filters.endTime = time;
    if (load) loadTransactions();
  }

  void parseStartTime(String? text) {
    final val = _parseDate(text);
    startTimeError = val.$2;
    if (!startTimeError) {
      setStartTime(val.$1);
    } else {
      notifyListeners();
    }
  }

  void parseEndTime(String? text, [bool load = true]) {
    final val = _parseDate(text);
    endTimeError = val.$2;
    if (!endTimeError) {
      setEndTime(val.$1);
    } else {
      notifyListeners();
    }
  }

  void setFilters(TransactionFilters filters) {
    this.filters = filters;
    nameController.text = filters.name ?? '';
    startTimeError = false;
    endTimeError = false;
    minValueError = false;
    maxValueError = false;
    loadTransactions();
  }

  void resetFilters() {
    setFilters(initialFilters.copy());
  }

  void setHasAllocation(bool? it) {
    filters.hasAllocation = it;
    loadTransactions();
  }

  void setHasReimbursement(bool? it) {
    filters.hasReimbursement = it;
    loadTransactions();
  }
}

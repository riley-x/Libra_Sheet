import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

class TransactionFilters {
  int? minValue;
  int? maxValue;
  DateTime? startTime;
  DateTime? endTime;
  Set<Account> accounts;
  CategoryTristateMap categories;
  Set<Tag> tags;
  int? limit;

  TransactionFilters({
    this.minValue,
    this.maxValue,
    this.startTime,
    this.endTime,
    Set<Account>? accounts,
    Set<Tag>? tags,
    CategoryTristateMap? categories,
    this.limit = 300,
  })  : accounts = accounts ?? {},
        tags = tags ?? {},
        categories = categories ?? CategoryTristateMap();
}

/// This class stores the common state for a TransactionFilterColumn and its corresponding transactions.
/// It handles the loading of the transactions and the UI state of the filter fields.
class TransactionFilterState extends ChangeNotifier {
  TransactionFilterState(
    this.service, {
    TransactionFilters? initialFilters,
    this.doLoads = true,
  }) {
    if (initialFilters != null) filters = initialFilters;
    service.addListener(loadTransactions);
    loadTransactions();
  }

  //----------------------------------------------------------------------
  // Config
  //----------------------------------------------------------------------
  final TransactionService service;
  final bool doLoads;

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

  void setStartTime(String? text) {
    final val = _parseDate(text);
    startTimeError = val.$2;
    if (!startTimeError) {
      filters.startTime = val.$1;
      loadTransactions();
    } else {
      notifyListeners();
    }
  }

  void setEndTime(String? text) {
    final val = _parseDate(text);
    endTimeError = val.$2;
    if (!endTimeError) {
      filters.endTime = val.$1;
      loadTransactions();
    } else {
      notifyListeners();
    }
  }

  void setFilters(TransactionFilters filters) {
    this.filters = filters;
    startTimeError = false;
    endTimeError = false;
    minValueError = false;
    maxValueError = false;
    loadTransactions();
  }
}

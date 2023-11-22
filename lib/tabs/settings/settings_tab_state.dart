/// These classes store the state of the various submenus in the settings tab. They need to be stored
/// above the settings tab itself so that when the LayoutBuilder changes, their state is preserved.

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';

/// State for the EditAccountsScreen
class EditAccountState extends ChangeNotifier {
  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;
  Account? focused;
  MutableAccount saveSink = MutableAccount();

  void setFocus(Account? it) {
    focused = it;
    isFocused = true;
    notifyListeners();
  }

  void clearFocus() {
    isFocused = false;
    notifyListeners();
  }
}

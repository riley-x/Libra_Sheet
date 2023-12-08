// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/test_data.dart';

/// Helper module for handling the tags
class TagState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  TagState(this.appState);

  final List<Tag> list = [];

  //----------------------------------------------------------------------------
  // Modification Functions
  //----------------------------------------------------------------------------
  Future<void> load() async {
    list.addAll(testTags);
    appState.notifyListeners();
  }

  Future<void> add(Tag tag) async {
    list.insert(0, tag);
    appState.notifyListeners();
  }

  Future<void> delete(Tag tag) async {
    list.removeWhere((it) => it.key == tag.key);
    appState.notifyListeners();
  }

  /// Tags are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(Tag tag) async {
    appState.notifyListeners();
  }

  //----------------------------------------------------------------------------
  // Retrieval
  //----------------------------------------------------------------------------

  Map<int, Tag> createKeyMap() {
    final out = <int, Tag>{};
    for (final tag in list) {
      out[tag.key] = tag;
    }
    return out;
  }
}

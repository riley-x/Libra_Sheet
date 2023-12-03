// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/objects/tag.dart';

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
    list.addAll(await LibraDatabase.db.getAllTags());
    appState.notifyListeners();
  }

  Future<void> add(Tag tag) async {
    int key = await LibraDatabase.db.insertTag(tag);
    tag = tag.copyWith(key: key);
    list.insert(0, tag);
    appState.notifyListeners();
  }

  Future<void> delete(Tag tag) async {
    list.removeWhere((it) => it.key == tag.key);
    appState.notifyListeners();
    await LibraDatabase.db.deleteTag(tag);
  }

  /// Tags are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(Tag tag) async {
    appState.notifyListeners();
    await LibraDatabase.db.updateTag(tag);
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

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
    list.clear();
    await LibraDatabase.read((db) async {
      list.addAll(await db.getAllTags());
    });
    appState.notifyListeners();
  }

  Future<void> add(Tag tag) async {
    final key = await LibraDatabase.update((db) => db.insertTag(tag, listIndex: list.length));
    if (key == null) return;
    tag = tag.copyWith(key: key);
    list.add(tag);
    appState.notifyListeners();
  }

  Future<void> delete(Tag tag) async {
    final oldLength = list.length;
    final ind = list.indexWhere((it) => it.key == tag.key);
    list.removeAt(ind);
    appState.notifyListeners();
    appState.transactions.notifyListeners();

    await LibraDatabase.backup(tag: '.before_delete_tag');
    await LibraDatabase.updateTransaction((txn) async {
      await txn.deleteTag(tag);
      await txn.shiftTagIndicies(ind + 1, oldLength, -1);
    });
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final acc = list.removeAt(oldIndex);
    if (newIndex > oldIndex) {
      list.insert(newIndex - 1, acc);
    } else {
      list.insert(newIndex, acc);
    }
    appState.notifyListeners();

    await LibraDatabase.updateTransaction((txn) async {
      if (newIndex > oldIndex) {
        await txn.shiftTagIndicies(oldIndex, newIndex, -1);
        await txn.updateTag(acc, listIndex: newIndex - 1);
      } else {
        await txn.shiftTagIndicies(newIndex, oldIndex, 1);
        await txn.updateTag(acc, listIndex: newIndex);
      }
    });
  }

  /// Tags are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(Tag tag) async {
    appState.notifyListeners();
    await LibraDatabase.update((db) async => await db.updateTag(tag));
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

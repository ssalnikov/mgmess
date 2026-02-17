import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/draft.dart';

class DraftStorage {
  static const _key = 'drafts';

  Future<void> saveDraft(Draft draft) async {
    if (draft.message.trim().isEmpty) {
      return deleteDraft(draft.channelId);
    }
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map[draft.channelId] = jsonEncode(draft.toJson());
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<Draft?> getDraft(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    final raw = map[channelId];
    if (raw == null) return null;
    return Draft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<Draft>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    final drafts = <Draft>[];
    for (final raw in map.values) {
      drafts.add(Draft.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  Future<void> deleteDraft(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readMap(prefs);
    map.remove(channelId);
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<int> getDraftCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _readMap(prefs).length;
  }

  Map<String, String> _readMap(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }
}

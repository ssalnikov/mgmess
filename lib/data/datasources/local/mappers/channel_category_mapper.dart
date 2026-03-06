import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../domain/entities/channel_category.dart';
import '../../../models/channel_category_model.dart';
import '../app_database.dart' as db;

class ChannelCategoryMapper {
  static db.ChannelCategoriesCompanion toCompanion(
      ChannelCategory category) {
    return db.ChannelCategoriesCompanion(
      id: Value(category.id),
      teamId: Value(category.teamId),
      userId: Value(category.userId),
      type: Value(ChannelCategory.typeToString(category.type)),
      displayName: Value(category.displayName),
      collapsed: Value(category.collapsed),
      channelIdsJson: Value(jsonEncode(category.channelIds)),
      sorting: Value(_sortingToString(category.sorting)),
      muted: Value(category.muted),
      sortOrder: Value(category.sortOrder),
    );
  }

  static ChannelCategoryModel fromEntry(db.ChannelCategory entry) {
    List<String> channelIds;
    try {
      channelIds = (jsonDecode(entry.channelIdsJson) as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } catch (_) {
      channelIds = [];
    }

    return ChannelCategoryModel(
      id: entry.id,
      teamId: entry.teamId,
      userId: entry.userId,
      type: ChannelCategory.typeFromString(entry.type),
      displayName: entry.displayName,
      collapsed: entry.collapsed,
      channelIds: channelIds,
      sorting: _sortingFromString(entry.sorting),
      muted: entry.muted,
      sortOrder: entry.sortOrder,
    );
  }

  static ChannelCategorySorting _sortingFromString(String sorting) {
    switch (sorting) {
      case 'alpha':
        return ChannelCategorySorting.alphabetical;
      case 'recent':
        return ChannelCategorySorting.recency;
      case 'manual':
        return ChannelCategorySorting.manual;
      default:
        return ChannelCategorySorting.default_;
    }
  }

  static String _sortingToString(ChannelCategorySorting sorting) {
    switch (sorting) {
      case ChannelCategorySorting.alphabetical:
        return 'alpha';
      case ChannelCategorySorting.recency:
        return 'recent';
      case ChannelCategorySorting.manual:
        return 'manual';
      case ChannelCategorySorting.default_:
        return 'default';
    }
  }
}

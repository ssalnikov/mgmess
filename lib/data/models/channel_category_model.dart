import 'dart:convert';

import '../../domain/entities/channel_category.dart';

class ChannelCategoryModel extends ChannelCategory {
  const ChannelCategoryModel({
    required super.id,
    super.teamId,
    super.userId,
    super.type,
    super.displayName,
    super.collapsed,
    super.channelIds,
    super.sorting,
    super.muted,
    super.sortOrder,
  });

  factory ChannelCategoryModel.fromJson(
    Map<String, dynamic> json, {
    int sortOrder = 0,
  }) {
    final channelIds = (json['channel_ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return ChannelCategoryModel(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: ChannelCategory.typeFromString(json['type'] as String? ?? ''),
      displayName: json['display_name'] as String? ?? '',
      collapsed: json['collapsed'] as bool? ?? false,
      channelIds: channelIds,
      sorting: _sortingFromString(json['sorting'] as String? ?? ''),
      muted: json['muted'] as bool? ?? false,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'type': ChannelCategory.typeToString(type),
        'display_name': displayName,
        'collapsed': collapsed,
        'channel_ids': channelIds,
        'sorting': _sortingToString(sorting),
        'muted': muted,
      };

  String get channelIdsJsonEncoded => jsonEncode(channelIds);

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

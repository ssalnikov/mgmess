import 'package:equatable/equatable.dart';

enum ChannelCategoryType { favorites, channels, directMessages, custom }

enum ChannelCategorySorting { alphabetical, recency, manual, default_ }

class ChannelCategory extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final ChannelCategoryType type;
  final String displayName;
  final bool collapsed;
  final List<String> channelIds;
  final ChannelCategorySorting sorting;
  final bool muted;
  final int sortOrder;

  const ChannelCategory({
    required this.id,
    this.teamId = '',
    this.userId = '',
    this.type = ChannelCategoryType.channels,
    this.displayName = '',
    this.collapsed = false,
    this.channelIds = const [],
    this.sorting = ChannelCategorySorting.default_,
    this.muted = false,
    this.sortOrder = 0,
  });

  ChannelCategory copyWith({
    bool? collapsed,
    List<String>? channelIds,
    ChannelCategorySorting? sorting,
  }) {
    return ChannelCategory(
      id: id,
      teamId: teamId,
      userId: userId,
      type: type,
      displayName: displayName,
      collapsed: collapsed ?? this.collapsed,
      channelIds: channelIds ?? this.channelIds,
      sorting: sorting ?? this.sorting,
      muted: muted,
      sortOrder: sortOrder,
    );
  }

  static ChannelCategoryType typeFromString(String type) {
    switch (type) {
      case 'favorites':
        return ChannelCategoryType.favorites;
      case 'channels':
        return ChannelCategoryType.channels;
      case 'direct_messages':
        return ChannelCategoryType.directMessages;
      case 'custom':
        return ChannelCategoryType.custom;
      default:
        return ChannelCategoryType.channels;
    }
  }

  static String typeToString(ChannelCategoryType type) {
    switch (type) {
      case ChannelCategoryType.favorites:
        return 'favorites';
      case ChannelCategoryType.channels:
        return 'channels';
      case ChannelCategoryType.directMessages:
        return 'direct_messages';
      case ChannelCategoryType.custom:
        return 'custom';
    }
  }

  @override
  List<Object?> get props => [id, collapsed, channelIds, sorting];
}

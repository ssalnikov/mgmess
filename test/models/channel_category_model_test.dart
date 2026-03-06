import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/channel_category_model.dart';
import 'package:mgmess/domain/entities/channel_category.dart';

void main() {
  group('ChannelCategoryModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'cat1',
        'team_id': 'team1',
        'user_id': 'user1',
        'type': 'channels',
        'display_name': 'Channels',
        'collapsed': false,
        'channel_ids': ['ch1', 'ch2', 'ch3'],
        'sorting': 'alpha',
        'muted': false,
      };

      final model = ChannelCategoryModel.fromJson(json);

      expect(model.id, 'cat1');
      expect(model.teamId, 'team1');
      expect(model.userId, 'user1');
      expect(model.type, ChannelCategoryType.channels);
      expect(model.displayName, 'Channels');
      expect(model.collapsed, false);
      expect(model.channelIds, ['ch1', 'ch2', 'ch3']);
      expect(model.sorting, ChannelCategorySorting.alphabetical);
      expect(model.muted, false);
    });

    test('fromJson handles favorites type', () {
      final json = {
        'id': 'cat2',
        'type': 'favorites',
        'display_name': 'Favorites',
        'channel_ids': ['ch1'],
        'sorting': 'manual',
      };

      final model = ChannelCategoryModel.fromJson(json);

      expect(model.type, ChannelCategoryType.favorites);
      expect(model.sorting, ChannelCategorySorting.manual);
    });

    test('fromJson handles direct_messages type', () {
      final json = {
        'id': 'cat3',
        'type': 'direct_messages',
        'display_name': 'Direct Messages',
        'channel_ids': ['dm1', 'dm2'],
        'sorting': 'recent',
      };

      final model = ChannelCategoryModel.fromJson(json);

      expect(model.type, ChannelCategoryType.directMessages);
      expect(model.sorting, ChannelCategorySorting.recency);
    });

    test('fromJson handles custom type', () {
      final json = {
        'id': 'cat4',
        'type': 'custom',
        'display_name': 'My Custom Category',
        'channel_ids': [],
        'sorting': 'default',
        'collapsed': true,
      };

      final model = ChannelCategoryModel.fromJson(json);

      expect(model.type, ChannelCategoryType.custom);
      expect(model.sorting, ChannelCategorySorting.default_);
      expect(model.collapsed, true);
      expect(model.channelIds, isEmpty);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{
        'id': 'cat5',
      };

      final model = ChannelCategoryModel.fromJson(json);

      expect(model.id, 'cat5');
      expect(model.teamId, '');
      expect(model.userId, '');
      expect(model.type, ChannelCategoryType.channels);
      expect(model.displayName, '');
      expect(model.collapsed, false);
      expect(model.channelIds, isEmpty);
      expect(model.sorting, ChannelCategorySorting.default_);
      expect(model.muted, false);
    });

    test('fromJson with sortOrder sets sort order', () {
      final json = {
        'id': 'cat6',
        'type': 'channels',
        'channel_ids': [],
      };

      final model = ChannelCategoryModel.fromJson(json, sortOrder: 3);

      expect(model.sortOrder, 3);
    });

    test('toJson serializes correctly', () {
      const model = ChannelCategoryModel(
        id: 'cat1',
        teamId: 'team1',
        userId: 'user1',
        type: ChannelCategoryType.channels,
        displayName: 'Channels',
        collapsed: false,
        channelIds: ['ch1', 'ch2'],
        sorting: ChannelCategorySorting.alphabetical,
        muted: false,
      );

      final json = model.toJson();

      expect(json['id'], 'cat1');
      expect(json['team_id'], 'team1');
      expect(json['type'], 'channels');
      expect(json['sorting'], 'alpha');
      expect(json['channel_ids'], ['ch1', 'ch2']);
      expect(json['collapsed'], false);
    });

    test('toJson roundtrip', () {
      const original = ChannelCategoryModel(
        id: 'cat_rt',
        teamId: 'team1',
        userId: 'user1',
        type: ChannelCategoryType.favorites,
        displayName: 'Favorites',
        collapsed: true,
        channelIds: ['ch1', 'ch2', 'ch3'],
        sorting: ChannelCategorySorting.recency,
        muted: true,
      );

      final json = original.toJson();
      final restored = ChannelCategoryModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.collapsed, original.collapsed);
      expect(restored.channelIds, original.channelIds);
      expect(restored.sorting, original.sorting);
      expect(restored.muted, original.muted);
    });
  });
}

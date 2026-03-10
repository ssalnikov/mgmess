import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/channel_category_model.dart';
import '../../models/channel_model.dart';
import '../../models/channel_stats_model.dart';

class ChannelRemoteDataSource {
  final ApiClient _apiClient;

  ChannelRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<ChannelModel>> getChannelsForUser(
    String userId,
    String teamId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelsForUser(userId, teamId),
      );
      return (response.data as List<dynamic>)
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get channels: $e');
    }
  }

  Future<ChannelModel> getChannel(String channelId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.channel(channelId));
      return ChannelModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get channel: $e');
    }
  }

  Future<Map<String, dynamic>> getChannelMember(
    String channelId,
    String userId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelMember(channelId, userId),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ServerException(
          message: 'Failed to get channel member: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChannelMembersForUser(
    String userId,
    String teamId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelMembersForUser(userId, teamId),
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Failed to get channel members: $e');
    }
  }

  Future<void> viewChannel(String userId, String channelId) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.channelViewForUser(userId),
        data: {'channel_id': channelId},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to view channel: $e');
    }
  }

  Future<void> updateChannelNotifyProps(
    String channelId,
    String userId,
    Map<String, String> notifyProps,
  ) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.channelMemberNotifyProps(channelId, userId),
        data: notifyProps,
      );
    } catch (e) {
      throw ServerException(
          message: 'Failed to update notify props: $e');
    }
  }

  Future<ChannelModel> createDirectChannel(
    String userId,
    String otherUserId,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.directChannel,
        data: [userId, otherUserId],
      );
      return ChannelModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(
          message: 'Failed to create direct channel: $e');
    }
  }

  Future<ChannelModel> createChannel({
    required String teamId,
    required String name,
    required String displayName,
    required String type,
    String purpose = '',
    String header = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.channels,
        data: {
          'team_id': teamId,
          'name': name,
          'display_name': displayName,
          'type': type,
          if (purpose.isNotEmpty) 'purpose': purpose,
          if (header.isNotEmpty) 'header': header,
        },
      );
      return ChannelModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to create channel: $e');
    }
  }

  Future<ChannelModel> createGroupChannel(List<String> userIds) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.groupChannel,
        data: userIds,
      );
      return ChannelModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(
          message: 'Failed to create group channel: $e');
    }
  }

  Future<ChannelStatsModel> getChannelStats(String channelId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelStats(channelId),
      );
      return ChannelStatsModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get channel stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChannelMembers(
    String channelId, {
    int page = 0,
    int perPage = 60,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelMembers(channelId),
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Failed to get channel members: $e');
    }
  }

  Future<void> leaveChannel(String channelId, String userId) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.channelMember(channelId, userId),
      );
    } catch (e) {
      throw ServerException(message: 'Failed to leave channel: $e');
    }
  }

  Future<void> removeChannelMember(String channelId, String userId) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.channelMember(channelId, userId),
      );
    } catch (e) {
      throw ServerException(message: 'Failed to remove channel member: $e');
    }
  }

  Future<void> addChannelMember(String channelId, String userId) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.channelMembers(channelId),
        data: {'user_id': userId},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to add channel member: $e');
    }
  }

  Future<void> updateChannelMemberSchemeRoles(
    String channelId,
    String userId, {
    required bool schemeAdmin,
  }) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.channelMemberSchemeRoles(channelId, userId),
        data: {
          'scheme_user': true,
          'scheme_admin': schemeAdmin,
        },
      );
    } catch (e) {
      throw ServerException(
          message: 'Failed to update member roles: $e');
    }
  }

  Future<ChannelModel> updateChannel(
    String channelId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.channelPatch(channelId),
        data: data,
      );
      return ChannelModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to update channel: $e');
    }
  }

  Future<List<ChannelCategoryModel>> getChannelCategories(
    String userId,
    String teamId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelCategories(userId, teamId),
      );
      final data = response.data as Map<String, dynamic>;
      final categories = data['categories'] as List<dynamic>? ?? [];
      final order = (data['order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      final models = categories
          .map((c) => ChannelCategoryModel.fromJson(c as Map<String, dynamic>))
          .toList();

      // Apply server-defined order
      if (order.isNotEmpty) {
        final orderMap = <String, int>{};
        for (var i = 0; i < order.length; i++) {
          orderMap[order[i]] = i;
        }
        models.sort((a, b) {
          final ai = orderMap[a.id] ?? 999;
          final bi = orderMap[b.id] ?? 999;
          return ai.compareTo(bi);
        });
        // Set sortOrder based on position
        return [
          for (var i = 0; i < models.length; i++)
            ChannelCategoryModel(
              id: models[i].id,
              teamId: models[i].teamId,
              userId: models[i].userId,
              type: models[i].type,
              displayName: models[i].displayName,
              collapsed: models[i].collapsed,
              channelIds: models[i].channelIds,
              sorting: models[i].sorting,
              muted: models[i].muted,
              sortOrder: i,
            ),
        ];
      }
      return models;
    } catch (e) {
      throw ServerException(message: 'Failed to get channel categories: $e');
    }
  }

  Future<void> updateChannelCategory(
    String userId,
    String teamId,
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.channelCategory(userId, teamId, categoryId),
        data: data,
      );
    } catch (e) {
      throw ServerException(
          message: 'Failed to update channel category: $e');
    }
  }

  Future<List<ChannelModel>> getCommonChannels(
    String userId,
    String otherUserId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.commonChannels(userId, otherUserId),
      );
      return (response.data as List<dynamic>)
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get common channels: $e');
    }
  }

  /// Returns the default_channel_user_role name from the scheme.
  Future<String> getSchemeUserRoleName(String schemeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.scheme(schemeId),
      );
      final data = response.data as Map<String, dynamic>;
      return data['default_channel_user_role'] as String? ?? '';
    } catch (e) {
      throw ServerException(message: 'Failed to get scheme: $e');
    }
  }

  /// Returns the list of permissions for a given role name.
  Future<List<String>> getRolePermissions(String roleName) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.roleByName(roleName),
      );
      final data = response.data as Map<String, dynamic>;
      final permissions = data['permissions'] as List<dynamic>? ?? [];
      return permissions.cast<String>();
    } catch (e) {
      throw ServerException(message: 'Failed to get role: $e');
    }
  }

  Future<List<ChannelModel>> autocompleteChannels(
    String teamId,
    String term,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelsAutocomplete,
        queryParameters: {'team_id': teamId, 'name': term},
      );
      return (response.data as List<dynamic>)
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(
          message: 'Failed to autocomplete channels: $e');
    }
  }
}

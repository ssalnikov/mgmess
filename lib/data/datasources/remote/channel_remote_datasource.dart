import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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

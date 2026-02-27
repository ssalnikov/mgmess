import '../../../core/error/exceptions.dart';
import '../../../domain/entities/channel.dart';
import '../../models/channel_model.dart';
import 'daos/channel_dao.dart';
import 'mappers/channel_mapper.dart';

class ChannelLocalDataSource {
  final ChannelDao _dao;

  ChannelLocalDataSource({required ChannelDao dao}) : _dao = dao;

  Future<void> cacheChannels(List<Channel> channels) async {
    try {
      final companions =
          channels.map((c) => ChannelMapper.toCompanion(c)).toList();
      await _dao.upsertChannels(companions);
    } catch (e) {
      throw CacheException(message: 'Failed to cache channels: $e');
    }
  }

  Future<List<ChannelModel>> getAllChannels() async {
    try {
      final entries = await _dao.getAllChannels();
      return entries.map(ChannelMapper.fromEntry).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached channels: $e');
    }
  }

  Future<ChannelModel?> getChannel(String id) async {
    try {
      final entry = await _dao.getChannel(id);
      if (entry == null) return null;
      return ChannelMapper.fromEntry(entry);
    } catch (e) {
      throw CacheException(message: 'Failed to get cached channel: $e');
    }
  }

  Future<void> updateMembership({
    required String channelId,
    int? msgCount,
    int? mentionCount,
    int? lastViewedAt,
    bool? isMuted,
  }) async {
    try {
      await _dao.updateMembership(
        channelId: channelId,
        msgCount: msgCount,
        mentionCount: mentionCount,
        lastViewedAt: lastViewedAt,
        isMuted: isMuted,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to update membership: $e');
    }
  }
}

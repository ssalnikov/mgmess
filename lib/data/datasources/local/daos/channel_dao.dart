import 'package:drift/drift.dart';

import '../app_database.dart';

class ChannelDao {
  final AppDatabase _db;

  ChannelDao(this._db);

  Future<void> upsertChannels(List<ChannelsCompanion> channels) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.channels, channels);
    });
  }

  Future<List<Channel>> getAllChannels() async {
    return (_db.select(_db.channels)
          ..orderBy([(t) => OrderingTerm.desc(t.lastPostAt)]))
        .get();
  }

  Future<Channel?> getChannel(String id) async {
    return (_db.select(_db.channels)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateMembership({
    required String channelId,
    int? msgCount,
    int? mentionCount,
    int? lastViewedAt,
    bool? isMuted,
  }) async {
    final companion = ChannelsCompanion(
      msgCount: msgCount != null ? Value(msgCount) : const Value.absent(),
      mentionCount:
          mentionCount != null ? Value(mentionCount) : const Value.absent(),
      lastViewedAt:
          lastViewedAt != null ? Value(lastViewedAt) : const Value.absent(),
      isMuted: isMuted != null ? Value(isMuted) : const Value.absent(),
    );

    await (_db.update(_db.channels)..where((t) => t.id.equals(channelId)))
        .write(companion);
  }
}

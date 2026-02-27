import 'package:drift/drift.dart';

import '../../../../domain/entities/channel.dart';
import '../../../models/channel_model.dart';
import '../app_database.dart' as db;

class ChannelMapper {
  static db.ChannelsCompanion toCompanion(Channel channel) {
    return db.ChannelsCompanion(
      id: Value(channel.id),
      teamId: Value(channel.teamId),
      name: Value(channel.name),
      displayName: Value(channel.displayName),
      header: Value(channel.header),
      purpose: Value(channel.purpose),
      type: Value(_typeToString(channel.type)),
      createAt: Value(channel.createAt),
      updateAt: Value(channel.updateAt),
      deleteAt: Value(channel.deleteAt),
      totalMsgCount: Value(channel.totalMsgCount),
      lastPostAt: Value(channel.lastPostAt),
      msgCount: Value(channel.msgCount),
      mentionCount: Value(channel.mentionCount),
      lastViewedAt: Value(channel.lastViewedAt),
      isMuted: Value(channel.isMuted),
    );
  }

  static ChannelModel fromEntry(db.Channel entry) {
    return ChannelModel(
      id: entry.id,
      teamId: entry.teamId,
      name: entry.name,
      displayName: entry.displayName,
      header: entry.header,
      purpose: entry.purpose,
      type: Channel.typeFromString(entry.type),
      createAt: entry.createAt,
      updateAt: entry.updateAt,
      deleteAt: entry.deleteAt,
      totalMsgCount: entry.totalMsgCount,
      lastPostAt: entry.lastPostAt,
      msgCount: entry.msgCount,
      mentionCount: entry.mentionCount,
      lastViewedAt: entry.lastViewedAt,
      isMuted: entry.isMuted,
    );
  }

  static String _typeToString(ChannelType type) {
    switch (type) {
      case ChannelType.open:
        return 'O';
      case ChannelType.private_:
        return 'P';
      case ChannelType.direct:
        return 'D';
      case ChannelType.group:
        return 'G';
    }
  }
}

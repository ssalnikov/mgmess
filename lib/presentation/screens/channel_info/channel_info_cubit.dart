import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_member.dart';
import '../../../domain/entities/channel_stats.dart';
import '../../../domain/repositories/channel_repository.dart';

// States

abstract class ChannelInfoState extends Equatable {
  const ChannelInfoState();

  @override
  List<Object?> get props => [];
}

class ChannelInfoInitial extends ChannelInfoState {
  const ChannelInfoInitial();
}

class ChannelInfoLoading extends ChannelInfoState {
  const ChannelInfoLoading();
}

class ChannelInfoLoaded extends ChannelInfoState {
  final Channel channel;
  final ChannelStats stats;
  final List<ChannelMember> memberPreview;

  const ChannelInfoLoaded({
    required this.channel,
    required this.stats,
    this.memberPreview = const [],
  });

  @override
  List<Object?> get props => [channel, stats, memberPreview];
}

class ChannelInfoError extends ChannelInfoState {
  final String message;

  const ChannelInfoError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit

class ChannelInfoCubit extends Cubit<ChannelInfoState> {
  final ChannelRepository _channelRepository;

  ChannelInfoCubit({
    required ChannelRepository channelRepository,
  })  : _channelRepository = channelRepository,
        super(const ChannelInfoInitial());

  Future<void> loadChannelInfo(String channelId) async {
    emit(const ChannelInfoLoading());

    final results = await Future.wait([
      _channelRepository.getChannel(channelId),
      _channelRepository.getChannelStats(channelId),
      _channelRepository.getChannelMembers(channelId, page: 0, perPage: 5),
    ]);

    final channelResult = results[0];
    final statsResult = results[1];
    final membersResult = results[2];

    // Channel is required
    channelResult.fold(
      (failure) => emit(ChannelInfoError(message: failure.message)),
      (channel) {
        final ch = channel as Channel;
        final stats = statsResult.fold(
          (_) => ChannelStats(channelId: channelId),
          (s) => s as ChannelStats,
        );
        final members = membersResult.fold(
          (_) => <ChannelMember>[],
          (m) => m as List<ChannelMember>,
        );
        emit(ChannelInfoLoaded(
          channel: ch,
          stats: stats,
          memberPreview: members,
        ));
      },
    );
  }

  Future<void> leaveChannel(String channelId, String userId) async {
    final result = await _channelRepository.leaveChannel(channelId, userId);
    result.fold(
      (failure) => emit(ChannelInfoError(message: failure.message)),
      (_) {}, // Navigation handled by the screen
    );
  }

  Future<void> toggleMute(
    String channelId,
    String userId,
    bool currentlyMuted,
  ) async {
    final result = currentlyMuted
        ? await _channelRepository.unmuteChannel(channelId, userId)
        : await _channelRepository.muteChannel(channelId, userId);
    result.fold(
      (failure) => emit(ChannelInfoError(message: failure.message)),
      (_) => loadChannelInfo(channelId),
    );
  }
}

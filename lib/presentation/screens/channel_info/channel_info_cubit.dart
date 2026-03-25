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
  final bool isCurrentUserAdmin;
  final bool isReadOnly;

  const ChannelInfoLoaded({
    required this.channel,
    required this.stats,
    this.memberPreview = const [],
    this.isCurrentUserAdmin = false,
    this.isReadOnly = false,
  });

  @override
  List<Object?> get props => [channel, stats, memberPreview, isCurrentUserAdmin, isReadOnly];
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

  Future<void> loadChannelInfo(
    String channelId, {
    String currentUserId = '',
  }) async {
    emit(const ChannelInfoLoading());

    final futures = <Future>[
      _channelRepository.getChannel(channelId),
      _channelRepository.getChannelStats(channelId),
      _channelRepository.getChannelMembers(channelId, page: 0, perPage: 5),
      if (currentUserId.isNotEmpty)
        _channelRepository.getChannelMemberInfo(channelId, currentUserId),
      if (currentUserId.isNotEmpty)
        _channelRepository.canUserPost(channelId, currentUserId),
    ];

    final results = await Future.wait(futures);

    final channelResult = results[0];
    final statsResult = results[1];
    final membersResult = results[2];

    // Channel is required
    channelResult.fold(
      (failure) => emit(ChannelInfoError(message: failure.message)),
      (channel) {
        var ch = channel as Channel;
        final stats = statsResult.fold(
          (_) => ChannelStats(channelId: channelId),
          (s) => s as ChannelStats,
        );
        final members = membersResult.fold(
          (_) => <ChannelMember>[],
          (m) => m as List<ChannelMember>,
        );
        var isAdmin = false;
        var isReadOnly = false;
        if (currentUserId.isNotEmpty && results.length > 3) {
          results[3].fold(
            (_) {},
            (info) {
              final memberInfo =
                  info as ({String roles, bool isMuted});
              isAdmin = memberInfo.roles.contains('channel_admin');
              ch = ch.copyWith(isMuted: memberInfo.isMuted);
            },
          );
        }
        if (currentUserId.isNotEmpty && results.length > 4) {
          results[4].fold(
            (_) {},
            (canPost) {
              isReadOnly = canPost == false;
            },
          );
        }
        emit(ChannelInfoLoaded(
          channel: ch,
          stats: stats,
          memberPreview: members,
          isCurrentUserAdmin: isAdmin,
          isReadOnly: isReadOnly,
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

  Future<bool> updateChannel(
    String channelId,
    Map<String, dynamic> data,
  ) async {
    final result = await _channelRepository.updateChannel(channelId, data);
    return result.fold(
      (failure) {
        emit(ChannelInfoError(message: failure.message));
        return false;
      },
      (_) => true,
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
      (_) => loadChannelInfo(channelId, currentUserId: userId),
    );
  }
}

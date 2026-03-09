import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';

class CustomStatus extends Equatable {
  final String emoji;
  final String text;

  const CustomStatus({required this.emoji, required this.text});

  bool get isEmpty => emoji.isEmpty && text.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [emoji, text];
}

class UserStatusState extends Equatable {
  final Map<String, String> statuses;
  final Map<String, CustomStatus> customStatuses;
  final Map<String, int> lastActivity;

  const UserStatusState({
    this.statuses = const {},
    this.customStatuses = const {},
    this.lastActivity = const {},
  });

  UserStatusState copyWith({
    Map<String, String>? statuses,
    Map<String, CustomStatus>? customStatuses,
    Map<String, int>? lastActivity,
  }) {
    return UserStatusState(
      statuses: statuses ?? this.statuses,
      customStatuses: customStatuses ?? this.customStatuses,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  List<Object?> get props => [statuses, customStatuses, lastActivity];
}

class UserStatusCubit extends Cubit<UserStatusState> {
  final UserRepository _userRepository;
  StreamSubscription<WsEvent>? _wsSub;

  final Set<String> _pendingIds = {};
  Timer? _batchTimer;

  UserStatusCubit({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const UserStatusState());

  void subscribeToWs(Stream<WsEvent> wsEvents) {
    _wsSub?.cancel();
    _wsSub = wsEvents.listen((event) {
      if (event.event == WsEventType.hello) {
        _refreshAllStatuses();
      } else if (event.event == WsEventType.statusChange) {
        final userId = event.data['user_id'] as String?;
        final status = event.data['status'] as String?;
        if (userId != null && status != null) {
          final updated = Map<String, String>.from(state.statuses);
          updated[userId] = status;
          emit(state.copyWith(statuses: updated));
        }
      } else if (event.event == WsEventType.userUpdated) {
        final userJson = event.data['user'] as Map<String, dynamic>?;
        if (userJson != null) {
          final user = UserModel.fromJson(userJson);
          _updateCustomStatusFromUser(user);
        }
      }
    });
  }

  Future<void> _refreshAllStatuses() async {
    final userIds = state.statuses.keys.toList();
    if (userIds.isEmpty) return;
    final result = await _userRepository.getUserStatuses(userIds);
    result.fold(
      (_) {},
      (data) {
        final updatedActivity = Map<String, int>.from(state.lastActivity);
        updatedActivity.addAll(data.lastActivity);
        emit(state.copyWith(
          statuses: data.statuses,
          lastActivity: updatedActivity,
        ));
      },
    );
  }

  void _updateCustomStatusFromUser(User user) {
    final updated = Map<String, CustomStatus>.from(state.customStatuses);
    if (user.customStatusEmoji.isEmpty && user.customStatusText.isEmpty) {
      updated.remove(user.id);
    } else {
      updated[user.id] = CustomStatus(
        emoji: user.customStatusEmoji,
        text: user.customStatusText,
      );
    }
    emit(state.copyWith(customStatuses: updated));
  }

  void setCustomStatusFromUser(User user) {
    _updateCustomStatusFromUser(user);
  }

  Future<void> fetchStatuses(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final result = await _userRepository.getUserStatuses(userIds);
    result.fold(
      (_) {},
      (data) {
        final updated = Map<String, String>.from(state.statuses);
        updated.addAll(data.statuses);
        final updatedActivity = Map<String, int>.from(state.lastActivity);
        updatedActivity.addAll(data.lastActivity);
        emit(state.copyWith(
          statuses: updated,
          lastActivity: updatedActivity,
        ));
      },
    );
  }

  Future<void> updateStatus(String userId, String status) async {
    final previous = state.statuses[userId];
    final updated = Map<String, String>.from(state.statuses);
    updated[userId] = status;
    emit(state.copyWith(statuses: updated));

    final result = await _userRepository.updateUserStatus(userId, status);
    result.fold(
      (_) {
        // Rollback on error
        final rollback = Map<String, String>.from(state.statuses);
        if (previous != null) {
          rollback[userId] = previous;
        } else {
          rollback.remove(userId);
        }
        emit(state.copyWith(statuses: rollback));
      },
      (_) {},
    );
  }

  Future<void> updateCustomStatus(
    String userId, {
    required String emoji,
    required String text,
  }) async {
    final previous = state.customStatuses[userId];
    final updated = Map<String, CustomStatus>.from(state.customStatuses);
    updated[userId] = CustomStatus(emoji: emoji, text: text);
    emit(state.copyWith(customStatuses: updated));

    final result = await _userRepository.updateCustomStatus(
      userId,
      emoji: emoji,
      text: text,
    );
    result.fold(
      (_) {
        final rollback = Map<String, CustomStatus>.from(state.customStatuses);
        if (previous != null) {
          rollback[userId] = previous;
        } else {
          rollback.remove(userId);
        }
        emit(state.copyWith(customStatuses: rollback));
      },
      (_) {},
    );
  }

  Future<void> clearCustomStatus(String userId) async {
    final previous = state.customStatuses[userId];
    final updated = Map<String, CustomStatus>.from(state.customStatuses);
    updated.remove(userId);
    emit(state.copyWith(customStatuses: updated));

    final result = await _userRepository.deleteCustomStatus(userId);
    result.fold(
      (_) {
        if (previous != null) {
          final rollback = Map<String, CustomStatus>.from(state.customStatuses);
          rollback[userId] = previous;
          emit(state.copyWith(customStatuses: rollback));
        }
      },
      (_) {},
    );
  }

  void requestStatus(String userId) {
    if (state.statuses.containsKey(userId)) return;
    _pendingIds.add(userId);
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 100), () {
      final ids = _pendingIds.toList();
      _pendingIds.clear();
      if (ids.isNotEmpty) fetchStatuses(ids);
    });
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _batchTimer?.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../domain/repositories/user_repository.dart';

class UserStatusState extends Equatable {
  final Map<String, String> statuses;

  const UserStatusState({this.statuses = const {}});

  UserStatusState copyWith({Map<String, String>? statuses}) {
    return UserStatusState(statuses: statuses ?? this.statuses);
  }

  @override
  List<Object?> get props => [statuses];
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
      if (event.event == WsEventType.statusChange) {
        final userId = event.data['user_id'] as String?;
        final status = event.data['status'] as String?;
        if (userId != null && status != null) {
          final updated = Map<String, String>.from(state.statuses);
          updated[userId] = status;
          emit(state.copyWith(statuses: updated));
        }
      }
    });
  }

  Future<void> fetchStatuses(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final result = await _userRepository.getUserStatuses(userIds);
    result.fold(
      (_) {},
      (statuses) {
        final updated = Map<String, String>.from(state.statuses);
        updated.addAll(statuses);
        emit(state.copyWith(statuses: updated));
      },
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

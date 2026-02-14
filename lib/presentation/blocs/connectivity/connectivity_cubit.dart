import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/network_info.dart';

class ConnectivityState {
  final bool isConnected;

  const ConnectivityState({this.isConnected = true});
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({required NetworkInfo networkInfo})
      : _networkInfo = networkInfo,
        super(const ConnectivityState()) {
    _init();
  }

  void _init() {
    _subscription = _networkInfo.onConnectivityChanged.listen((connected) {
      emit(ConnectivityState(isConnected: connected));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

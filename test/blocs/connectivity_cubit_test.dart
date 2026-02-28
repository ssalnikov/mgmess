import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/presentation/blocs/connectivity/connectivity_cubit.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    connectivityController = StreamController<bool>.broadcast();
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    connectivityController.close();
  });

  group('ConnectivityCubit', () {
    test('initial state is connected', () {
      final cubit = ConnectivityCubit(networkInfo: mockNetworkInfo);
      expect(cubit.state.isConnected, true);
      cubit.close();
    });

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits disconnected when connectivity changes to false',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) => connectivityController.add(false),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', false),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits connected when connectivity changes to true',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) {
        connectivityController.add(false);
        connectivityController.add(true);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', false),
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', true),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'emits multiple state changes in sequence',
      build: () => ConnectivityCubit(networkInfo: mockNetworkInfo),
      act: (cubit) {
        connectivityController.add(false);
        connectivityController.add(true);
        connectivityController.add(false);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', false),
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', true),
        isA<ConnectivityState>()
            .having((s) => s.isConnected, 'isConnected', false),
      ],
    );

    test('cancels subscription on close', () async {
      final cubit = ConnectivityCubit(networkInfo: mockNetworkInfo);
      await cubit.close();

      // After close, emitting should not cause errors
      connectivityController.add(false);
      await Future.delayed(const Duration(milliseconds: 50));
      // No exception = success
    });
  });
}

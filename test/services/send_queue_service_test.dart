import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/data/datasources/local/post_local_datasource.dart';
import 'package:mgmess/data/datasources/remote/post_remote_datasource.dart';
import 'package:mgmess/data/models/post_model.dart';
import 'package:mgmess/data/services/send_queue_service.dart';

class MockPostLocalDataSource extends Mock implements PostLocalDataSource {}

class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockPostLocalDataSource mockLocal;
  late MockPostRemoteDataSource mockRemote;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<bool> connectivityController;
  late SendQueueService service;

  const pendingPost1 = PostModel(
    id: 'pending_1',
    channelId: 'ch1',
    userId: '',
    message: 'Hello',
    rootId: '',
    fileIds: [],
    priority: '',
  );

  const pendingPost2 = PostModel(
    id: 'pending_2',
    channelId: 'ch2',
    userId: '',
    message: 'World',
    rootId: 'root1',
    fileIds: ['file1'],
    priority: 'urgent',
  );

  const sentPost = PostModel(
    id: 'real_1',
    channelId: 'ch1',
    userId: 'user1',
    message: 'Hello',
  );

  setUp(() {
    mockLocal = MockPostLocalDataSource();
    mockRemote = MockPostRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    connectivityController = StreamController<bool>.broadcast();

    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    service.dispose();
    connectivityController.close();
  });

  group('SendQueueService', () {
    group('start', () {
      test('subscribes to connectivity and processes immediately', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => []);

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockNetworkInfo.isConnected).called(1);
        verify(() => mockLocal.getPendingPosts()).called(1);
      });
    });

    group('processPendingPosts when connected', () {
      test('sends each pending post and marks as sent', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => [pendingPost1]);
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenAnswer((_) async => sentPost);
        when(() => mockLocal.markAsSent(any()))
            .thenAnswer((_) async {});

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockRemote.createPost(
              channelId: 'ch1',
              message: 'Hello',
              rootId: null,
              fileIds: null,
              priority: null,
            )).called(1);
        verify(() => mockLocal.markAsSent('pending_1')).called(1);
      });

      test('converts empty rootId/fileIds/priority to null', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => [pendingPost1]);
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenAnswer((_) async => sentPost);
        when(() => mockLocal.markAsSent(any()))
            .thenAnswer((_) async {});

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        // pendingPost1 has empty rootId, empty fileIds, empty priority
        verify(() => mockRemote.createPost(
              channelId: 'ch1',
              message: 'Hello',
              rootId: null,
              fileIds: null,
              priority: null,
            )).called(1);
      });

      test('passes non-empty rootId/fileIds/priority as-is', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => [pendingPost2]);
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenAnswer((_) async => sentPost);
        when(() => mockLocal.markAsSent(any()))
            .thenAnswer((_) async {});

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockRemote.createPost(
              channelId: 'ch2',
              message: 'World',
              rootId: 'root1',
              fileIds: ['file1'],
              priority: 'urgent',
            )).called(1);
      });
    });

    group('processPendingPosts when disconnected', () {
      test('does not send any posts', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockLocal.getPendingPosts());
        verifyNever(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
            ));
      });
    });

    group('error handling', () {
      test('marks as failed on send error and continues', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => [pendingPost1, pendingPost2]);
        // First post fails
        var callCount = 0;
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) throw Exception('Network error');
          return sentPost;
        });
        when(() => mockLocal.markAsFailed(any()))
            .thenAnswer((_) async {});
        when(() => mockLocal.markAsSent(any()))
            .thenAnswer((_) async {});

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockLocal.markAsFailed('pending_1')).called(1);
        verify(() => mockLocal.markAsSent('pending_2')).called(1);
      });
    });

    group('connectivity change', () {
      test('processes queue when network reconnects', () async {
        // Initial call — disconnected
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        // Now reconnect
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockLocal.getPendingPosts())
            .thenAnswer((_) async => []);

        connectivityController.add(true);

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockLocal.getPendingPosts()).called(1);
      });

      test('does not process when connectivity emits false', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();

        await Future.delayed(const Duration(milliseconds: 50));

        connectivityController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        // getPendingPosts is never called because we're always disconnected
        verifyNever(() => mockLocal.getPendingPosts());
      });
    });

    group('dispose', () {
      test('cancels connectivity subscription', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);

        service = SendQueueService(
          localDataSource: mockLocal,
          remoteDataSource: mockRemote,
          networkInfo: mockNetworkInfo,
        );
        service.start();
        service.dispose();

        // After dispose, connectivity changes should not trigger processing
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);

        connectivityController.add(true);
        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockLocal.getPendingPosts());
      });
    });
  });
}

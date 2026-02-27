import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/network_info.dart';
import '../datasources/local/post_local_datasource.dart';
import '../datasources/remote/post_remote_datasource.dart';

class SendQueueService {
  final PostLocalDataSource _localDataSource;
  final PostRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _connectivitySub;

  SendQueueService({
    required PostLocalDataSource localDataSource,
    required PostRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  void start() {
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((connected) {
      if (connected) {
        _processPendingPosts();
      }
    });
    // Also try immediately
    _processPendingPosts();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<void> _processPendingPosts() async {
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) return;

      final pendingPosts = await _localDataSource.getPendingPosts();
      for (final post in pendingPosts) {
        try {
          await _remoteDataSource.createPost(
            channelId: post.channelId,
            message: post.message,
            rootId: post.rootId.isNotEmpty ? post.rootId : null,
            fileIds: post.fileIds.isNotEmpty ? post.fileIds : null,
            priority: post.priority.isNotEmpty ? post.priority : null,
          );
          await _localDataSource.markAsSent(post.id);
        } catch (e) {
          debugPrint('SendQueue: Failed to send post ${post.id}: $e');
          await _localDataSource.markAsFailed(post.id);
        }
      }
    } catch (e) {
      debugPrint('SendQueue: Error processing pending posts: $e');
    }
  }
}

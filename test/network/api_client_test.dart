import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/config/app_config.dart';
import 'package:mgmess/core/network/api_client.dart';
import 'package:mgmess/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late ApiClient apiClient;
  late _DioAdapter dioAdapter;

  setUp(() {
    mockStorage = MockSecureStorage();
    AppConfig.serverUrlOverride = 'https://test.example.com';
    apiClient = ApiClient(secureStorage: mockStorage);

    // Replace the HTTP adapter with a mock adapter
    dioAdapter = _DioAdapter();
    apiClient.dio.httpClientAdapter = dioAdapter;
  });

  group('ApiClient', () {
    group('AuthInterceptor', () {
      test('adds Bearer token and CSRF header to requests', () async {
        when(() => mockStorage.getToken())
            .thenAnswer((_) async => 'test-token');
        when(() => mockStorage.getCsrfToken())
            .thenAnswer((_) async => 'csrf-token');

        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, {'ok': true}),
        );

        final response = await apiClient.dio.get('/test');

        expect(response.statusCode, 200);
        expect(
          response.requestOptions.headers['Authorization'],
          'Bearer test-token',
        );
        expect(
          response.requestOptions.headers['X-CSRF-Token'],
          'csrf-token',
        );
      });

      test('skips Authorization when no token', () async {
        when(() => mockStorage.getToken())
            .thenAnswer((_) async => null);
        when(() => mockStorage.getCsrfToken())
            .thenAnswer((_) async => null);

        dioAdapter.onGet(
          '/test',
          (server) => server.reply(200, {'ok': true}),
        );

        final response = await apiClient.dio.get('/test');

        expect(response.requestOptions.headers['Authorization'], isNull);
        expect(
            response.requestOptions.headers['X-CSRF-Token'], isNull);
      });

      test('clears storage on 401 response', () async {
        when(() => mockStorage.getToken())
            .thenAnswer((_) async => 'expired-token');
        when(() => mockStorage.getCsrfToken())
            .thenAnswer((_) async => 'csrf');
        when(() => mockStorage.clearAll())
            .thenAnswer((_) async {});

        dioAdapter.onGet(
          '/protected',
          (server) => server.reply(401, {'error': 'unauthorized'}),
        );

        try {
          await apiClient.dio.get('/protected');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 401);
        }

        verify(() => mockStorage.clearAll()).called(1);
      });

      test('does not clear storage on non-401 errors', () async {
        when(() => mockStorage.getToken())
            .thenAnswer((_) async => 'token');
        when(() => mockStorage.getCsrfToken())
            .thenAnswer((_) async => 'csrf');

        dioAdapter.onGet(
          '/bad',
          (server) => server.reply(403, {'error': 'forbidden'}),
        );

        try {
          await apiClient.dio.get('/bad');
          fail('Should have thrown');
        } on DioException catch (_) {}

        verifyNever(() => mockStorage.clearAll());
      });
    });

    group('configuration', () {
      test('uses correct base URL', () {
        expect(
          apiClient.dio.options.baseUrl,
          'https://test.example.com/api/v4',
        );
      });

      test('sets JSON content type', () {
        expect(
          apiClient.dio.options.headers['Content-Type'],
          'application/json',
        );
      });

      test('has configured timeouts', () {
        expect(
          apiClient.dio.options.connectTimeout,
          AppConfig.connectTimeout,
        );
        expect(
          apiClient.dio.options.receiveTimeout,
          AppConfig.receiveTimeout,
        );
      });
    });
  });
}

/// Minimal Dio mock adapter for testing interceptors.
class _DioAdapter implements HttpClientAdapter {
  final _handlers = <String, void Function(_MockServer)>{};

  void onGet(String path, void Function(_MockServer server) handler) {
    _handlers['GET:$path'] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method}:${options.path}';
    final handler = _handlers[key];

    if (handler == null) {
      throw DioException(
        requestOptions: options,
        message: 'No handler for $key',
      );
    }

    final server = _MockServer();
    handler(server);

    if (server._statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: server._statusCode,
          data: server._data,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return ResponseBody.fromString(
      jsonEncode(server._data),
      server._statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockServer {
  int _statusCode = 200;
  dynamic _data;

  void reply(int statusCode, dynamic data) {
    _statusCode = statusCode;
    _data = data;
  }
}

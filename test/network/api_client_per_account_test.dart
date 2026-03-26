import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/network/api_client.dart';
import 'package:mgmess/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
  });

  group('ApiClient with accountId', () {
    late ApiClient apiClient;
    late _DioAdapter dioAdapter;

    setUp(() {
      apiClient = ApiClient(
        secureStorage: mockStorage,
        baseUrl: 'https://custom.server.com/api/v4',
        accountId: 'acc123',
      );
      dioAdapter = _DioAdapter();
      apiClient.dio.httpClientAdapter = dioAdapter;
    });

    test('uses custom baseUrl', () {
      expect(
        apiClient.dio.options.baseUrl,
        'https://custom.server.com/api/v4',
      );
    });

    test('uses per-account token methods', () async {
      when(() => mockStorage.getTokenFor('acc123'))
          .thenAnswer((_) async => 'account-token');
      when(() => mockStorage.getCsrfFor('acc123'))
          .thenAnswer((_) async => 'account-csrf');

      dioAdapter.onGet(
        '/test',
        (server) => server.reply(200, {'ok': true}),
      );

      final response = await apiClient.dio.get('/test');

      expect(
        response.requestOptions.headers['Authorization'],
        'Bearer account-token',
      );
      expect(
        response.requestOptions.headers['X-CSRF-Token'],
        'account-csrf',
      );
    });

    test('clears per-account storage on 401', () async {
      when(() => mockStorage.getTokenFor('acc123'))
          .thenAnswer((_) async => 'expired');
      when(() => mockStorage.getCsrfFor('acc123'))
          .thenAnswer((_) async => 'csrf');
      when(() => mockStorage.clearFor('acc123'))
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

      verify(() => mockStorage.clearFor('acc123')).called(1);
    });

    test('stores accountId on instance', () {
      expect(apiClient.accountId, 'acc123');
    });
  });

  group('ApiClient without accountId (legacy)', () {
    late ApiClient apiClient;
    late _DioAdapter dioAdapter;

    setUp(() {
      apiClient = ApiClient(
        secureStorage: mockStorage,
        baseUrl: 'https://test.example.com/api/v4',
      );
      dioAdapter = _DioAdapter();
      apiClient.dio.httpClientAdapter = dioAdapter;
    });

    test('uses legacy token methods', () async {
      when(() => mockStorage.getTokenFor(null))
          .thenAnswer((_) async => 'legacy-token');
      when(() => mockStorage.getCsrfFor(null))
          .thenAnswer((_) async => 'legacy-csrf');

      dioAdapter.onGet(
        '/test',
        (server) => server.reply(200, {'ok': true}),
      );

      final response = await apiClient.dio.get('/test');

      expect(
        response.requestOptions.headers['Authorization'],
        'Bearer legacy-token',
      );
    });

    test('accountId is null', () {
      expect(apiClient.accountId, isNull);
    });
  });
}

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

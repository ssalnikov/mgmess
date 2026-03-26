import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../observability/crash_reporting.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorage _secureStorage;
  final String? accountId;
  final _logger = Logger(printer: SimplePrinter());

  ApiClient({
    required SecureStorage secureStorage,
    required String baseUrl,
    this.accountId,
  }) : _secureStorage = secureStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, accountId: accountId),
      _RetryInterceptor(dio),
      _LoggingInterceptor(_logger),
    ]);
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final String? _accountId;

  _AuthInterceptor(this._secureStorage, {String? accountId})
      : _accountId = accountId;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getTokenFor(_accountId);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final csrf = await _secureStorage.getCsrfFor(_accountId);
    if (csrf != null) {
      options.headers['X-CSRF-Token'] = csrf;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _secureStorage.clearFor(_accountId);
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio _dio;

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      final options = err.requestOptions;
      final retryCount = options.extra['retryCount'] ?? 0;
      if (retryCount < AppConfig.maxRetries) {
        options.extra['retryCount'] = retryCount + 1;
        await Future.delayed(
          AppConfig.retryDelay * (retryCount + 1),
        );
        try {
          final response = await _dio.fetch(options);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('→ ${options.method} ${options.path}');
    SentryHttpBreadcrumbInterceptor.onRequest(options.method, options.path);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    SentryHttpBreadcrumbInterceptor.onError(
      err.response?.statusCode,
      err.requestOptions.path,
      err.message,
    );
    handler.next(err);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';

class ServerUrlScreen extends StatefulWidget {
  final VoidCallback onServerConfigured;

  const ServerUrlScreen({super.key, required this.onServerConfigured});

  @override
  State<ServerUrlScreen> createState() => _ServerUrlScreenState();
}

class _ServerUrlScreenState extends State<ServerUrlScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> _connect() async {
    final url = _normalizeUrl(_urlController.text);
    if (url.isEmpty) {
      setState(() => _error = 'Enter server URL');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.get('$url/api/v4/system/ping');
      dio.close();

      if (response.statusCode == 200) {
        await AppConfig.setServerUrl(url);
        await initDependencies();
        await sl<NotificationService>().init();
        if (mounted) {
          widget.onServerConfigured();
        }
      } else {
        setState(() {
          _error = 'Server returned status ${response.statusCode}';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out. Check the URL and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Cannot connect to server. Check the URL.';
      } else if (e.response != null) {
        message = 'Server error: ${e.response?.statusCode}';
      } else {
        message = 'Connection failed: ${e.message}';
      }
      setState(() {
        _error = message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.chat,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MGMess',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.mattermostClient,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: context.l10n.serverUrl,
                    hintText: context.l10n.serverUrlHint,
                    prefixIcon: const Icon(Icons.dns),
                    border: const OutlineInputBorder(),
                    errorText: _error,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _connect(),
                  enabled: !_loading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.l10n.connect,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

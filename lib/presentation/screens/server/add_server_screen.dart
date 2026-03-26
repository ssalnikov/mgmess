import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/server_account.dart';
import '../../blocs/server/server_list_cubit.dart';

/// Screen for adding a new Mattermost server.
///
/// Validates the URL by pinging `/api/v4/system/ping`, then creates a
/// [ServerAccount] and switches to it. The OAuth / login flow will start
/// automatically because the new session has no token.
class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
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
      setState(() => _error = context.l10n.enterServerUrl);
      return;
    }

    // Check for duplicates
    final cubit = sl<ServerListCubit>();
    final existing = cubit.state.accounts
        .where((a) => a.serverUrl.toLowerCase() == url.toLowerCase());
    if (existing.isNotEmpty) {
      // Already exists — just switch to it
      await cubit.switchServer(existing.first.id);
      if (mounted) Navigator.of(context).pop();
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
        final now = DateTime.now();
        final account = ServerAccount(
          id: now.millisecondsSinceEpoch.toString(),
          serverUrl: url,
          displayName: Uri.parse(url).host,
          addedAt: now,
          lastActiveAt: now,
        );
        await cubit.addServer(account);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _error = context.l10n.serverReturnedStatus(response.statusCode ?? 0);
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = context.l10n.connectionTimedOut;
      } else if (e.type == DioExceptionType.connectionError) {
        message = context.l10n.cannotConnectToServer;
      } else if (e.response != null) {
        message = context.l10n.serverError('${e.response?.statusCode}');
      } else {
        message = 'Connection failed: ${e.message}';
      }
      setState(() {
        _error = message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.addServer),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.dns, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
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

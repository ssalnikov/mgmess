import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight analytics service for tracking usage events.
///
/// Events are accumulated locally in SharedPreferences and can be
/// exported / sent to a backend. In debug mode events are also logged.
class AnalyticsService {
  static const String _prefsKeyEvents = 'analytics_events';
  static const String _prefsKeyEnabled = 'analytics_enabled';
  static const int _maxStoredEvents = 500;

  final _logger = Logger(printer: SimplePrinter());
  bool _enabled = true;

  /// Load persisted opt-in/out preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKeyEnabled) ?? true;
  }

  /// Whether analytics collection is enabled.
  bool get isEnabled => _enabled;

  /// Opt in or out of analytics collection.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEnabled, value);
  }

  // ── Predefined events ────────────────────────────────────────────

  void trackLogin({required String method}) =>
      _track('login', {'method': method});

  void trackLogout() => _track('logout');

  void trackChannelOpened({required String channelId, required String type}) =>
      _track('channel_opened', {'channel_id': channelId, 'type': type});

  void trackMessageSent({required String channelId, bool hasFiles = false}) =>
      _track('message_sent', {
        'channel_id': channelId,
        'has_files': hasFiles,
      });

  void trackSearch({required String query, int resultCount = 0}) =>
      _track('search', {
        'query_length': query.length,
        'result_count': resultCount,
      });

  void trackFileUploaded({required String mimeType}) =>
      _track('file_uploaded', {'mime_type': mimeType});

  void trackReactionAdded({required String emoji}) =>
      _track('reaction_added', {'emoji': emoji});

  void trackThreadOpened({required String postId}) =>
      _track('thread_opened', {'post_id': postId});

  void trackPushReceived() => _track('push_received');

  void trackScreenView({required String screenName}) =>
      _track('screen_view', {'screen': screenName});

  void trackError({required String source, required String message}) =>
      _track('error', {'source': source, 'message': message});

  void trackChannelCreated({required String type}) =>
      _track('channel_created', {'type': type});

  void trackFeatureFlagEvaluated({
    required String flag,
    required bool value,
  }) =>
      _track('feature_flag_evaluated', {'flag': flag, 'value': value});

  // ── Core ─────────────────────────────────────────────────────────

  void _track(String event, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;

    final Map<String, dynamic> entry = {
      'event': event,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      if (properties != null) 'properties': properties,
    };

    if (kDebugMode) {
      _logger.d('[Analytics] $event ${properties ?? ''}');
    }

    _persist(entry);
  }

  Future<void> _persist(Map<String, dynamic> entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKeyEvents) ?? [];

      raw.add(jsonEncode(entry));

      // Keep only the most recent events to avoid unbounded growth
      if (raw.length > _maxStoredEvents) {
        raw.removeRange(0, raw.length - _maxStoredEvents);
      }

      await prefs.setStringList(_prefsKeyEvents, raw);
    } catch (_) {
      // Analytics storage should never crash the app
    }
  }

  /// Return all stored events (for export / debugging).
  Future<List<Map<String, dynamic>>> getStoredEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKeyEvents) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  /// Clear stored events (e.g. after successful upload).
  Future<void> clearStoredEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyEvents);
  }

  /// Number of stored events.
  Future<int> get storedEventCount async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefsKeyEvents) ?? []).length;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag definitions.
///
/// Each flag has a default value that ships with the binary.
/// Flags can be overridden locally via [FeatureFlagService.setOverride]
/// or remotely by calling [FeatureFlagService.applyRemoteConfig].
enum FeatureFlag {
  /// Show link preview (OpenGraph) cards in chat.
  linkPreview(defaultValue: true),

  /// Enable voice message recording.
  voiceMessages(defaultValue: false),

  /// Enable AI summarization of unread messages.
  aiSummarization(defaultValue: false),

  /// Enable Sentry crash reporting.
  crashReporting(defaultValue: true),

  /// Enable analytics event collection.
  analytics(defaultValue: true),

  /// Show onboarding flow for new users.
  onboarding(defaultValue: true),

  /// Enable biometric lock feature.
  biometricLock(defaultValue: true),

  /// Enable Jitsi video calls button.
  videoCalls(defaultValue: false);

  final bool defaultValue;

  const FeatureFlag({required this.defaultValue});
}

/// Service for evaluating feature flags.
///
/// Resolution order:
/// 1. Local override (set via [setOverride])
/// 2. Remote config (set via [applyRemoteConfig])
/// 3. Compiled default value ([FeatureFlag.defaultValue])
class FeatureFlagService {
  static const String _remotePrefix = 'ff_remote_';
  static const String _localPrefix = 'ff_local_';

  final Map<String, bool> _cache = {};
  bool _loaded = false;

  /// Load persisted flags from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    for (final flag in FeatureFlag.values) {
      // Local override takes priority
      final localKey = '$_localPrefix${flag.name}';
      final remoteKey = '$_remotePrefix${flag.name}';

      if (prefs.containsKey(localKey)) {
        _cache[flag.name] = prefs.getBool(localKey)!;
      } else if (prefs.containsKey(remoteKey)) {
        _cache[flag.name] = prefs.getBool(remoteKey)!;
      }
    }
    _loaded = true;
  }

  /// Evaluate a feature flag.
  bool isEnabled(FeatureFlag flag) {
    assert(_loaded, 'FeatureFlagService.init() must be called before use');
    return _cache[flag.name] ?? flag.defaultValue;
  }

  /// Convenience operator: `featureFlags[FeatureFlag.linkPreview]`
  bool operator [](FeatureFlag flag) => isEnabled(flag);

  /// Set a local override for a flag (survives app restarts).
  Future<void> setOverride(FeatureFlag flag, bool value) async {
    _cache[flag.name] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_localPrefix${flag.name}', value);
  }

  /// Remove local override, falling back to remote or default.
  Future<void> clearOverride(FeatureFlag flag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_localPrefix${flag.name}');

    // Recalculate from remote or default
    final remoteKey = '$_remotePrefix${flag.name}';
    if (prefs.containsKey(remoteKey)) {
      _cache[flag.name] = prefs.getBool(remoteKey)!;
    } else {
      _cache.remove(flag.name);
    }
  }

  /// Apply remote config (e.g. from server response).
  /// Remote values are overridden by any local overrides.
  Future<void> applyRemoteConfig(Map<String, bool> config) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in config.entries) {
      final remoteKey = '$_remotePrefix${entry.key}';
      await prefs.setBool(remoteKey, entry.value);

      // Only update cache if there's no local override
      final localKey = '$_localPrefix${entry.key}';
      if (!prefs.containsKey(localKey)) {
        _cache[entry.key] = entry.value;
      }
    }
  }

  /// Get all current flag values (for debugging / display).
  Map<String, bool> getAllFlags() {
    return {
      for (final flag in FeatureFlag.values) flag.name: isEnabled(flag),
    };
  }

  /// Check if a flag has a local override.
  Future<bool> hasOverride(FeatureFlag flag) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_localPrefix${flag.name}');
  }

  /// Reset all overrides and remote config.
  Future<void> resetAll() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final flag in FeatureFlag.values) {
      await prefs.remove('$_localPrefix${flag.name}');
      await prefs.remove('$_remotePrefix${flag.name}');
    }
  }
}

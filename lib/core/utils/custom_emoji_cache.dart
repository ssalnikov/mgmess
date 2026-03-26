import '../di/injection.dart';
import '../network/api_endpoints.dart';

/// Shared cache for custom (server) emoji shortcode -> image URL mapping.
class CustomEmojiCache {
  static Map<String, String>? _urls;
  static bool _loading = false;

  /// Returns cached custom emoji URLs (shortcode -> image URL).
  /// Returns empty map if not yet loaded.
  static Map<String, String> get urls => _urls ?? const {};

  /// Triggers loading if not already loaded. Safe to call multiple times.
  static Future<void> ensureLoaded() async {
    if (_urls != null || _loading) return;
    _loading = true;
    try {
      final session = currentSession;
      final emojis = await session.emojiRemoteDataSource.getCustomEmojis();
      _urls = {
        for (final e in emojis)
          e.name:
              '${session.baseUrl}${ApiEndpoints.customEmojiImage(e.id)}',
      };
    } catch (_) {
      _urls = {};
    } finally {
      _loading = false;
    }
  }

  /// Returns the image URL for a custom emoji shortcode, or null.
  static String? getUrl(String shortcode) => _urls?[shortcode];
}

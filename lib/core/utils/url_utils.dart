/// Shared URL helpers used across the app.
class UrlUtils {
  UrlUtils._();

  /// Extract the host from a URL, returning the original string on failure.
  static String extractHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }
}

/// Application-wide constants
class AppConstants {
  static const String appName = 'InstaGrab';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  // Regex patterns for parsing og:meta tags
  static const String ogVideoPattern =
      r'property="og:video"\s+content="([^"]+)"';
  static const String ogImagePattern =
      r'property="og:image"\s+content="([^"]+)"';
  static const String ogTitlePattern =
      r'property="og:title"\s+content="([^"]+)"';
  static const String altOgVideoPattern =
      r'content="([^"]+)"\s+property="og:video"';
  static const String altOgImagePattern =
      r'content="([^"]+)"\s+property="og:image"';

  // URL validation
  static const String instagramUrlPattern =
      r'https?://(www\.)?instagram\.com/(p|reel|reels|tv)/[A-Za-z0-9_-]+/?';

  // Storage keys
  static const String historyKey = 'download_history';

  // Timeouts (seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 60;
}

/// Media type enum
enum MediaType { video, image, carousel, unknown }

extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.video:
        return 'Video';
      case MediaType.image:
        return 'Image';
      case MediaType.carousel:
        return 'Carousel';
      case MediaType.unknown:
        return 'Unknown';
    }
  }
}

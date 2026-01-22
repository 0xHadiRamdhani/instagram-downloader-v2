import 'package:dio/dio.dart';
import 'package:instagram_downloader/core/constants.dart';
import 'package:instagram_downloader/features/instagrab/data/models/instagram_media.dart';

/// Parser for extracting media URLs from Instagram public pages
class InstagramParser {
  final Dio _dio;

  InstagramParser({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: Duration(seconds: AppConstants.connectionTimeout),
              receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
              headers: {
                'User-Agent': AppConstants.userAgent,
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-US,en;q=0.5',
              },
            ),
          );

  bool isValidInstagramUrl(String url) {
    final pattern = RegExp(
      AppConstants.instagramUrlPattern,
      caseSensitive: false,
    );
    return pattern.hasMatch(url.trim());
  }

  String normalizeUrl(String url) {
    String normalized = url.trim();
    if (!normalized.startsWith('http')) normalized = 'https://$normalized';
    if (!normalized.endsWith('/')) normalized = '$normalized/';
    return normalized;
  }

  Future<InstagramMedia> fetchMedia(String url) async {
    if (!isValidInstagramUrl(url)) {
      throw InstagramParserException(
        'Invalid Instagram URL. Please use a post or reel link.',
      );
    }

    final normalizedUrl = normalizeUrl(url);

    try {
      final response = await _dio.get(
        normalizedUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw InstagramParserException(
          'Failed to fetch page. Content might be private.',
        );
      }

      return _parseHtmlContent(response.data.toString(), normalizedUrl);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw InstagramParserException(
          'Connection timeout. Check your internet.',
        );
      }
      throw InstagramParserException('Network error: ${e.message}');
    } catch (e) {
      if (e is InstagramParserException) rethrow;
      throw InstagramParserException('Failed to parse: $e');
    }
  }

  InstagramMedia _parseHtmlContent(String html, String originalUrl) {
    String? videoUrl =
        _extractMeta(html, AppConstants.ogVideoPattern) ??
        _extractMeta(html, AppConstants.altOgVideoPattern);
    String? imageUrl =
        _extractMeta(html, AppConstants.ogImagePattern) ??
        _extractMeta(html, AppConstants.altOgImagePattern);
    String? title = _extractMeta(html, AppConstants.ogTitlePattern);

    // Fallback patterns for video
    if (videoUrl == null) {
      for (final pattern in [
        RegExp(r'"video_url"\s*:\s*"([^"]+)"'),
        RegExp(r'"contentUrl"\s*:\s*"([^"]+\.mp4[^"]*)"'),
      ]) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          videoUrl = _unescapeUrl(match.group(1));
          break;
        }
      }
    }

    videoUrl = videoUrl != null ? _unescapeUrl(videoUrl) : null;
    imageUrl = imageUrl != null ? _unescapeUrl(imageUrl) : null;

    MediaType type;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      type = MediaType.video;
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      type = MediaType.image;
    } else {
      throw InstagramParserException(
        'No media found. Content might be private or carousel.',
      );
    }

    return InstagramMedia(
      originalUrl: originalUrl,
      videoUrl: videoUrl,
      imageUrl: imageUrl,
      title: _cleanText(title),
      type: type,
    );
  }

  String? _extractMeta(String html, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
    return match?.group(1);
  }

  String? _unescapeUrl(String? url) {
    if (url == null) return null;
    return url
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\\u0026', '&')
        .replaceAll(r'\/', '/')
        .replaceAll('&amp;', '&');
  }

  String? _cleanText(String? text) {
    if (text == null) return null;
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}

class InstagramParserException implements Exception {
  final String message;
  InstagramParserException(this.message);
  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UrlMetadata {
  final String url;
  final String title;
  final String description;
  final String? imageUrl;
  final String? siteName;
  final String? faviconUrl;
  final String? articleBody;
  final int readingTimeMinutes;

  const UrlMetadata({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
    this.siteName,
    this.faviconUrl,
    this.articleBody,
    this.readingTimeMinutes = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'siteName': siteName,
      'faviconUrl': faviconUrl,
      'articleBody': articleBody,
      'readingTimeMinutes': readingTimeMinutes,
    };
  }

  factory UrlMetadata.fromMap(Map<String, dynamic> map) {
    return UrlMetadata(
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      siteName: map['siteName'],
      faviconUrl: map['faviconUrl'],
      articleBody: map['articleBody'],
      readingTimeMinutes: map['readingTimeMinutes'] ?? 2,
    );
  }
}

/// OpenGraph & Rich Web Metadata Scraper & Reader Mode Content Extractor.
/// Zero external runtime dependencies; uses Dart's native HttpClient.
class UrlMetadataService {
  static final UrlMetadataService instance = UrlMetadataService._internal();
  UrlMetadataService._internal();

  final Map<String, UrlMetadata> _cache = {};

  /// Scrapes OpenGraph tags, article text, and favicon for a given URL.
  Future<UrlMetadata> fetchMetadata(String rawUrl) async {
    String cleanUrl = rawUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    if (_cache.containsKey(cleanUrl)) {
      return _cache[cleanUrl]!;
    }

    try {
      final uri = Uri.parse(cleanUrl);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..userAgent =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 400) {
        final html = await response.transform(utf8.decoder).join();
        final metadata = _parseHtmlMetadata(cleanUrl, uri, html);
        _cache[cleanUrl] = metadata;
        return metadata;
      }
    } catch (e) {
      debugPrint('UrlMetadataService: Failed to fetch live metadata for $cleanUrl: $e');
    }

    // Fallback heuristic metadata if offline or request fails
    final fallback = _generateFallbackMetadata(cleanUrl);
    _cache[cleanUrl] = fallback;
    return fallback;
  }

  UrlMetadata _parseHtmlMetadata(String originalUrl, Uri uri, String html) {
    String? ogTitle = _extractMeta(html, 'property', 'og:title') ??
        _extractMeta(html, 'name', 'twitter:title') ??
        _extractTag(html, 'title');

    String? ogDescription = _extractMeta(html, 'property', 'og:description') ??
        _extractMeta(html, 'name', 'description') ??
        _extractMeta(html, 'name', 'twitter:description');

    String? ogImage = _extractMeta(html, 'property', 'og:image') ??
        _extractMeta(html, 'name', 'twitter:image');

    String? siteName = _extractMeta(html, 'property', 'og:site_name') ??
        uri.host.replaceAll('www.', '');

    String? favicon = _extractFavicon(html, uri);

    // Resolve relative image URLs
    if (ogImage != null && !ogImage.startsWith('http')) {
      ogImage = uri.resolve(ogImage).toString();
    }

    // Extract Clean Article Content for Reader Mode
    final articleText = _extractArticleBody(html);
    final wordCount = articleText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final readingTime = (wordCount / 200).ceil().clamp(1, 45);

    return UrlMetadata(
      url: originalUrl,
      title: _decodeHtmlEntities(ogTitle?.trim() ?? uri.host),
      description: _decodeHtmlEntities(ogDescription?.trim() ?? ''),
      imageUrl: ogImage,
      siteName: siteName,
      faviconUrl: favicon,
      articleBody: articleText.isNotEmpty ? articleText : null,
      readingTimeMinutes: readingTime,
    );
  }

  String? _extractMeta(String html, String attrName, String attrValue) {
    final pattern = RegExp(
      '<meta\\s+[^>]*$attrName=["\']$attrValue["\'][^>]*content=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    // Reverse attribute order: content first, then property/name
    final altPattern = RegExp(
      '<meta\\s+[^>]*content=["\']([^"\']*)["\'][^>]*$attrName=["\']$attrValue["\']',
      caseSensitive: false,
    );
    final altMatch = altPattern.firstMatch(html);
    if (altMatch != null && altMatch.groupCount >= 1) {
      return altMatch.group(1);
    }

    return null;
  }

  String? _extractTag(String html, String tagName) {
    final pattern = RegExp(
      '<$tagName[^>]*>(.*?)</$tagName>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = pattern.firstMatch(html);
    return match?.group(1);
  }

  String? _extractFavicon(String html, Uri uri) {
    final pattern = RegExp(
      '<link\\s+[^>]*rel=["\'](?:shortcut icon|icon)["\'][^>]*href=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      final href = match.group(1)!;
      return href.startsWith('http') ? href : uri.resolve(href).toString();
    }
    return '${uri.scheme}://${uri.host}/favicon.ico';
  }

  String _extractArticleBody(String html) {
    // 1. Remove script, style, header, nav, footer, iframe, svg, comments
    var text = html.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // 2. Extract paragraphs and headings
    final paragraphPattern = RegExp(r'<(?:p|h1|h2|h3|h4|li|blockquote)[^>]*>(.*?)</(?:p|h1|h2|h3|h4|li|blockquote)>', caseSensitive: false, dotAll: true);
    final matches = paragraphPattern.allMatches(text);

    final List<String> cleanBlocks = [];
    for (final match in matches) {
      final inner = match.group(1) ?? '';
      final stripped = inner.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
      final decoded = _decodeHtmlEntities(stripped);
      if (decoded.length > 25 && !decoded.toLowerCase().contains('cookie') && !decoded.toLowerCase().contains('privacy policy')) {
        cleanBlocks.add(decoded);
      }
    }

    if (cleanBlocks.isEmpty) {
      // Fallback: strip all HTML tags
      final allStripped = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
      final words = allStripped.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(300).join(' ');
      return _decodeHtmlEntities(words);
    }

    return cleanBlocks.join('\n\n');
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8212;', '—')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  UrlMetadata _generateFallbackMetadata(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.replaceAll('www.', '');
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      String cleanTitle = domain;

      if (pathSegments.isNotEmpty) {
        final lastSeg = pathSegments.last.replaceAll(RegExp(r'[-_]'), ' ');
        cleanTitle = '${lastSeg[0].toUpperCase()}${lastSeg.substring(1)} — $domain';
      }

      return UrlMetadata(
        url: url,
        title: cleanTitle,
        description: 'Web article and resource saved from $domain into ATLAS Personal Memory OS.',
        siteName: domain,
        faviconUrl: '${uri.scheme}://${uri.host}/favicon.ico',
        readingTimeMinutes: 3,
      );
    } catch (_) {
      return UrlMetadata(
        url: url,
        title: 'Saved Web Resource',
        description: 'Web link indexed in ATLAS Memory OS.',
        readingTimeMinutes: 2,
      );
    }
  }
}

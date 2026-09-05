import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  UrlService._();

  /// Opens [rawUrl] in the default browser / app handler.
  /// Supports http, https, mailto, tel schemes.
  /// Shows a SnackBar via [context] only if the URL cannot be launched.
  static Future<void> launch(String rawUrl, {BuildContext? context}) async {
    final cleaned = rawUrl.trim();
    if (cleaned.isEmpty) return;

    // Auto-prepend https:// if no scheme
    final urlString =
        cleaned.startsWith('http://') ||
            cleaned.startsWith('https://') ||
            cleaned.startsWith('mailto:') ||
            cleaned.startsWith('tel:')
        ? cleaned
        : 'https://$cleaned';

    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      _showError(context, 'Invalid URL: $rawUrl');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context != null && context.mounted) {
        _showError(context, 'Could not open: $rawUrl');
      }
    }
  }

  static void _showError(BuildContext? context, String message) {
    if (context == null) {
      debugPrint('[UrlService] $message');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// E-poçta programmasyny (Gmail we ş.m.) açmak üçin kömekçi.
class EmailLauncher {
  static const String supportEmail = 'gazojaknamazwagty@gmail.com';

  static Future<bool> open({
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeQuery({'subject': subject, 'body': body}),
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('EmailLauncher error: $e');
      return false;
    }
  }

  static String? _encodeQuery(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

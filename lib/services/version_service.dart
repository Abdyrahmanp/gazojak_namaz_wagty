import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/site_config.dart';

class AppVersionInfo {
  final String versionName;
  final int versionCode;
  final String releaseDate;
  final String apkUrl;
  final String whatsNew;

  AppVersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.releaseDate,
    required this.apkUrl,
    required this.whatsNew,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      versionName: json['versionName'] ?? json['version'] ?? '1.0.0',
      versionCode: json['versionCode'] ?? json['buildNumber'] ?? 1,
      releaseDate: json['releaseDate'] ?? '',
      apkUrl: json['apkUrl'] ?? '',
      whatsNew: json['whatsNew'] ?? '',
    );
  }
}

class VersionService {
  static const String _versionUrlKey = 'version_check_url';
  static const String _dismissedVersionKey = 'dismissed_version_code';
  
  static const String defaultVersionUrl = SiteConfig.versionJsonUrl;

  // Current app hardcoded version
  static const String currentVersionName = '1.0.0';
  static const int currentVersionCode = 1;
  static const String currentReleaseDate = '24.06.2026';

  /// Fetches version info from the remote JSON file
  Future<AppVersionInfo?> fetchRemoteVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urlString = await _resolveVersionUrl(prefs);
      final url = Uri.parse(urlString);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final decoded = json.decode(jsonString);
        return AppVersionInfo.fromJson(decoded);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to check version: $e');
    }
    return null;
  }

  /// Checks if a new update is available (remote versionCode > currentVersionCode)
  Future<bool> isUpdateAvailable(AppVersionInfo remoteInfo) async {
    return remoteInfo.versionCode > currentVersionCode;
  }

  /// Checks if the user has already dismissed this specific remote update version code
  Future<bool> isUpdateDismissed(int remoteVersionCode) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getInt(_dismissedVersionKey) ?? 0;
    return dismissed == remoteVersionCode;
  }

  /// Saves the remote version code to SharedPreferences so the user isn't prompted again on startup
  Future<void> dismissUpdate(int remoteVersionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedVersionKey, remoteVersionCode);
  }

  Future<void> setVersionUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionUrlKey, url);
  }

  Future<String> getVersionUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return _resolveVersionUrl(prefs);
  }

  /// Köne GitHub URL-sinden täze web sahypasyna geçirmek.
  Future<String> _resolveVersionUrl(SharedPreferences prefs) async {
    final stored = prefs.getString(_versionUrlKey);
    if (stored == null) return defaultVersionUrl;
    if (stored.contains('githubusercontent.com') ||
        stored.contains('github.com') ||
        stored.contains('gazojak_namaz_wagty.byethost')) {
      await prefs.setString(_versionUrlKey, defaultVersionUrl);
      return defaultVersionUrl;
    }
    return stored;
  }
}

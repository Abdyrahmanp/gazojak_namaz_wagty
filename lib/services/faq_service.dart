import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/site_config.dart';
import '../models/faq_item.dart';

class FaqService {
  static const String _cacheKey = 'cached_faq_data';
  static const String _remoteUrlKey = 'faq_remote_url';
  
  static const String defaultRemoteUrl = SiteConfig.faqJsonUrl;

  /// Loads FAQ data instantly. First checks the local cached data in SharedPreferences.
  /// If none exists, loads from the local assets/data/faq.json asset.
  Future<List<FaqCategory>> loadFaqData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        return _parseJson(cachedJson);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error reading FAQ cache: $e');
    }
    
    return _loadFromAsset();
  }

  Future<List<FaqCategory>> _loadFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/faq.json');
      return _parseJson(jsonString);
    } catch (e) {
      // ignore: avoid_print
      print('Error loading FAQ asset: $e');
      return [];
    }
  }

  List<FaqCategory> _parseJson(String jsonString) {
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((item) => FaqCategory.fromJson(item)).toList();
  }

  /// Fetches the latest FAQ JSON from the remote server/GitHub in the background.
  /// If successful, saves to cache and returns true. Does not block the main execution.
  Future<bool> updateFaqDataFromServer({String? customUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urlString =
          customUrl ?? await _resolveRemoteUrl(prefs);
      final url = Uri.parse(urlString);
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(url);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        
        // Validate JSON structure by testing parsing
        final parsed = _parseJson(jsonString);
        if (parsed.isNotEmpty) {
          await prefs.setString(_cacheKey, jsonString);
          return true;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to update FAQ from server: $e');
    }
    return false;
  }

  Future<void> setRemoteUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remoteUrlKey, url);
  }

  Future<String> getRemoteUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return _resolveRemoteUrl(prefs);
  }

  Future<String> _resolveRemoteUrl(SharedPreferences prefs) async {
    final stored = prefs.getString(_remoteUrlKey);
    if (stored == null) return defaultRemoteUrl;
    if (stored.contains('githubusercontent.com') ||
        stored.contains('github.com') ||
        stored.contains('gazojaknamazwagt.byethost3.com')) {
      await prefs.setString(_remoteUrlKey, defaultRemoteUrl);
      return defaultRemoteUrl;
    }
    return stored;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_time_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final PrayerTimeService prayerService = PrayerTimeService();

  bool _isDarkMode = true;
  DateTime _selectedDate = DateTime.now();
  bool _persistentNotificationEnabled = true;
  bool _notificationSoundEnabled = true;

  // 6 prayer times including gun (sunrise)
  final Map<String, int> _offsets = {
    'bamdat': 0,
    'gun': 0,
    'oyle': 0,
    'ikindi': 0,
    'agsam': 0,
    'yasy': 0,
  };

  int _zikirCount = 0;
  int _selectedZikirIndex = 0;
  int _zikirTarget = 33;

  bool get isDarkMode => _isDarkMode;
  DateTime get selectedDate => _selectedDate;
  bool get persistentNotificationEnabled => _persistentNotificationEnabled;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  Map<String, int> get offsets => _offsets;
  int get zikirCount => _zikirCount;
  int get selectedZikirIndex => _selectedZikirIndex;
  int get zikirTarget => _zikirTarget;

  Future<void> initialize() async {
    await prayerService.loadDatabase();
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _persistentNotificationEnabled =
          prefs.getBool('persistent_notification_enabled') ?? true;
      _notificationSoundEnabled =
          prefs.getBool('notification_sound_enabled') ?? true;
      _zikirCount = prefs.getInt('zikir_count') ?? 0;
      _selectedZikirIndex = prefs.getInt('selected_zikir_index') ?? 0;
      _zikirTarget = prefs.getInt('zikir_target') ?? 33;
      for (final key in _offsets.keys) {
        _offsets[key] = prefs.getInt('offset_$key') ?? 0;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading settings: $e');
    }

    try {
      await NotificationService().initialize();
      await NotificationService().schedulePrayerNotifications(
        prayerService: prayerService,
        offsets: _offsets,
        soundEnabled: _notificationSoundEnabled,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Notification setup error: $e');
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  Future<void> togglePersistentNotification(bool val) async {
    _persistentNotificationEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persistent_notification_enabled', val);
    if (!val) {
      await NotificationService().cancelPersistentNotification();
    }
  }

  Future<void> toggleNotificationSound(bool val) async {
    _notificationSoundEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound_enabled', val);
    await NotificationService().schedulePrayerNotifications(
      prayerService: prayerService,
      offsets: _offsets,
      soundEnabled: val,
    );
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  Future<void> setOffset(String key, int val) async {
    if (_offsets.containsKey(key)) {
      _offsets[key] = val;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('offset_$key', val);
      await NotificationService().schedulePrayerNotifications(
        prayerService: prayerService,
        offsets: _offsets,
        soundEnabled: _notificationSoundEnabled,
      );
    }
  }

  Future<void> resetOffsets() async {
    for (final key in _offsets.keys) {
      _offsets[key] = 0;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    for (final key in _offsets.keys) {
      await prefs.setInt('offset_$key', 0);
    }
    await NotificationService().schedulePrayerNotifications(
      prayerService: prayerService,
      offsets: _offsets,
      soundEnabled: _notificationSoundEnabled,
    );
  }

  Future<void> incrementZikir() async {
    _zikirCount++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_count', _zikirCount);
  }

  Future<void> setZikirCount(int val) async {
    _zikirCount = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_count', val);
  }

  Future<void> resetZikir() async {
    _zikirCount = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_count', 0);
  }

  Future<void> setSelectedZikirIndex(int index) async {
    _selectedZikirIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_zikir_index', index);
  }

  Future<void> setZikirTarget(int target) async {
    _zikirTarget = target;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('zikir_target', target);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_time_service.dart';
import '../services/notification_service.dart';
import '../config/notification_sounds.dart';

class AppState extends ChangeNotifier {
  final PrayerTimeService prayerService = PrayerTimeService();

  bool _isDarkMode = true;
  DateTime _selectedDate = DateTime.now();
  bool _persistentNotificationEnabled = true;
  bool _notificationSoundEnabled = true;
  String _notificationSoundId = NotificationSounds.defaultSoundId;

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

  Timer? _prayerTimer;
  String _countdownStr = '00:00:00';
  String _nextPrayerKey = 'bamdat';
  String _activePrayerKey = 'bamdat';
  bool _isMekruh = false;
  int _mekruhMinutesLeft = 0;

  bool get isDarkMode => _isDarkMode;
  DateTime get selectedDate => _selectedDate;
  bool get persistentNotificationEnabled => _persistentNotificationEnabled;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  String get notificationSoundId => _notificationSoundId;
  Map<String, int> get offsets => _offsets;
  int get zikirCount => _zikirCount;
  int get selectedZikirIndex => _selectedZikirIndex;
  int get zikirTarget => _zikirTarget;

  String get countdownStr => _countdownStr;
  String get nextPrayerKey => _nextPrayerKey;
  String get activePrayerKey => _activePrayerKey;
  bool get isMekruh => _isMekruh;
  int get mekruhMinutesLeft => _mekruhMinutesLeft;

  Future<void> initialize() async {
    await prayerService.loadDatabase();
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _persistentNotificationEnabled =
          prefs.getBool('persistent_notification_enabled') ?? true;
      _notificationSoundEnabled =
          prefs.getBool('notification_sound_enabled') ?? true;
      _notificationSoundId =
          prefs.getString('notification_sound_id') ?? NotificationSounds.defaultSoundId;
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
        soundId: _notificationSoundId,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Notification setup error: $e');
    }

    _startPrayerTimer();
    notifyListeners();
  }

  void _startPrayerTimer() {
    _prayerTimer?.cancel();
    _tickPrayerTimer();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickPrayerTimer();
    });
  }

  void tickPrayerTimer() => _tickPrayerTimer();

  void _tickPrayerTimer() {
    if (!prayerService.isLoaded) return;

    final now = DateTime.now();
    final selectedDate = _selectedDate;
    final service = prayerService;

    final targetDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final activeKey = service.getActivePrayerKey(targetDateTime, _offsets);
    final nextInfo = service.getNextPrayerInfo(targetDateTime, _offsets);
    final nextKey = nextInfo['key'] as String;
    final nextDateTime = nextInfo['dateTime'] as DateTime;
    final difference = nextDateTime.difference(targetDateTime);

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    final countdownStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final selectedTimes = service.getAdjustedDateTimes(targetDateTime, _offsets);
    final agsamDt = selectedTimes['agsam']!;
    final diffToAgsam = agsamDt.difference(targetDateTime);

    bool isMekruh = false;
    int mekruhMinutesLeft = 0;
    if (targetDateTime.isBefore(agsamDt) &&
        diffToAgsam.inMinutes <= 20 &&
        diffToAgsam.inMinutes >= 0) {
      isMekruh = true;
      mekruhMinutesLeft = diffToAgsam.inMinutes + 1;
    }

    final isShowingToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    _countdownStr = countdownStr;
    _nextPrayerKey = nextKey;
    _activePrayerKey = activeKey;
    _isMekruh = isMekruh;
    _mekruhMinutesLeft = mekruhMinutesLeft;
    notifyListeners();

    if (_persistentNotificationEnabled && isShowingToday) {
      final dailyTimes = service.getTimesForDate(selectedDate);
      NotificationService().showPersistentNotification(
        nextPrayerKey: nextKey,
        remainingTime: countdownStr,
        dailyTimes: dailyTimes,
        offsets: _offsets,
        activePrayerKey: activeKey,
      );
    }
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
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
    } else {
      _tickPrayerTimer();
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
      soundId: _notificationSoundId,
    );
  }

  Future<void> setNotificationSoundId(String soundId) async {
    if (_notificationSoundId == soundId) return;
    _notificationSoundId = soundId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound_id', soundId);
    await NotificationService().schedulePrayerNotifications(
      prayerService: prayerService,
      offsets: _offsets,
      soundEnabled: _notificationSoundEnabled,
      soundId: soundId,
    );
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    _tickPrayerTimer();
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
    _tickPrayerTimer();
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
        soundId: _notificationSoundId,
      );
      _tickPrayerTimer();
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
      soundId: _notificationSoundId,
    );
    _tickPrayerTimer();
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

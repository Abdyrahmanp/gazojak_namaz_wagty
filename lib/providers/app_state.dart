import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_time_service.dart';
import '../services/notification_service.dart';
import '../utils/agent_debug_log.dart';

class AppState extends ChangeNotifier {
  final PrayerTimeService prayerService = PrayerTimeService();

  bool _isDarkMode = true;
  DateTime _selectedDate = DateTime.now();
  bool _persistentNotificationEnabled = true;
  bool _notificationSoundEnabled = true;
  bool _isReady = false;

  final Map<String, int> _offsets = {
    'bamdat': 0,
    'gun': 0,
    'oyle': 0,
    'ikindi': 0,
    'agsam': 0,
    'yasy': 0,
  };

  // Per-prayer sound toggles (true = sound enabled for that prayer)
  final Map<String, bool> _prayerSoundEnabled = {
    'bamdat': true,
    'gun': true,
    'oyle': true,
    'ikindi': true,
    'agsam': true,
    'yasy': true,
  };

  int _zikirCount = 0;
  int _selectedZikirIndex = 0;
  int _zikirTarget = 33;

  Timer? _prayerTimer;
  String _countdownStr = '';
  String _nextPrayerKey = 'bamdat';
  String _activePrayerKey = 'bamdat';
  bool _isMekruh = false;
  int _mekruhMinutesLeft = 0;
  int? _lastPanelWhenMs;
  String? _lastPanelActiveKey;
  String? _lastPanelNextKey;

  bool get isReady => _isReady;
  bool get isDarkMode => _isDarkMode;
  DateTime get selectedDate => _selectedDate;
  bool get persistentNotificationEnabled => _persistentNotificationEnabled;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  Map<String, int> get offsets => _offsets;
  Map<String, bool> get prayerSoundEnabled => Map.unmodifiable(_prayerSoundEnabled);
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
    _computePrayerState();

    _isReady = true;
    notifyListeners();

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
      for (final key in _prayerSoundEnabled.keys) {
        _prayerSoundEnabled[key] = prefs.getBool('prayer_sound_$key') ?? true;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading settings: $e');
    }

    _computePrayerState();
    notifyListeners();

    try {
      await NotificationService().initialize();
      // When user taps the persistent panel notification, immediately re-show it
      // so it never disappears from the notification shade.
      NotificationService.onPanelTapped = () {
        if (_persistentNotificationEnabled) {
          _lastPanelWhenMs = null; // Force a fresh re-show
          _lastPanelActiveKey = null;
          _lastPanelNextKey = null;
          _updatePersistentPanel();
        }
      };
      await _rescheduleNotifications();
      _updatePersistentPanel();
    } catch (e) {
      // ignore: avoid_print
      print('Notification setup error: $e');
    }

    _startPrayerTimer();
  }

  Future<void> _rescheduleNotifications() async {
    await NotificationService().schedulePrayerNotifications(
      prayerService: prayerService,
      offsets: _offsets,
      soundEnabled: _notificationSoundEnabled,
      prayerSoundEnabled: _prayerSoundEnabled,
      persistentPanelEnabled: _persistentNotificationEnabled,
    );
  }

  void _startPrayerTimer() {
    _prayerTimer?.cancel();
    _prayerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computePrayerState();
    });
  }

  void tickPrayerTimer() => _computePrayerState();

  Future<void> refreshOnResume() async {
    if (!_isReady) return;
    // Reset all three cached state keys so _updatePersistentPanel always
    // re-shows the panel immediately when resuming from background or
    // when the notification is tapped.
    _lastPanelWhenMs = null;
    _lastPanelActiveKey = null;
    _lastPanelNextKey = null;
    _computePrayerState();
    try {
      await _rescheduleNotifications();
      _updatePersistentPanel();
    } catch (_) {}
  }

  void _computePrayerState() {
    if (!prayerService.isLoaded) return;

    final now = DateTime.now();
    final selectedDate = _selectedDate;
    final service = prayerService;

    // For showing the active prayer and mekruh on the selected date,
    // we use a datetime that has today's clock but the selected date's calendar.
    final targetDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final activeKey = service.getActivePrayerKey(targetDateTime, _offsets);

    // Always compute next prayer from real now to prevent negative countdowns
    // when returning to the app or during state transitions.
    final nextInfo = service.getNextPrayerInfo(now, _offsets);
    final nextKey = nextInfo['key'] as String;
    final nextDateTime = nextInfo['dateTime'] as DateTime;

    // Clamp to zero to prevent negative display during brief timing gaps
    final rawDiff = nextDateTime.difference(now);
    final difference = rawDiff.isNegative ? Duration.zero : rawDiff;

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
        diffToAgsam.inMinutes <= 30 &&
        diffToAgsam.inMinutes >= 0) {
      isMekruh = true;
      mekruhMinutesLeft = diffToAgsam.inMinutes + 1;
    }

    _countdownStr = countdownStr;
    _nextPrayerKey = nextKey;
    _activePrayerKey = activeKey;
    _isMekruh = isMekruh;
    _mekruhMinutesLeft = mekruhMinutesLeft;
    notifyListeners();

    _updatePersistentPanel();
  }

  void _updatePersistentPanel() {
    if (!_persistentNotificationEnabled) return;
    if (!prayerService.isLoaded) return;

    final now = DateTime.now();
    final service = prayerService;

    // Always compute persistent panel info based on real "now" so the
    // status bar notification is always correct for today, even when
    // the user is browsing other calendar dates in the app UI.
    final nextInfo = service.getNextPrayerInfo(now, _offsets);
    final nextKey = nextInfo['key'] as String;
    final nextDateTime = nextInfo['dateTime'] as DateTime;
    final whenMs = nextDateTime.millisecondsSinceEpoch;

    final activeKey = service.getActivePrayerKey(now, _offsets);

    final panelState = '${whenMs}_${activeKey}_$nextKey';
    if (panelState == '${_lastPanelWhenMs}_${_lastPanelActiveKey}_$_lastPanelNextKey') {
      return;
    }
    // #region agent log
    agentDebugLog(
      location: 'app_state.dart:_updatePersistentPanel',
      message: 'panel state changed, updating notification',
      hypothesisId: 'D',
      data: {
        'activeKey': activeKey,
        'nextKey': nextKey,
        'whenMs': whenMs,
        'previousActiveKey': _lastPanelActiveKey,
        'previousNextKey': _lastPanelNextKey,
      },
      runId: 'post-fix',
    );
    // #endregion
    _lastPanelWhenMs = whenMs;
    _lastPanelActiveKey = activeKey;
    _lastPanelNextKey = nextKey;

    final todayDate = DateTime(now.year, now.month, now.day);
    final dailyTimes = service.getTimesForDate(todayDate);
    NotificationService().showPersistentNotification(
      nextPrayerKey: nextKey,
      nextPrayerDateTime: nextDateTime,
      dailyTimes: dailyTimes,
      offsets: _offsets,
      activePrayerKey: activeKey,
    );
    NotificationService().rescheduleNextPanelRefresh(
      prayerService: service,
      offsets: _offsets,
    );
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
    _lastPanelWhenMs = null;
    _lastPanelActiveKey = null;
    _lastPanelNextKey = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persistent_notification_enabled', val);
    if (!val) {
      await NotificationService().cancelPersistentNotification();
    } else {
      await _rescheduleNotifications();
      _updatePersistentPanel();
    }
  }

  Future<void> toggleNotificationSound(bool val) async {
    _notificationSoundEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound_enabled', val);
    await _rescheduleNotifications();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _lastPanelWhenMs = null;
    _lastPanelActiveKey = null;
    _lastPanelNextKey = null;
    notifyListeners();
    _computePrayerState();
  }

  void resetToToday() {
    _selectedDate = DateTime.now();
    _lastPanelWhenMs = null;
    _lastPanelActiveKey = null;
    _lastPanelNextKey = null;
    notifyListeners();
    _computePrayerState();
  }

  Future<void> setOffset(String key, int val) async {
    if (_offsets.containsKey(key)) {
      _offsets[key] = val;
      _lastPanelWhenMs = null;
      _lastPanelActiveKey = null;
      _lastPanelNextKey = null;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('offset_$key', val);
      await _rescheduleNotifications();
      _computePrayerState();
    }
  }

  Future<void> setPrayerSoundEnabled(String key, bool val) async {
    if (_prayerSoundEnabled.containsKey(key)) {
      _prayerSoundEnabled[key] = val;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prayer_sound_$key', val);
      await _rescheduleNotifications();
    }
  }

  Future<void> resetOffsets() async {
    for (final key in _offsets.keys) {
      _offsets[key] = 0;
    }
    _lastPanelWhenMs = null;
    _lastPanelActiveKey = null;
    _lastPanelNextKey = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    for (final key in _offsets.keys) {
      await prefs.setInt('offset_$key', 0);
    }
    await _rescheduleNotifications();
    _computePrayerState();
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

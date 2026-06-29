import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../config/notification_sounds.dart';
import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../utils/tk_translations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String _activeSoundId = NotificationSounds.defaultSoundId;

  static const int persistentNotificationId = 8888;
  static const int alertBaseId = 1000;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _persistentChannel = AndroidNotificationChannel(
    'persistent_prayer_times',
    'Yzygiderli wagtlar paneli',
    description: 'Namaz wagtlayny we galan wagty görkezýän panel',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  Future<void> initialize() async {
    if (_isInitialized || !_isAndroid) return;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ashgabat'));
    } catch (e) {
      debugPrint('NotificationService timezone error: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (_) {},
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(_persistentChannel);
        await _ensureAlertChannel(android, _activeSoundId);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  String _channelIdForSound(String soundId) => 'prayer_alerts_$soundId';

  AndroidNotificationChannel _alertChannelFor(String soundId) =>
      AndroidNotificationChannel(
        _channelIdForSound(soundId),
        'Namaz wagty habarlandyryşy',
        description: 'Namaz wagty gelende bildiriş iberýär',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundId),
        enableVibration: true,
      );

  Future<void> _ensureAlertChannel(
    AndroidFlutterLocalNotificationsPlugin android,
    String soundId,
  ) async {
    await android.createNotificationChannel(_alertChannelFor(soundId));
    _activeSoundId = soundId;
  }

  Future<bool> requestPermissions() async {
    if (!_isAndroid) return true;
    if (!_isInitialized) await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    try {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('requestPermissions error: $e');
      return false;
    }
  }

  String _adj(String key, String base, Map<String, int> offsets) {
    final off = offsets[key] ?? 0;
    if (off == 0) return base;
    try {
      final parts = base.split(':');
      final dt =
          DateTime(2026, 1, 1, int.parse(parts[0]), int.parse(parts[1]))
              .add(Duration(minutes: off));
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return base;
    }
  }

  String _formatPrayerLine(
    String key,
    String time,
    String activeKey,
    String nextKey,
  ) {
    final name = (TkTranslations.prayerNamesShort[key] ?? key).padRight(6);
    final marker = key == activeKey ? ' ◆' : (key == nextKey ? ' ▶' : '  ');
    return '$name $time$marker';
  }

  Future<void> showPersistentNotification({
    required String nextPrayerKey,
    required String remainingTime,
    required PrayerTime dailyTimes,
    required Map<String, int> offsets,
    required String activePrayerKey,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final nextPrayerName =
        TkTranslations.prayerNamesShort[nextPrayerKey] ?? nextPrayerKey;

    const keys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];

    final lines = <String>[];
    for (final key in keys) {
      final raw = dailyTimes.getTimeByKey(key);
      final time = _adj(key, raw, offsets);
      lines.add(_formatPrayerLine(key, time, activePrayerKey, nextPrayerKey));
    }

    final body = lines.join('\n');

    final androidDetails = AndroidNotificationDetails(
      'persistent_prayer_times',
      'Yzygiderli wagtlar paneli',
      channelDescription: 'Namaz wagtlayny we galan wagty görkezýän panel',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: '$nextPrayerName namazyna — $remainingTime galdy',
        summaryText: 'Gazojak namaz wagtlary',
      ),
    );

    try {
      await _plugin.show(
        id: persistentNotificationId,
        title: '$nextPrayerName namazyna — $remainingTime galdy',
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('showPersistentNotification error: $e');
    }
  }

  Future<void> cancelPersistentNotification() async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();
    try {
      await _plugin.cancel(id: persistentNotificationId);
    } catch (e) {
      debugPrint('cancelPersistentNotification error: $e');
    }
  }

  AndroidNotificationDetails _alertDetails(bool playSound, String soundId) =>
      AndroidNotificationDetails(
        _channelIdForSound(soundId),
        'Namaz wagty habarlandyryşy',
        channelDescription: 'Namaz wagty gelende bildiriş iberýär',
        importance:
            playSound ? Importance.max : Importance.defaultImportance,
        priority: playSound ? Priority.high : Priority.defaultPriority,
        playSound: playSound,
        sound: playSound ? RawResourceAndroidNotificationSound(soundId) : null,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

  Future<void> schedulePrayerNotifications({
    required PrayerTimeService prayerService,
    required Map<String, int> offsets,
    required bool soundEnabled,
    required String soundId,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();
    if (!prayerService.isLoaded) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null && soundId != _activeSoundId) {
      await _ensureAlertChannel(android, soundId);
    }

    await _cancelScheduledAlerts();

    final now = DateTime.now();
    final dates = [now, now.add(const Duration(days: 1))];
    const prayerKeys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];

    for (var dayIndex = 0; dayIndex < dates.length; dayIndex++) {
      final date = dates[dayIndex];
      final times = prayerService.getAdjustedDateTimes(date, offsets);

      for (var i = 0; i < prayerKeys.length; i++) {
        final key = prayerKeys[i];
        final prayerTime = times[key]!;
        if (!prayerTime.isAfter(now)) continue;

        final prayerName = TkTranslations.prayerNamesShort[key] ?? key;
        final id = alertBaseId + dayIndex * 10 + i;
        final tzTime = tz.TZDateTime.from(prayerTime, tz.local);

        try {
          await _plugin.zonedSchedule(
            id: id,
            title: 'Namaz Wagty Boldy',
            body:
                'Gazojak şäherinde $prayerName wagty girdi. Namazyňyzy berjaý etmegi unutmaň.',
            scheduledDate: tzTime,
            notificationDetails: NotificationDetails(
              android: _alertDetails(soundEnabled, soundId),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('schedulePrayerNotifications error ($key): $e');
        }
      }
    }
  }

  Future<void> previewAlertSound(String soundId) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await _ensureAlertChannel(android, soundId);
    }

    try {
      await _plugin.show(
        id: 7777,
        title: 'Ses synagy',
        body: NotificationSounds.optionById(soundId).label,
        notificationDetails: NotificationDetails(
          android: _alertDetails(true, soundId),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        _plugin.cancel(id: 7777);
      });
    } catch (e) {
      debugPrint('previewAlertSound error: $e');
    }
  }

  Future<void> _cancelScheduledAlerts() async {
    for (var id = alertBaseId; id < alertBaseId + 30; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelAllPrayerAlerts() async {
    await _cancelScheduledAlerts();
  }
}

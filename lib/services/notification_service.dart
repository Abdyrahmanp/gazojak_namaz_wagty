import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
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

  static const int persistentNotificationId = 8888;
  static const int alertBaseId = 1000;
  static const int panelRefreshBaseId = 8900;
  static const Color _panelAccent = Color(0xFF2E7D32);
  static const String _greenHtml = '#43A047';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _persistentChannel = AndroidNotificationChannel(
    'persistent_prayer_times',
    'Yzygiderli wagtlar paneli',
    description: 'Namaz wagtlary we galan wagty görkezýär',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  static const _alertChannel = AndroidNotificationChannel(
    'prayer_alerts',
    'Namaz wagty habarlandyryşy',
    description: 'Namaz wagty gelende bildiriş iberýär',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
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
        await android.createNotificationChannel(_alertChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
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

  String _buildPanelBodyHtml(
    PrayerTime dailyTimes,
    Map<String, int> offsets,
    String activeKey,
  ) {
    const keys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];
    final lines = <String>[];
    for (final key in keys) {
      final raw = dailyTimes.getTimeByKey(key);
      final time = _adj(key, raw, offsets);
      final name = TkTranslations.prayerNamesShort[key] ?? key;
      final padded = name.padRight(8);
      if (key == activeKey) {
        lines.add(
          '<font color="$_greenHtml"><b>$padded $time</b></font>',
        );
      } else {
        lines.add('$padded $time');
      }
    }
    return lines.join('<br/>');
  }

  String _panelTitle(String nextPrayerName, String remainingTime) =>
      '$nextPrayerName namazyna $remainingTime galdy';

  AndroidNotificationDetails _persistentDetails({
    required String bodyHtml,
  }) {
    return AndroidNotificationDetails(
      'persistent_prayer_times',
      'Yzygiderli wagtlar paneli',
      channelDescription: 'Namaz wagtlary we galan wagty görkezýär',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      silent: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      color: _panelAccent,
      colorized: true,
      styleInformation: BigTextStyleInformation(
        bodyHtml,
        htmlFormatBigText: true,
      ),
    );
  }

  Future<void> showPersistentNotification({
    required String nextPrayerKey,
    required String remainingTime,
    required DateTime nextPrayerDateTime,
    required PrayerTime dailyTimes,
    required Map<String, int> offsets,
    required String activePrayerKey,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final nextPrayerName =
        TkTranslations.prayerNamesShort[nextPrayerKey] ?? nextPrayerKey;
    final title = _panelTitle(nextPrayerName, remainingTime);
    final bodyHtml = _buildPanelBodyHtml(dailyTimes, offsets, activePrayerKey);

    try {
      await _plugin.show(
        id: persistentNotificationId,
        title: title,
        body: bodyHtml.replaceAll(RegExp(r'<[^>]*>'), ''),
        notificationDetails: NotificationDetails(
          android: _persistentDetails(bodyHtml: bodyHtml),
        ),
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
    await _cancelPanelRefreshes();
  }

  AndroidNotificationDetails _alertDetails(bool playSound) =>
      AndroidNotificationDetails(
        'prayer_alerts',
        'Namaz wagty habarlandyryşy',
        channelDescription: 'Namaz wagty gelende bildiriş iberýär',
        importance:
            playSound ? Importance.max : Importance.defaultImportance,
        priority: playSound ? Priority.high : Priority.defaultPriority,
        playSound: playSound,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        color: _panelAccent,
      );

  Future<void> schedulePrayerNotifications({
    required PrayerTimeService prayerService,
    required Map<String, int> offsets,
    required bool soundEnabled,
    required bool persistentPanelEnabled,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();
    if (!prayerService.isLoaded) return;

    await _cancelScheduledAlerts();
    if (persistentPanelEnabled) {
      await _scheduleNextPanelRefresh(prayerService, offsets);
    }

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
            notificationDetails:
                NotificationDetails(android: _alertDetails(soundEnabled)),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('schedulePrayerNotifications error ($key): $e');
        }
      }
    }
  }

  Future<void> _scheduleNextPanelRefresh(
    PrayerTimeService prayerService,
    Map<String, int> offsets,
  ) async {
    await _cancelPanelRefreshes();

    final now = DateTime.now();
    DateTime? nearest;
    DateTime? nearestDay;

    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      final dayDate = DateTime(date.year, date.month, date.day);
      for (final t in prayerService.getAdjustedDateTimes(date, offsets).values) {
        if (t.isAfter(now) && (nearest == null || t.isBefore(nearest))) {
          nearest = t;
          nearestDay = dayDate;
        }
      }
    }

    if (nearest == null || nearestDay == null) return;

    final atTime = nearest;
    final dailyTimes = prayerService.getTimesForDate(nearestDay);
    final activeKey = prayerService.getActivePrayerKey(atTime, offsets);
    final nextInfo = prayerService.getNextPrayerInfo(atTime, offsets);
    final nextKey = nextInfo['key'] as String;
    final nextDt = nextInfo['dateTime'] as DateTime;
    final nextName = TkTranslations.prayerNamesShort[nextKey] ?? nextKey;
    final diff = nextDt.difference(atTime);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    final remaining =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final title = _panelTitle(nextName, remaining);
    final bodyHtml = _buildPanelBodyHtml(dailyTimes, offsets, activeKey);

    try {
      await _plugin.zonedSchedule(
        id: persistentNotificationId,
        title: title,
        body: bodyHtml.replaceAll(RegExp(r'<[^>]*>'), ''),
        scheduledDate: tz.TZDateTime.from(atTime, tz.local),
        notificationDetails: NotificationDetails(
          android: _persistentDetails(bodyHtml: bodyHtml),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('panel refresh schedule error: $e');
    }
  }

  Future<void> _cancelPanelRefreshes() async {
    for (var id = panelRefreshBaseId; id < panelRefreshBaseId + 20; id++) {
      await _plugin.cancel(id: id);
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

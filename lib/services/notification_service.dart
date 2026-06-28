import 'package:flutter/foundation.dart';
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
  String? _lastAlertedPrayerKey;

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

  Future<void> showPersistentNotification({
    required String nextPrayerName,
    required String remainingTime,
    required PrayerTime dailyTimes,
    required Map<String, int> offsets,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final b = _adj('bamdat', dailyTimes.bamdat, offsets);
    final g = _adj('gun', dailyTimes.gun, offsets);
    final o = _adj('oyle', dailyTimes.oyle, offsets);
    final i = _adj('ikindi', dailyTimes.ikindi, offsets);
    final a = _adj('agsam', dailyTimes.agsam, offsets);
    final y = _adj('yasy', dailyTimes.yasy, offsets);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    );

    try {
      await _plugin.show(
        id: persistentNotificationId,
        title: 'Indiki: $nextPrayerName ($remainingTime galdy)',
        body: 'E:$b  G:$g  Ö:$o  I:$i  A:$a  Ý:$y',
        notificationDetails:
            const NotificationDetails(android: androidDetails),
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

  Future<void> showPrayerAlert(String prayerKey, bool playSound) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final prayerName =
        TkTranslations.prayerNamesShort[prayerKey] ?? prayerKey;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_alerts',
      'Namaz wagty habarlandyryşy',
      channelDescription: 'Namaz wagty gelende bildiriş iberýär',
      importance: playSound ? Importance.max : Importance.defaultImportance,
      priority: playSound ? Priority.high : Priority.defaultPriority,
      playSound: playSound,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _plugin.show(
        id: alertBaseId + prayerKey.hashCode.abs() % 1000,
        title: 'Namaz Wagty Boldy',
        body:
            'Gazojak şäherinde $prayerName wagty girdi. Namazyňyzy berjaý etmegi unutmaň.',
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('showPrayerAlert error: $e');
    }
  }

  void checkPrayerTransition({
    required String activePrayerKey,
    required bool soundEnabled,
    required bool isShowingToday,
  }) {
    if (!_isAndroid || !isShowingToday) return;

    if (_lastAlertedPrayerKey != null &&
        _lastAlertedPrayerKey != activePrayerKey) {
      showPrayerAlert(activePrayerKey, soundEnabled);
    }
    _lastAlertedPrayerKey = activePrayerKey;
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimeService prayerService,
    required Map<String, int> offsets,
    required bool soundEnabled,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();
    if (!prayerService.isLoaded) return;

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

        final prayerName =
            TkTranslations.prayerNamesShort[key] ?? key;
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
              android: AndroidNotificationDetails(
                'prayer_alerts',
                'Namaz wagty habarlandyryşy',
                channelDescription: 'Namaz wagty gelende bildiriş iberýär',
                importance: soundEnabled
                    ? Importance.max
                    : Importance.defaultImportance,
                priority:
                    soundEnabled ? Priority.high : Priority.defaultPriority,
                playSound: soundEnabled,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('schedulePrayerNotifications error ($key): $e');
        }
      }
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

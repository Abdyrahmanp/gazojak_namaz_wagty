import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/prayer_time.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int persistentNotificationId = 8888;
  static const int alertBaseId = 1000;

  Future<void> initialize() async {
    if (_isInitialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse r) {},
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
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
    required String activePrayerName,
    required String nextPrayerName,
    required String remainingTime,
    required PrayerTime dailyTimes,
    required Map<String, int> offsets,
  }) async {
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
    if (!_isInitialized) await initialize();
    try {
      await _plugin.cancel(id: persistentNotificationId);
    } catch (e) {
      debugPrint('cancelPersistentNotification error: $e');
    }
  }

  Future<void> showPrayerAlert(String prayerName, bool playSound) async {
    if (!_isInitialized) await initialize();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_alerts',
      'Namaz wagty habarlandyryşy',
      channelDescription: 'Namaz wagty gelende bildiriş iberýär',
      importance: playSound ? Importance.max : Importance.defaultImportance,
      priority: playSound ? Priority.high : Priority.defaultPriority,
      playSound: playSound,
      enableVibration: true,
    );

    try {
      await _plugin.show(
        id: alertBaseId + prayerName.hashCode.abs() % 1000,
        title: 'Namaz Wagty Boldy',
        body:
            'Gazojak şäherinde $prayerName wagty girdi. Namazyňyzy berjaý etmegi unutmaň.',
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('showPrayerAlert error: $e');
    }
  }
}

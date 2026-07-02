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
  static const String _panelTag = 'gazojak_prayer_panel';
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

    // Use the vector XML drawable (no PNG anymore)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
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
      final line = '$name: $time';
      if (key == activeKey) {
        lines.add(
          '<font color="$_greenHtml"><b>$line (şu wagt)</b></font>',
        );
      } else {
        lines.add('<font color="#CBD5E1">$line</font>');
      }
    }
    return lines.join('<br/>');
  }

  /// Panel başlığı: 'gun' key için özel yazı, diğerleri için 'namazyna galdy'
  String _panelTitle(String prayerKey, String prayerName) {
    if (prayerKey == 'gun') {
      return 'Günüň dogmagy wagty boldy';
    }
    return '$prayerName namazyna galdy';
  }

  AndroidNotificationDetails _persistentDetails({
    required String bodyHtml,
    required int whenMs,
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
      onlyAlertOnce: true,
      showWhen: true,
      when: whenMs,
      usesChronometer: true,
      chronometerCountDown: true,
      // Icon kaldırıldı — platform varsayılan ikonu kullanılacak
      // largeIcon kaldırıldı — sağdaki büyük resim kaldırıldı
      color: _panelAccent,
      tag: _panelTag,
      styleInformation: BigTextStyleInformation(
        bodyHtml,
        htmlFormatBigText: true,
        contentTitle: null,
      ),
    );
  }

  Future<void> showPersistentNotification({
    required String nextPrayerKey,
    required DateTime nextPrayerDateTime,
    required PrayerTime dailyTimes,
    required Map<String, int> offsets,
    required String activePrayerKey,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();

    final nextPrayerName =
        TkTranslations.prayerNamesShort[nextPrayerKey] ?? nextPrayerKey;
    final title = _panelTitle(nextPrayerKey, nextPrayerName);
    final bodyHtml = _buildPanelBodyHtml(dailyTimes, offsets, activePrayerKey);
    final whenMs = nextPrayerDateTime.millisecondsSinceEpoch;

    try {
      await _plugin.show(
        id: persistentNotificationId,
        title: title,
        body: '',
        notificationDetails: NotificationDetails(
          android: _persistentDetails(bodyHtml: bodyHtml, whenMs: whenMs),
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
      await _cancelAllPanelNotifications();
    } catch (e) {
      debugPrint('cancelPersistentNotification error: $e');
    }
  }

  AndroidNotificationDetails _alertDetails(bool playSound) {
    return AndroidNotificationDetails(
      'prayer_alerts',
      'Namaz wagty habarlandyryşy',
      channelDescription: 'Namaz wagty gelende bildiriş iberýär',
      importance: Importance.max,
      priority: Priority.max,
      // Telefon sessizde olsa bile titreşim we ses
      playSound: playSound,
      enableVibration: true,
      // Alarm tipi ses kanaly — DND/sessiz modyny aşar
      audioAttributesUsage: AudioAttributesUsage.alarm,
      color: _panelAccent,
    );
  }


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
      await _schedulePanelRefreshes(prayerService, offsets);
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

        // 'gun' için özel başlık/metin
        final bool isGunDogmagy = key == 'gun';
        final String notifTitle = isGunDogmagy
            ? 'Günüň dogmagy wagty boldy'
            : '$prayerName namazy boldy';
        final String notifBody = isGunDogmagy
            ? 'Gazojak şäherinde gün dogdy. Ertir namazynyň wagty geçýär.'
            : 'Gazojak şäherinde $prayerName wagty girdi. Namazyňyzy berjaý etmegi unutmaň.';

        try {
          await _plugin.zonedSchedule(
            id: id,
            title: notifTitle,
            body: notifBody,
            scheduledDate: tzTime,
            notificationDetails: NotificationDetails(
              android: _alertDetails(soundEnabled),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('schedulePrayerNotifications error ($key): $e');
        }
      }
    }
  }

  Future<void> _schedulePanelRefreshes(
    PrayerTimeService prayerService,
    Map<String, int> offsets,
  ) async {
    // Sadece planlı yenilemeleri iptal et — aktif panel bildirimi kaybolmasın
    await _cancelScheduledPanelRefreshes();

    final now = DateTime.now();

    // Her namaz vakti için panel yenileme planla (today + tomorrow)
    const prayerKeys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];

    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      final times = prayerService.getAdjustedDateTimes(date, offsets);
      final dayDate = DateTime(date.year, date.month, date.day);
      final dailyTimes = prayerService.getTimesForDate(dayDate);

      for (var i = 0; i < prayerKeys.length; i++) {
        final atKey = prayerKeys[i];
        final atTime = times[atKey]!;

        // Sadece gelecekteki vakitler için planla
        if (!atTime.isAfter(now)) continue;

        // O vakit başladığında aktif namaz bu olacak
        final activeKey = atKey;
        // Sonraki namazı bul
        final nextInfo = prayerService.getNextPrayerInfo(atTime.add(const Duration(seconds: 1)), offsets);
        final nextKey = nextInfo['key'] as String;
        final nextDt = nextInfo['dateTime'] as DateTime;

        final nextPrayerName = TkTranslations.prayerNamesShort[nextKey] ?? nextKey;
        final title = _panelTitle(nextKey, nextPrayerName);
        final bodyHtml = _buildPanelBodyHtml(dailyTimes, offsets, activeKey);
        final whenMs = nextDt.millisecondsSinceEpoch;

        // Her vakit için farklı ID kullan (tag ile gruplama)
        final scheduleId = persistentNotificationId + dayOffset * 10 + i + 1;

        try {
          await _plugin.zonedSchedule(
            id: scheduleId,
            title: title,
            body: '',
            scheduledDate: tz.TZDateTime.from(atTime, tz.local),
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'persistent_prayer_times',
                'Yzygiderli wagtlar paneli',
                channelDescription: 'Namaz wagtlary we galan wagty görkezýär',
                importance: Importance.low,
                priority: Priority.low,
                ongoing: true,
                autoCancel: false,
                silent: true,
                onlyAlertOnce: true,
                showWhen: true,
                when: whenMs,
                usesChronometer: true,
                chronometerCountDown: true,
                color: _panelAccent,
                tag: _panelTag,
                styleInformation: BigTextStyleInformation(
                  bodyHtml,
                  htmlFormatBigText: true,
                  contentTitle: null,
                ),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('panel refresh schedule error ($atKey): $e');
        }
      }
    }
  }

  /// Sadece gelecekte planlanmış panel yenileme bildirimlerini iptal eder.
  /// Ana panel (ID 8888) bu fonksiyon tarafından iptal EDİLMEZ.
  Future<void> _cancelScheduledPanelRefreshes() async {
    for (var i = 1; i <= 22; i++) {
      try {
        await _plugin.cancel(id: persistentNotificationId + i, tag: _panelTag);
      } catch (_) {}
    }
  }

  /// Hem ana paneli hem tüm planlanmış yenilemeleri iptal eder.
  /// Sadece kullanıcı 'paneli kapat' dediğinde çağrılmalı.
  Future<void> _cancelAllPanelNotifications() async {
    await _plugin.cancel(id: persistentNotificationId, tag: _panelTag);
    await _cancelScheduledPanelRefreshes();
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

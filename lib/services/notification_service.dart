import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer_time.dart';
import '../services/prayer_time_service.dart';
import '../utils/agent_debug_log.dart';
import '../utils/tk_translations.dart';

/// Top-level function required by flutter_local_notifications for background
/// notification tap handling. Must be annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  // No-op in background isolate — foreground handler in NotificationService
  // handles the re-show logic via onPanelTapped callback.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int persistentNotificationId = 8888;
  static const int alertBaseId = 1000;
  static const Color _panelAccent = Color(0xFF2E7D32);
  static const String _greenHtml = '#43A047';

  /// Called by AppState after initialize(). When the persistent panel
  /// notification is tapped by the user, this callback re-shows the panel
  /// immediately so it never disappears until the user turns it off in settings.
  static void Function()? onPanelTapped;

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
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Re-show the active panel if the user taps either the active panel
          // (8888) or any of the scheduled refresh notifications (8889-8910).
          final id = response.id ?? -1;
          final isPanelNotification = id == persistentNotificationId ||
              (id >= _panelRefreshBaseId &&
               id < _panelRefreshBaseId + _panelRefreshCount);
          if (isPanelNotification) {
            // #region agent log
            agentDebugLog(
              location: 'notification_service.dart:onPanelTap',
              message: 'panel notification tapped',
              hypothesisId: 'E',
              data: {'id': id},
            );
            // #endregion
            onPanelTapped?.call();
          }
        },
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
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

  /// Panel başlığı: ähli key'ler üçin galdy formatı
  String _panelTitle(String prayerKey, String prayerName) {
    if (prayerKey == 'gun') {
      return 'Günüň dogmagyna galdy';
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
      color: _panelAccent,
      // No tag — using ID alone avoids OEM-specific tag cancel bugs.
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
      // Remove any legacy duplicate panel notifications (old 8889-8910 approach).
      await _cancelScheduledPanelRefreshes();
      // #region agent log
      agentDebugLog(
        location: 'notification_service.dart:showPersistentNotification',
        message: 'showing active panel on id 8888',
        hypothesisId: 'B',
        data: {
          'notificationId': persistentNotificationId,
          'activePrayerKey': activePrayerKey,
          'nextPrayerKey': nextPrayerKey,
          'whenMs': whenMs,
        },
        runId: 'post-fix',
      );
      // #endregion
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

  // Legacy IDs 8889-8910 from an older approach that caused duplicate panels.
  // Still cancelled on startup/show to clean up devices that already have them.
  static const int _panelRefreshBaseId = 8889;
  static const int _panelRefreshCount = 22;

  /// Reschedule only the next panel refresh (used after prayer transitions).
  Future<void> rescheduleNextPanelRefresh({
    required PrayerTimeService prayerService,
    required Map<String, int> offsets,
  }) async {
    if (!_isAndroid) return;
    if (!_isInitialized) await initialize();
    if (!prayerService.isLoaded) return;
    await _schedulePanelRefreshes(prayerService, offsets);
  }

  Future<void> _schedulePanelRefreshes(
    PrayerTimeService prayerService,
    Map<String, int> offsets,
  ) async {
    await _cancelScheduledPanelRefreshes();

    final now = DateTime.now();
    const prayerKeys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];

    DateTime? nearestAtTime;
    String? nearestActiveKey;
    String? nearestNextKey;
    DateTime? nearestNextDt;
    PrayerTime? nearestDailyTimes;

    for (final dayOffset in [0, 1]) {
      final date = now.add(Duration(days: dayOffset));
      final times = prayerService.getAdjustedDateTimes(date, offsets);
      final dayDate = DateTime(date.year, date.month, date.day);
      final dailyTimes = prayerService.getTimesForDate(dayDate);

      for (final atKey in prayerKeys) {
        final atTime = times[atKey]!;
        if (!atTime.isAfter(now)) continue;

        if (nearestAtTime == null || atTime.isBefore(nearestAtTime)) {
          nearestAtTime = atTime;
          nearestActiveKey = atKey;
          nearestDailyTimes = dailyTimes;
          final nextInfo = prayerService.getNextPrayerInfo(
            atTime.add(const Duration(seconds: 1)),
            offsets,
          );
          nearestNextKey = nextInfo['key'] as String;
          nearestNextDt = nextInfo['dateTime'] as DateTime;
        }
      }
    }

    if (nearestAtTime == null ||
        nearestActiveKey == null ||
        nearestNextKey == null ||
        nearestNextDt == null ||
        nearestDailyTimes == null) {
      return;
    }

    final nextPrayerName =
        TkTranslations.prayerNamesShort[nearestNextKey] ?? nearestNextKey;
    final title = _panelTitle(nearestNextKey, nextPrayerName);
    final bodyHtml =
        _buildPanelBodyHtml(nearestDailyTimes, offsets, nearestActiveKey);
    final whenMs = nearestNextDt.millisecondsSinceEpoch;

    try {
      // #region agent log
      agentDebugLog(
        location: 'notification_service.dart:_schedulePanelRefreshes',
        message: 'scheduling next panel refresh on same id as active panel',
        hypothesisId: 'A',
        data: {
          'scheduleId': persistentNotificationId,
          'activeKey': nearestActiveKey,
          'nextKey': nearestNextKey,
          'atTime': nearestAtTime.toIso8601String(),
        },
        runId: 'post-fix',
      );
      // #endregion
      await _plugin.zonedSchedule(
        id: persistentNotificationId,
        title: title,
        body: '',
        scheduledDate: tz.TZDateTime.from(nearestAtTime, tz.local),
        notificationDetails: NotificationDetails(
          android: _persistentDetails(bodyHtml: bodyHtml, whenMs: whenMs),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint(
        'panel refresh schedule error ($nearestActiveKey, id=$persistentNotificationId): $e',
      );
    }
  }

  /// Cancels legacy duplicate panel notifications (IDs 8889-8910).
  Future<void> _cancelScheduledPanelRefreshes() async {
    // #region agent log
    agentDebugLog(
      location: 'notification_service.dart:_cancelScheduledPanelRefreshes',
      message: 'cancelling scheduled panel refresh ids 8889-8910',
      hypothesisId: 'C',
      data: {
        'baseId': _panelRefreshBaseId,
        'count': _panelRefreshCount,
        'activePanelId': persistentNotificationId,
      },
    );
    // #endregion
    for (var id = _panelRefreshBaseId;
        id < _panelRefreshBaseId + _panelRefreshCount;
        id++) {
      try {
        await _plugin.cancel(id: id); // No tag needed — ID alone identifies it.
      } catch (_) {}
    }
  }

  /// Cancels the active ongoing panel (8888) AND all scheduled refreshes (8889-8910).
  /// Only call when the user explicitly disables the feature in settings.
  Future<void> _cancelAllPanelNotifications() async {
    // #region agent log
    agentDebugLog(
      location: 'notification_service.dart:_cancelAllPanelNotifications',
      message: 'cancelling all panel notifications',
      hypothesisId: 'E',
      data: {
        'activePanelId': persistentNotificationId,
        'refreshBaseId': _panelRefreshBaseId,
      },
    );
    // #endregion
    try {
      await _plugin.cancel(id: persistentNotificationId); // No tag needed.
    } catch (_) {}
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

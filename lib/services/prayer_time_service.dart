import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/prayer_time.dart';

class PrayerTimeService {
  Map<String, dynamic> _rawJsonData = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // Gazojak, Turkmenistan coordinates
  static const double _lat = 41.08;
  static const double _lng = 60.03;
  static const int _utcOffset = 5; // UTC+5

  Future<void> loadDatabase() async {
    if (_isLoaded) return;
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/gazojak_times.json');
      _rawJsonData = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print('Error loading prayer times JSON: $e');
      _rawJsonData = {};
    }
  }

  String getDateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m-$d';
  }

  // ── Astronomical sunrise calculator ─────────────────────────────────────────
  // US Naval Observatory algorithm adapted for Gazojak (41.08°N, 60.03°E, UTC+5)
  String calculateSunriseStr(DateTime date) {
    try {
      final int dayOfYear =
          date.difference(DateTime(date.year, 1, 1)).inDays + 1;

      final double lngHour = _lng / 15.0;

      // Approximate time of sunrise
      final double t = dayOfYear + ((6.0 - lngHour) / 24.0);

      // Sun's mean anomaly (degrees)
      final double M = (0.9856 * t) - 3.289;
      final double Mrad = M * pi / 180.0;

      // Sun's true longitude (degrees)
      double L = M +
          (1.916 * sin(Mrad)) +
          (0.020 * sin(2.0 * Mrad)) +
          282.634;
      L = L % 360;
      if (L < 0) L += 360;

      // Sun's right ascension (degrees)
      double RA = atan(0.91764 * tan(L * pi / 180.0)) * 180.0 / pi;
      RA = RA % 360;
      if (RA < 0) RA += 360;

      final double Lq = (L / 90.0).floor() * 90.0;
      final double RAq = (RA / 90.0).floor() * 90.0;
      RA = (RA + (Lq - RAq)) / 15.0;

      // Sun's declination
      final double sinDec = 0.39782 * sin(L * pi / 180.0);
      final double cosDec = cos(asin(sinDec));

      // Local hour angle (official zenith = 90.833°)
      const double zenith = 90.833;
      final double cosH =
          (cos(zenith * pi / 180.0) - (sinDec * sin(_lat * pi / 180.0))) /
              (cosDec * cos(_lat * pi / 180.0));

      // Polar edge-cases (will not occur at Gazojak's latitude)
      if (cosH > 1 || cosH < -1) return '06:00';

      // Sunrise: use 360 - acos branch
      double H = (360.0 - acos(cosH) * 180.0 / pi) / 15.0;

      // Local mean time
      double T = H + RA - (0.06571 * t) - 6.622;

      // Convert to UTC then to local time
      double ut = T - lngHour;
      if (ut > 24) ut -= 24;
      if (ut < 0) ut += 24;

      double local = ut + _utcOffset;
      if (local >= 24) local -= 24;

      int hour = local.floor();
      int minute = ((local - hour) * 60).round();
      if (minute == 60) {
        hour++;
        minute = 0;
      }
      if (hour >= 24) hour -= 24;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '06:30';
    }
  }

  // ── Daily times lookup + sunrise injection ───────────────────────────────────
  PrayerTime getTimesForDate(DateTime date) {
    final key = getDateKey(date);
    final sunrise = calculateSunriseStr(date);

    if (_rawJsonData.containsKey(key)) {
      return PrayerTime.fromJson(
          key, _rawJsonData[key] as Map<String, dynamic>, sunrise);
    }
    return PrayerTime(
      dateKey: key,
      bamdat: '06:00',
      gun: sunrise,
      oyle: '13:00',
      ikindi: '16:30',
      agsam: '18:30',
      yasy: '20:00',
    );
  }

  DateTime getAdjustedDateTime(
      DateTime date, String timeStr, int offsetMinutes) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute)
        .add(Duration(minutes: offsetMinutes));
  }

  Map<String, DateTime> getAdjustedDateTimes(
      DateTime date, Map<String, int> offsets) {
    final t = getTimesForDate(date);
    return {
      'bamdat': getAdjustedDateTime(date, t.bamdat, offsets['bamdat'] ?? 0),
      'gun': getAdjustedDateTime(date, t.gun, offsets['gun'] ?? 0),
      'oyle': getAdjustedDateTime(date, t.oyle, offsets['oyle'] ?? 0),
      'ikindi': getAdjustedDateTime(date, t.ikindi, offsets['ikindi'] ?? 0),
      'agsam': getAdjustedDateTime(date, t.agsam, offsets['agsam'] ?? 0),
      'yasy': getAdjustedDateTime(date, t.yasy, offsets['yasy'] ?? 0),
    };
  }

  Map<String, dynamic> getNextPrayerInfo(
      DateTime now, Map<String, int> offsets) {
    final todayTimes = getAdjustedDateTimes(now, offsets);

    final sorted = todayTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sorted) {
      if (entry.value.isAfter(now)) {
        return {'key': entry.key, 'dateTime': entry.value};
      }
    }

    // Past Ýassy → next is Ertir (bamdat) of tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowTimes = getTimesForDate(tomorrow);
    final nextDt = getAdjustedDateTime(
        tomorrow, tomorrowTimes.bamdat, offsets['bamdat'] ?? 0);
    return {'key': 'bamdat', 'dateTime': nextDt};
  }

  String getActivePrayerKey(DateTime now, Map<String, int> offsets) {
    final t = getAdjustedDateTimes(now, offsets);

    if (now.isBefore(t['bamdat']!)) return 'yasy';
    if (now.isBefore(t['gun']!)) return 'bamdat';
    if (now.isBefore(t['oyle']!)) return 'gun';
    if (now.isBefore(t['ikindi']!)) return 'oyle';
    if (now.isBefore(t['agsam']!)) return 'ikindi';
    if (now.isBefore(t['yasy']!)) return 'agsam';
    return 'yasy';
  }
}

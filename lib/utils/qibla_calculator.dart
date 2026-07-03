import 'dart:math' as math;

/// Kaaba coordinates (Masjid al-Haram).
const double kaabaLatitude = 21.422487;
const double kaabaLongitude = 39.826206;

/// Gazojak default coordinates when GPS is unavailable.
const double gazojakLatitude = 41.08;
const double gazojakLongitude = 60.03;

/// Great-circle bearing from [lat]/[lng] to the Kaaba, in degrees (0–360, clockwise from true north).
double calculateQiblaBearing(double lat, double lng) {
  final latRad = lat * math.pi / 180;
  final lngRad = lng * math.pi / 180;
  final kaabaLatRad = kaabaLatitude * math.pi / 180;
  final kaabaLngRad = kaabaLongitude * math.pi / 180;

  final lngDiff = kaabaLngRad - lngRad;

  final y = math.sin(lngDiff);
  final x = math.cos(latRad) * math.tan(kaabaLatRad) -
      math.sin(latRad) * math.cos(lngDiff);

  var bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

/// Low-pass filter for compass headings, handling 0°/360° wrap-around.
class HeadingSmoother {
  double? _value;
  final double alpha;

  HeadingSmoother({this.alpha = 0.12});

  double smooth(double raw) {
    if (_value == null) {
      _value = raw;
      return raw;
    }

    var diff = raw - _value!;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    _value = (_value! + diff * alpha) % 360;
    if (_value! < 0) _value = _value! + 360;
    return _value!;
  }

  void reset() => _value = null;
}

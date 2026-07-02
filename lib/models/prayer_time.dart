class PrayerTime {
  final String dateKey; // MM-dd format
  final String bamdat;  // Ertir namazy
  final String gun;     // Günüň dogmagy (calculated, not from JSON)
  final String oyle;
  final String ikindi;
  final String agsam;
  final String yasy;    // Ýassy

  PrayerTime({
    required this.dateKey,
    required this.bamdat,
    required this.gun,
    required this.oyle,
    required this.ikindi,
    required this.agsam,
    required this.yasy,
  });

  factory PrayerTime.fromJson(
      String dateKey, Map<String, dynamic> json, String calculatedGun) {
    return PrayerTime(
      dateKey: dateKey,
      bamdat: json['bamdat'] as String? ?? '00:00',
      gun: calculatedGun,
      oyle: json['oyle'] as String? ?? '00:00',
      ikindi: json['ikindi'] as String? ?? '00:00',
      agsam: json['agsam'] as String? ?? '00:00',
      yasy: json['yasy'] as String? ?? '00:00',
    );
  }

  Map<String, String> asMap() {
    return {
      'bamdat': bamdat,
      'gun': gun,
      'oyle': oyle,
      'ikindi': ikindi,
      'agsam': agsam,
      'yasy': yasy,
    };
  }

  String getTimeByKey(String key) {
    switch (key) {
      case 'bamdat':
        return bamdat;
      case 'gun':
        return gun;
      case 'oyle':
        return oyle;
      case 'ikindi':
        return ikindi;
      case 'agsam':
        return agsam;
      case 'yasy':
        return yasy;
      default:
        return '00:00';
    }
  }
}

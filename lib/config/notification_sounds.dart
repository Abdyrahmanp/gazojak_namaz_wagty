/// Namaz wagty bildiriş sesleri — azan däl, ýumşak ýatladyjy sesler.
class NotificationSounds {
  static const String defaultSoundId = 'sound_gentle_bell';

  static const List<NotificationSoundOption> options = [
    NotificationSoundOption(
      id: 'sound_gentle_bell',
      label: 'Ýumşak çan',
      description: 'Ýumşak, pes çan sesi — namaz wagty ýatladyjy',
    ),
    NotificationSoundOption(
      id: 'sound_wind_chime',
      label: 'Şemal çany',
      description: 'Ýeňil şemal çan sesi',
    ),
    NotificationSoundOption(
      id: 'sound_soft_ding',
      label: 'Ýumşak ding',
      description: 'Gysga we arassalanan bildiriş sesi',
    ),
    NotificationSoundOption(
      id: 'sound_marimba',
      label: 'Marimba',
      description: 'Agaç ýaly ýyly ton',
    ),
    NotificationSoundOption(
      id: 'sound_calm_flute',
      label: 'Sakin fleýta',
      description: 'Sakin iki notaly melodýa',
    ),
    NotificationSoundOption(
      id: 'sound_temple_gong',
      label: 'Mabet gongy',
      description: 'Pes, çuň rezonansly ses',
    ),
  ];

  static NotificationSoundOption optionById(String id) {
    return options.firstWhere(
      (o) => o.id == id,
      orElse: () => options.first,
    );
  }
}

class NotificationSoundOption {
  final String id;
  final String label;
  final String description;

  const NotificationSoundOption({
    required this.id,
    required this.label,
    required this.description,
  });

  String get assetPath => 'assets/sounds/$id.wav';
}

class GameSettings {
  final bool musicEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String language;

  const GameSettings({
    this.musicEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.language = 'en',
  });

  GameSettings copyWith({
    bool? musicEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? language,
  }) =>
      GameSettings(
        musicEnabled: musicEnabled ?? this.musicEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        'musicEnabled': musicEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'language': language,
      };

  factory GameSettings.fromJson(Map<String, dynamic> j) => GameSettings(
        musicEnabled: j['musicEnabled'] as bool? ?? true,
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        vibrationEnabled: j['vibrationEnabled'] as bool? ?? true,
        language: j['language'] as String? ?? 'en',
      );
}

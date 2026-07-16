import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// App events that can trigger a sound effect.
///
/// Adding a new sound event:
/// 1. Add an entry to the "events" map in assets/sounds.json
///    (its defaultSoundId must match a sound id from the "sounds" list)
/// 2. Add a value here whose [id] matches the JSON key
/// 3. Call `SoundController.playEvent(SoundEvent.<newEvent>)` where it happens
/// The settings screen picks up the new event automatically (one sound
/// picker per event); only its display name needs a l10n string.
enum SoundEvent {
  dailyTaskCompleted('daily_task_completed');

  const SoundEvent(this.id);

  /// Key of this event in assets/sounds.json.
  final String id;
}

/// A selectable sound effect from the assets/sounds.json manifest.
class AppSound {
  const AppSound({required this.id, required this.name, required this.file});

  final String id;

  /// Display name shown in the sound picker (not localized).
  final String name;

  /// Asset path relative to assets/ (audioplayers' AssetSource convention).
  final String file;
}

/// Sound effects: loads the assets/sounds.json manifest, plays event sounds
/// and persists the user's sound settings (enabled, per-event sound, volume).
///
/// Adding a new sound: drop the file into assets/audio/ and register it in
/// assets/sounds.json - it appears in the settings picker automatically.
class SoundController extends ChangeNotifier {
  static const _enabledKey = 'settings_sounds_enabled_v1';
  static const _volumeKey = 'settings_sounds_volume_v1';
  static String _eventSoundKey(SoundEvent event) =>
      'settings_sound_event_${event.id}_v1';

  final AudioPlayer _player = AudioPlayer();

  List<AppSound> _sounds = const [];
  /// Event id -> default sound id, from the manifest.
  Map<String, String> _eventDefaults = const {};
  /// Event id -> sound id the user picked (overrides the manifest default).
  final Map<String, String> _userChoices = {};

  bool _enabled = true;
  double _volume = 0.8;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// All sounds available in the picker.
  List<AppSound> get sounds => _sounds;

  Future<void> load() async {
    // Playback errors (e.g. missing asset) surface on the event stream,
    // not as play() exceptions - log them so failures aren't silent.
    _player.eventStream.listen(
      (_) {},
      onError: (Object e) => debugPrint('SoundController: player error: $e'),
    );
    try {
      final manifest =
          jsonDecode(await rootBundle.loadString('assets/sounds.json'))
              as Map<String, dynamic>;
      _sounds = [
        for (final entry in (manifest['sounds'] as List? ?? const []))
          AppSound(
            id: entry['id'] as String,
            name: entry['name'] as String,
            file: entry['file'] as String,
          ),
      ];
      _eventDefaults = {
        for (final e in (manifest['events'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: (e.value as Map<String, dynamic>)['defaultSoundId'] as String,
      };
    } catch (e) {
      debugPrint('SoundController: failed to load sounds.json: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _volume = (prefs.getDouble(_volumeKey) ?? 0.8).clamp(0.0, 1.0);
    for (final event in SoundEvent.values) {
      final choice = prefs.getString(_eventSoundKey(event));
      if (choice != null && _sounds.any((s) => s.id == choice)) {
        _userChoices[event.id] = choice;
      }
    }
    notifyListeners();
  }

  /// The sound currently assigned to [event] (user choice, else manifest
  /// default, else the first sound). Null only if the manifest is empty.
  AppSound? soundForEvent(SoundEvent event) {
    if (_sounds.isEmpty) return null;
    final id = _userChoices[event.id] ?? _eventDefaults[event.id];
    return _sounds.firstWhere((s) => s.id == id, orElse: () => _sounds.first);
  }

  /// Plays the sound assigned to [event]. No-op when sounds are disabled.
  Future<void> playEvent(SoundEvent event) async {
    if (!_enabled) return;
    final sound = soundForEvent(event);
    if (sound == null) return;
    await _play(sound);
  }

  /// Plays [sound] regardless of the enabled flag (settings preview).
  Future<void> preview(AppSound sound) => _play(sound);

  Future<void> _play(AppSound sound) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(sound.file), volume: _volume);
    } catch (e) {
      debugPrint('SoundController: failed to play ${sound.file}: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (_volume == clamped) return;
    _volume = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, clamped);
  }

  Future<void> setSoundForEvent(SoundEvent event, String soundId) async {
    if (_userChoices[event.id] == soundId) return;
    _userChoices[event.id] = soundId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventSoundKey(event), soundId);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

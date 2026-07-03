import '../../../../../core/utils/local_storage.dart';
import '../models/interval_timer_state.dart';

/// Local (SharedPreferences-backed) data source for the interval timer feature.
///
/// Owns the storage keys and all (de)serialization; the only place that talks
/// to [LocalStorage]. To move onto a database/server later, add a remote data
/// source with the same signatures and swap it in the repository.
class IntervalTimerLocalDataSource {
  static const _kProfilesKey = 'interval_timer_profiles';
  static const _kSelectedProfileKey = 'interval_timer_selected_profile';

  Future<List<IntervalTimerProfile>> loadProfiles() async {
    final data = await LocalStorage.loadJson(_kProfilesKey, fallback: null);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(IntervalTimerProfile.fromJson)
          .where((profile) => profile.id.isNotEmpty && profile.tasks.isNotEmpty)
          .toList();
    }
    return <IntervalTimerProfile>[];
  }

  Future<void> saveProfiles(List<IntervalTimerProfile> profiles) =>
      LocalStorage.saveJson(
        _kProfilesKey,
        profiles.map((profile) => profile.toJson()).toList(),
      );

  Future<String?> loadSelectedProfileId() async {
    final id = await LocalStorage.loadJson(_kSelectedProfileKey, fallback: null);
    return (id is String && id.isNotEmpty) ? id : null;
  }

  Future<void> saveSelectedProfileId(String? id) async {
    if (id == null) {
      await LocalStorage.remove(_kSelectedProfileKey);
      return;
    }
    await LocalStorage.saveJson(_kSelectedProfileKey, id);
  }
}

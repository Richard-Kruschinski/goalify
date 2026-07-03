import '../../data/models/interval_timer_state.dart';

/// Contract for persisting and retrieving the interval timer feature's data.
///
/// The controller depends only on this abstraction; local storage backs it
/// today and a database/server backend can be added later without changes here.
abstract class IntervalTimerRepository {
  Future<List<IntervalTimerProfile>> loadProfiles();
  Future<void> saveProfiles(List<IntervalTimerProfile> profiles);
  Future<String?> loadSelectedProfileId();
  Future<void> saveSelectedProfileId(String? id);
}

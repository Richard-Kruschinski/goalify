import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/interval_timer_state.dart';
import '../../../../core/utils/local_storage.dart';

class IntervalTimerController extends ChangeNotifier {
  static const String _profilesStorageKey = 'interval_timer_profiles';
  static const String _selectedProfileStorageKey = 'interval_timer_selected_profile';

  // Profile
  final List<IntervalTaskProfileItem> _tasks = [];
  List<IntervalTimerProfile> _customProfiles = [];
  String? _selectedProfileId;

  // Runtime state
  IntervalTimerPhase _currentPhase = IntervalTimerPhase.task;
  IntervalTimerState _timerState = IntervalTimerState.idle;
  int _remainingSeconds = 0;
  int _currentTaskIndex = 0;
  int _currentPauseSeconds = 0;
  int _pendingTaskIndex = 0;

  Timer? _timer;

  // Getters
  List<IntervalTaskProfileItem> get tasks => List.unmodifiable(_tasks);
  List<IntervalTimerProfile> get customProfiles => List.unmodifiable(_customProfiles);
  String? get selectedProfileId => _selectedProfileId;
  String get selectedProfileName {
    if (_selectedProfileId == null) return 'No profile';
    final profile = _customProfiles.where((p) => p.id == _selectedProfileId).firstOrNull;
    return profile?.name ?? 'No profile';
  }
  IntervalTimerPhase get currentPhase => _currentPhase;
  IntervalTimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get currentTaskNumber => _tasks.isEmpty ? 0 : _currentTaskIndex + 1;
  int get totalTasks => _tasks.length;
  bool get hasTasks => _tasks.isNotEmpty;
  bool get isInPause => _currentPhase == IntervalTimerPhase.pause;

  IntervalTimerController() {
    _loadProfiles();
  }

  String get currentPhaseLabel {
    return _currentPhase == IntervalTimerPhase.task ? 'Task' : 'Pause';
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get currentItemLabel {
    if (_tasks.isEmpty) return 'No profile created';
    if (_currentPhase == IntervalTimerPhase.pause) {
      return 'Pause before ${_tasks[_pendingTaskIndex].name}';
    }
    return _tasks[_currentTaskIndex].name;
  }

  int get totalSecondsForPhase {
    if (_tasks.isEmpty) return 0;
    return _currentPhase == IntervalTimerPhase.pause
        ? _currentPauseSeconds
        : _tasks[_currentTaskIndex].durationSeconds;
  }

  double get progress {
    final total = totalSecondsForPhase;
    if (total <= 0) return 0;
    return (1.0 - (_remainingSeconds / total)).clamp(0.0, 1.0);
  }

  void addTask({
    required String name,
    required int durationSeconds,
    int pauseBeforeSeconds = 0,
  }) {
    final sanitizedName = name.trim();
    final safeDuration = durationSeconds < 1 ? 1 : durationSeconds;
    final safePause = pauseBeforeSeconds < 0 ? 0 : pauseBeforeSeconds;

    if (sanitizedName.isEmpty) return;
    if (_timerState != IntervalTimerState.idle) return;

    _tasks.add(
      IntervalTaskProfileItem(
        name: sanitizedName,
        durationSeconds: safeDuration,
        pauseBeforeSeconds: _tasks.isEmpty ? 0 : safePause,
      ),
    );

    if (_tasks.length == 1) {
      _currentTaskIndex = 0;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks.first.durationSeconds;
    }

    _selectedProfileId = null;

    notifyListeners();
  }

  void removeTask(int index) {
    if (_timerState != IntervalTimerState.idle) return;
    if (index < 0 || index >= _tasks.length) return;

    _tasks.removeAt(index);
    if (_tasks.isEmpty) {
      _currentTaskIndex = 0;
      _remainingSeconds = 0;
      _currentPhase = IntervalTimerPhase.task;
      notifyListeners();
      return;
    }

    _currentTaskIndex = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = _tasks.first.durationSeconds;
    _selectedProfileId = null;

    if (_tasks.first.pauseBeforeSeconds != 0) {
      _tasks[0] = IntervalTaskProfileItem(
        name: _tasks[0].name,
        durationSeconds: _tasks[0].durationSeconds,
        pauseBeforeSeconds: 0,
      );
    }

    notifyListeners();
  }

  void updateTask({
    required int index,
    required String name,
    required int durationSeconds,
    int pauseBeforeSeconds = 0,
  }) {
    if (_timerState != IntervalTimerState.idle) return;
    if (index < 0 || index >= _tasks.length) return;

    final sanitizedName = name.trim();
    final safeDuration = durationSeconds < 1 ? 1 : durationSeconds;
    final safePause = pauseBeforeSeconds < 0 ? 0 : pauseBeforeSeconds;
    if (sanitizedName.isEmpty) return;

    _tasks[index] = IntervalTaskProfileItem(
      name: sanitizedName,
      durationSeconds: safeDuration,
      pauseBeforeSeconds: index == 0 ? 0 : safePause,
    );

    _currentTaskIndex = 0;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = _tasks.first.durationSeconds;
    _selectedProfileId = null;

    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (_timerState != IntervalTimerState.idle) return;
    if (oldIndex < 0 || oldIndex >= _tasks.length) return;
    if (newIndex < 0 || newIndex > _tasks.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final movedTask = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, movedTask);

    if (_tasks.isNotEmpty && _tasks.first.pauseBeforeSeconds != 0) {
      _tasks[0] = IntervalTaskProfileItem(
        name: _tasks[0].name,
        durationSeconds: _tasks[0].durationSeconds,
        pauseBeforeSeconds: 0,
      );
    }

    _currentTaskIndex = 0;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = _tasks.isEmpty ? 0 : _tasks.first.durationSeconds;
    _selectedProfileId = null;

    notifyListeners();
  }

  void clearProfile() {
    if (_timerState != IntervalTimerState.idle) return;

    _tasks.clear();
    _currentTaskIndex = 0;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = 0;
    _selectedProfileId = null;
    notifyListeners();
  }

  Future<void> createCustomProfile(String profileName) async {
    if (_timerState != IntervalTimerState.idle) return;
    if (_tasks.isEmpty) return;

    final trimmedName = profileName.trim();
    if (trimmedName.isEmpty) return;

    final newProfile = IntervalTimerProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmedName,
      tasks: _tasks
          .map(
            (task) => IntervalTaskProfileItem(
              name: task.name,
              durationSeconds: task.durationSeconds,
              pauseBeforeSeconds: task.pauseBeforeSeconds,
            ),
          )
          .toList(),
    );

    _customProfiles.add(newProfile);
    _selectedProfileId = newProfile.id;
    await _saveProfiles();
    await _saveSelectedProfile();
    notifyListeners();
  }

  Future<void> applyCustomProfile(String profileId) async {
    if (_timerState != IntervalTimerState.idle) return;

    final profile = _customProfiles.where((p) => p.id == profileId).firstOrNull;
    if (profile == null || profile.tasks.isEmpty) return;

    _tasks
      ..clear()
      ..addAll(
        profile.tasks.map(
          (task) => IntervalTaskProfileItem(
            name: task.name,
            durationSeconds: task.durationSeconds,
            pauseBeforeSeconds: task.pauseBeforeSeconds,
          ),
        ),
      );

    _selectedProfileId = profile.id;
    _currentTaskIndex = 0;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = _tasks.first.durationSeconds;

    await _saveSelectedProfile();
    notifyListeners();
  }

  Future<void> deleteCustomProfile(String profileId) async {
    _customProfiles.removeWhere((p) => p.id == profileId);
    if (_selectedProfileId == profileId) {
      _selectedProfileId = null;
      await _saveSelectedProfile();
    }
    await _saveProfiles();
    notifyListeners();
  }

  void start() {
    if (_timerState == IntervalTimerState.running) return;
    if (_tasks.isEmpty) return;

    if (_currentPhase == IntervalTimerPhase.task && _remainingSeconds <= 0) {
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
    }
    if (_currentPhase == IntervalTimerPhase.pause && _remainingSeconds <= 0) {
      _remainingSeconds = _currentPauseSeconds;
    }

    _timerState = IntervalTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_timerState != IntervalTimerState.running) return;

    _timer?.cancel();
    _timerState = IntervalTimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_timerState != IntervalTimerState.paused) return;
    _timerState = IntervalTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timerState = IntervalTimerState.idle;
    _currentPhase = IntervalTimerPhase.task;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentTaskIndex = 0;
    _remainingSeconds = _tasks.isEmpty ? 0 : _tasks.first.durationSeconds;
    notifyListeners();
  }

  void _completePhase() {
    _timer?.cancel();

    if (_tasks.isEmpty) {
      reset();
      return;
    }

    if (_currentPhase == IntervalTimerPhase.pause) {
      _currentTaskIndex = _pendingTaskIndex;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
      _timerState = IntervalTimerState.running;
      _startTicker();
      notifyListeners();
      return;
    }

    final nextTaskIndex = _currentTaskIndex + 1;
    if (nextTaskIndex >= _tasks.length) {
      _timerState = IntervalTimerState.idle;
      _currentPhase = IntervalTimerPhase.task;
      _currentTaskIndex = 0;
      _pendingTaskIndex = 0;
      _currentPauseSeconds = 0;
      _remainingSeconds = _tasks.first.durationSeconds;
      notifyListeners();
      return;
    }

    final pauseBeforeNext = _tasks[nextTaskIndex].pauseBeforeSeconds;
    if (pauseBeforeNext > 0) {
      _currentPauseSeconds = pauseBeforeNext;
      _pendingTaskIndex = nextTaskIndex;
      _currentPhase = IntervalTimerPhase.pause;
      _remainingSeconds = pauseBeforeNext;
    } else {
      _currentTaskIndex = nextTaskIndex;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
    }

    _timerState = IntervalTimerState.running;
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _completePhase();
        return;
      }

      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        _completePhase();
        return;
      }

      notifyListeners();
    });
  }

  Future<void> _loadProfiles() async {
    final profilesData = await LocalStorage.loadJson(_profilesStorageKey, fallback: null);
    if (profilesData is List) {
      _customProfiles = profilesData
          .whereType<Map<String, dynamic>>()
          .map(IntervalTimerProfile.fromJson)
          .where((profile) => profile.id.isNotEmpty && profile.tasks.isNotEmpty)
          .toList();
    }

    final selectedId = await LocalStorage.loadJson(_selectedProfileStorageKey, fallback: null);
    if (selectedId is String && selectedId.isNotEmpty) {
      _selectedProfileId = selectedId;
      final selectedProfile = _customProfiles.where((p) => p.id == selectedId).firstOrNull;
      if (selectedProfile != null && selectedProfile.tasks.isNotEmpty) {
        _tasks
          ..clear()
          ..addAll(
            selectedProfile.tasks.map(
              (task) => IntervalTaskProfileItem(
                name: task.name,
                durationSeconds: task.durationSeconds,
                pauseBeforeSeconds: task.pauseBeforeSeconds,
              ),
            ),
          );
        _currentTaskIndex = 0;
        _currentPhase = IntervalTimerPhase.task;
        _remainingSeconds = _tasks.first.durationSeconds;
      }
    }

    notifyListeners();
  }

  Future<void> _saveProfiles() async {
    await LocalStorage.saveJson(
      _profilesStorageKey,
      _customProfiles.map((profile) => profile.toJson()).toList(),
    );
  }

  Future<void> _saveSelectedProfile() async {
    if (_selectedProfileId == null) {
      await LocalStorage.remove(_selectedProfileStorageKey);
      return;
    }
    await LocalStorage.saveJson(_selectedProfileStorageKey, _selectedProfileId!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

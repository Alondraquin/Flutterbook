import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/base_model.dart';
import 'timers_db_worker.dart';

/// Represents a saved countdown timer preset.
class TimerPreset extends Entry {
  /// The display name of the timer (e.g., "Pomodoro").
  String title;

  /// The total configured duration of the timer in seconds.
  int durationSeconds;

  /// An optional category label (e.g., "Study", "Workout", "General").
  String category;

  /// Creates a [TimerPreset] with optional default values.
  TimerPreset({
    super.id,
    this.title = '',
    this.durationSeconds = 60,
    this.category = 'General',
  });

  /// Formats a duration in seconds as `MM:SS` or `HH:MM:SS`.
  static String formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Returns the preset's configured duration as a formatted string.
  String get formattedDuration => formatSeconds(durationSeconds);
}

/// Manages the list of [TimerPreset] entries and active countdown state.
class TimersModel extends BaseModel<TimerPreset> {
  /// Creates a [TimersModel] backed by [TimersDBWorker.db].
  TimersModel() : super(TimersDBWorker.db);

  Timer? _ticker;
  int? _activeTimerId;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  /// Optional callback invoked when an active countdown reaches zero.
  VoidCallback? onTimerFinished;

  /// The database ID of the currently active timer, or `null` if none.
  int? get activeTimerId => _activeTimerId;

  /// The number of seconds remaining on the active timer.
  int get remainingSeconds => _remainingSeconds;

  /// Whether the active timer is currently counting down.
  bool get isRunning => _isRunning;

  /// Starts or resumes the countdown for the given [preset].
  ///
  /// If a different timer was active, it is replaced and reset to [preset]'s
  /// configured duration before starting.
  void startTimer(TimerPreset preset) {
    // Switching to a different timer preset resets the remaining time.
    if (_activeTimerId != preset.id) {
      _ticker?.cancel();
      _activeTimerId = preset.id;
      _remainingSeconds = preset.durationSeconds;
    } else if (_remainingSeconds <= 0) {
      // Restart from the beginning if it previously finished.
      _remainingSeconds = preset.durationSeconds;
    }

    if (_isRunning) return;

    _isRunning = true;
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        _isRunning = false;
        timer.cancel();
        notifyListeners();
        onTimerFinished?.call();
      }
    });
  }

  /// Pauses the currently running countdown without resetting remaining time.
  void pauseTimer() {
    if (!_isRunning) return;
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Stops the countdown and restores [preset]'s original duration.
  void resetTimer(TimerPreset preset) {
    _ticker?.cancel();
    _isRunning = false;
    if (_activeTimerId == preset.id) {
      _remainingSeconds = preset.durationSeconds;
    }
    notifyListeners();
  }

  @override
  Future<void> deleteEntry(TimerPreset entry) async {
    if (_activeTimerId == entry.id) {
      _ticker?.cancel();
      _activeTimerId = null;
      _remainingSeconds = 0;
      _isRunning = false;
    }
    await super.deleteEntry(entry);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timers_model.dart';

/// Displays the list of saved [TimerPreset] items and active countdown controls.
class TimersList extends StatefulWidget {
  /// Creates the [TimersList] screen.
  const TimersList({super.key});

  @override
  State<TimersList> createState() => _TimersListState();
}

class _TimersListState extends State<TimersList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TimersModel>().onTimerFinished = _showFinishedDialog;
    });
  }

  /// Displays an alert dialog when the active countdown reaches zero.
  void _showFinishedDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.alarm_on, size: 40, color: Colors.blueAccent),
        title: const Text("Time's Up!"),
        content: const Text('Your countdown timer has finished.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Prompts the user to confirm deleting [preset].
  Future<void> _confirmDelete(BuildContext context, TimerPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Timer'),
        content: Text('Delete "${preset.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TimersModel>().deleteEntry(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TimersModel>();
    final presets = model.entryList;

    // Find the currently active preset if one is selected.
    TimerPreset? activePreset;
    for (final item in presets) {
      if (item.id == model.activeTimerId) {
        activePreset = item;
        break;
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Timer',
        onPressed: () => model.startEditingEntry(TimerPreset()),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (activePreset != null)
            _ActiveCountdownBanner(model: model, preset: activePreset),
          Expanded(
            child: presets.isEmpty
                ? const Center(
                    child: Text(
                      'No saved timers yet.\nTap + to create one.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final isThisActive = model.activeTimerId == preset.id;
                      final isThisRunning = isThisActive && model.isRunning;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => model.startEditingEntry(preset),
                          leading: CircleAvatar(
                            child: Icon(
                              isThisRunning ? Icons.hourglass_bottom : Icons.timer,
                            ),
                          ),
                          title: Text(
                            preset.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${preset.formattedDuration}  •  ${preset.category}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: isThisRunning ? 'Pause' : 'Start',
                                icon: Icon(
                                  isThisRunning
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 30,
                                ),
                                onPressed: () {
                                  if (isThisRunning) {
                                    model.pauseTimer();
                                  } else {
                                    model.startTimer(preset);
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, preset),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Banner displaying live countdown progress for the active [TimerPreset].
class _ActiveCountdownBanner extends StatelessWidget {
  final TimersModel model;
  final TimerPreset preset;

  const _ActiveCountdownBanner({
    required this.model,
    required this.preset,
  });

  @override
  Widget build(BuildContext context) {
    final progress = preset.durationSeconds > 0
        ? model.remainingSeconds / preset.durationSeconds
        : 0.0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 5,
                  ),
                  const Icon(Icons.timer_outlined),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    TimerPreset.formatSeconds(model.remainingSeconds),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: model.isRunning ? 'Pause' : 'Resume',
              onPressed: () {
                if (model.isRunning) {
                  model.pauseTimer();
                } else {
                  model.startTimer(preset);
                }
              },
              icon: Icon(model.isRunning ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Reset',
              onPressed: () => model.resetTimer(preset),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
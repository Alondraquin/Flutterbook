import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timers_model.dart';

/// Form screen for creating or editing a [TimerPreset].
class TimersEntry extends StatefulWidget {
  /// Creates the [TimersEntry] form view.
  const TimersEntry({super.key});

  @override
  State<TimersEntry> createState() => _TimersEntryState();
}

class _TimersEntryState extends State<TimersEntry> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  TimerPreset? _loadedEntry;
  int _hours = 0;
  int _minutes = 1;
  int _seconds = 0;
  String _category = 'General';

  static const List<String> _categories = [
    'General',
    'Study',
    'Work',
    'Workout',
    'Break',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Syncs local form fields whenever [TimersModel.entryBeingEdited] changes.
  void _syncFromModel(TimerPreset? entry) {
    if (entry == null || identical(entry, _loadedEntry)) return;
    _loadedEntry = entry;
    _titleController.text = entry.title;
    _hours = entry.durationSeconds ~/ 3600;
    _minutes = (entry.durationSeconds % 3600) ~/ 60;
    _seconds = entry.durationSeconds % 60;
    _category = _categories.contains(entry.category) ? entry.category : 'General';
  }

  int get _totalSeconds => (_hours * 3600) + (_minutes * 60) + _seconds;

  void _applyQuickPreset(int minutes, String label, String category) {
    setState(() {
      _hours = 0;
      _minutes = minutes;
      _seconds = 0;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = label;
      }
      _category = category;
    });
  }

  Future<void> _save(TimersModel model) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration must be at least 1 second.'),
        ),
      );
      return;
    }

    final entry = model.entryBeingEdited!;
    entry
      ..title = _titleController.text.trim()
      ..durationSeconds = _totalSeconds
      ..category = _category;

    // Reset active countdown if the user just edited the currently active timer.
    if (model.activeTimerId == entry.id) {
      model.resetTimer(entry);
    }

    _loadedEntry = null;
    await model.stopEditingEntry(save: true);
  }

  Future<void> _cancel(TimersModel model) async {
    _loadedEntry = null;
    await model.stopEditingEntry(save: false);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TimersModel>();
    final entry = model.entryBeingEdited;
    _syncFromModel(entry);

    return Scaffold(
      appBar: AppBar(
        title: Text(entry?.isNew ?? true ? 'New Timer' : 'Edit Timer'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Timer Title',
                  hintText: 'e.g., Pomodoro Study Session',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a timer title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DurationDropdown(
                      label: 'Hours',
                      value: _hours,
                      max: 23,
                      onChanged: (val) => setState(() => _hours = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationDropdown(
                      label: 'Minutes',
                      value: _minutes,
                      max: 59,
                      onChanged: (val) => setState(() => _minutes = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DurationDropdown(
                      label: 'Seconds',
                      value: _seconds,
                      max: 59,
                      onChanged: (val) => setState(() => _seconds = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('1 min'),
                    onPressed: () => _applyQuickPreset(1, 'Quick 1 Min', 'General'),
                  ),
                  ActionChip(
                    label: const Text('5 min Break'),
                    onPressed: () => _applyQuickPreset(5, 'Short Break', 'Break'),
                  ),
                  ActionChip(
                    label: const Text('15 min'),
                    onPressed: () => _applyQuickPreset(15, '15 Min Focus', 'Work'),
                  ),
                  ActionChip(
                    label: const Text('25 min Pomodoro'),
                    onPressed: () => _applyQuickPreset(25, 'Pomodoro', 'Study'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _cancel(model),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _save(model),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Timer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numeric dropdown selector for hours, minutes, or seconds.
class _DurationDropdown extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _DurationDropdown({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: List.generate(
        max + 1,
        (index) => DropdownMenuItem(
          value: index,
          child: Text(index.toString().padLeft(2, '0')),
        ),
      ),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}
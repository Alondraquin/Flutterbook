import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/base_model.dart';
import 'timers_entry.dart';
import 'timers_list.dart';
import 'timers_model.dart';

/// Top-level widget for the Timers tab.
///
/// Switches between [TimersList] and [TimersEntry] based on the current
/// [Screen] state in [TimersModel].
class Timers extends StatelessWidget {
  /// Creates the [Timers] feature view.
  const Timers({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = context.watch<TimersModel>().screen;
    return IndexedStack(
      index: screen.index,
      children: const [
        TimersList(),
        TimersEntry(),
      ],
    );
  }
}
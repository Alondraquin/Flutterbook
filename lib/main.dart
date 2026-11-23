import 'dart:io';

import 'features/timers/timers.dart';
import 'features/timers/timers_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'features/appointments/appointments.dart';
import 'features/appointments/appointments_model.dart';
import 'features/contacts/contacts.dart';
import 'features/contacts/contacts_model.dart';
import 'features/notes/notes.dart';
import 'features/notes/notes_model.dart';
import 'features/timers/timers.dart';
import 'features/timers/timers_model.dart';
import 'features/tasks/tasks.dart';
import 'features/tasks/tasks_model.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    runApp(const UnsupportedPlatformApp());
    return;
  }
  runApp(const FlutterBook());
}

class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'FlutterBook currently runs on Windows desktop. '
              'Run it with "flutter run -d windows" instead of Chrome.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class FlutterBook extends StatefulWidget {
  const FlutterBook({super.key});

  @override
  State<FlutterBook> createState() => _FlutterBookState();
}

class _FlutterBookState extends State<FlutterBook> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _initialization = _initializeApp();
      });
    });
  }

  Future<void> _initializeApp() async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await setAvatarDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Book',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: _initialization == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : FutureBuilder<void>(
              future: _initialization,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('FlutterBook')),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not initialize FlutterBook:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return DefaultTabController(
                  length: _tabs.length,
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('FlutterBook'),
                      bottom: TabBar(
                        tabs: [
                          for (final tab in _tabs)
                            Tab(icon: Icon(tab.icon), text: tab.title),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      children: [for (final tab in _tabs) tab.view],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

typedef _TabInfo = ({String title, IconData icon, Widget view});

final _tabs = <_TabInfo>[
  (
    title: 'Appointments',
    icon: Icons.date_range,
    view: ChangeNotifierProvider(
      create: (_) => AppointmentsModel()..loadData(notify: true),
      child: const Appointments(),
    ),
  ),
  (
    title: 'Contacts',
    icon: Icons.contacts,
    view: ChangeNotifierProvider(
      create: (_) => ContactsModel()..loadData(notify: true),
      child: const Contacts(),
    ),
  ),
  (
    title: 'Notes',
    icon: Icons.note,
    view: ChangeNotifierProvider(
      create: (_) => NotesModel()..loadData(notify: true),
      child: const Notes(),
    ),
  ),
  (
    title: 'Tasks',
    icon: Icons.assignment_turned_in,
    view: ChangeNotifierProvider(
      create: (_) => TasksModel()..loadData(notify: true),
      child: const Tasks(),
    ),
  ),
];

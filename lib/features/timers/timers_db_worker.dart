import '../../shared/base_model.dart';
import 'timers_model.dart';

/// SQLite-backed persistence for [TimerPreset] entries.
///
/// Supplies the schema and the conversion logic required by
/// [SqliteDBWorker]; all CRUD operations are inherited unchanged.
/// Access the singleton instance via [TimersDBWorker.db].
class TimersDBWorker extends SqliteDBWorker<TimerPreset> {
  /// Singleton instance of [TimersDBWorker].
  static final TimersDBWorker db = TimersDBWorker._();

  TimersDBWorker._();

  @override
  String get dbName => 'timers.db';

  @override
  String get tableName => 'timers';

  @override
  String get createTableSql => '''
    CREATE TABLE IF NOT EXISTS timers (
      id INTEGER PRIMARY KEY,
      title TEXT,
      durationSeconds INTEGER,
      category TEXT
    )''';

  @override
  Map<String, dynamic> toMap(TimerPreset timer) => {
    'id': timer.id,
    'title': timer.title,
    'durationSeconds': timer.durationSeconds,
    'category': timer.category,
  };

  @override
  TimerPreset fromMap(Map<String, dynamic> map) => TimerPreset(
    id: map['id'] as int,
    title: (map['title'] as String?) ?? '',
    durationSeconds: (map['durationSeconds'] as int?) ?? 60,
    category: (map['category'] as String?) ?? 'General',
  );
}
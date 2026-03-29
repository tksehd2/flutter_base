import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class AppLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get message => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [AppLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<AppLog>> getRecentLogs() {
    return (select(
      appLogs,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
  }

  Future<int> addLog(String message) {
    return into(appLogs).insert(AppLogsCompanion.insert(message: message));
  }

  Future<void> clearLogs() => delete(appLogs).go();
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'app_database',
    native: DriftNativeOptions(
      databaseDirectory: () async {
        final directory = await getApplicationDocumentsDirectory();
        return Directory(p.join(directory.path, 'db'));
      },
    ),
  );
}

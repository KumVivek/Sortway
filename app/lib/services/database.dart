import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Best result per level (campaign, daily and event levels alike).
class LevelProgress extends Table {
  TextColumn get levelId => text()();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get bestFlips => integer().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {levelId};
}

class Stickers extends Table {
  IntColumn get setIndex => integer()();
  IntColumn get stickerIndex => integer()();
  DateTimeColumn get earnedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {setIndex, stickerIndex};
}

/// Wallet balance, streaks, entitlement cache, in-progress level snapshot…
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [LevelProgress, Stickers, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file on a background isolate.
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'flow_sort.sqlite')),
      );
    }),
  );

  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Add steps here when schemaVersion is raised; never drop player data.
    onUpgrade: (m, from, to) async {},
  );
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// --- Tables ---

class Posts extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get userId => text()();
  TextColumn get rootId => text().withDefault(const Constant(''))();
  TextColumn get message => text().withDefault(const Constant(''))();
  IntColumn get createAt => integer().withDefault(const Constant(0))();
  IntColumn get updateAt => integer().withDefault(const Constant(0))();
  IntColumn get deleteAt => integer().withDefault(const Constant(0))();
  IntColumn get editAt => integer().withDefault(const Constant(0))();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  TextColumn get fileIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get filesJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get replyCount => integer().withDefault(const Constant(0))();
  TextColumn get reactionsJson => text().withDefault(const Constant('{}'))();
  TextColumn get pendingId => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant(''))();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  IntColumn get sendStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get header => text().withDefault(const Constant(''))();
  TextColumn get purpose => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('O'))();
  IntColumn get createAt => integer().withDefault(const Constant(0))();
  IntColumn get updateAt => integer().withDefault(const Constant(0))();
  IntColumn get deleteAt => integer().withDefault(const Constant(0))();
  IntColumn get totalMsgCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPostAt => integer().withDefault(const Constant(0))();
  IntColumn get msgCount => integer().withDefault(const Constant(0))();
  IntColumn get mentionCount => integer().withDefault(const Constant(0))();
  IntColumn get lastViewedAt => integer().withDefault(const Constant(0))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get nickname => text().withDefault(const Constant(''))();
  TextColumn get position => text().withDefault(const Constant(''))();
  TextColumn get locale => text().withDefault(const Constant('en'))();
  IntColumn get createAt => integer().withDefault(const Constant(0))();
  IntColumn get updateAt => integer().withDefault(const Constant(0))();
  IntColumn get deleteAt => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('offline'))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(tables: [Posts, Channels, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'mgmess.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

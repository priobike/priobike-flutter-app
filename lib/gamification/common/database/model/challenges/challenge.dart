import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';

part 'challenge.g.dart';

/// This enum describes the different kind of challenges a user can do.
enum ChallengeType {
  distance,
  duration,
  rides,
  streak,
}

/// This table which holds objects, which represent the challenges a user can do in the game. The objects hold
/// information about the challenge and its state and about the users challenge progress.
class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get xp => integer()();
  DateTimeColumn get begin => dateTime()();
  DateTimeColumn get end => dateTime()();
  DateTimeColumn get userStartTime => dateTime()();
  TextColumn get description => text()();
  IntColumn get target => integer()();
  IntColumn get progress => integer()();
  BoolColumn get isWeekly => boolean()();
  BoolColumn get isOpen => boolean()();
  IntColumn get type => integer()();
}

@DriftAccessor(tables: [Challenges])
class ChallengeDao extends DatabaseDao<Challenge> with _$ChallengesDaoMixin {
  ChallengeDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => challenges;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(challenges)..where((tbl) => (tbl as $ChallengesTable).id.equals(value)));
  }

  /// Get all weekly challenges, that are still open.
  Future<List<Challenge>> getOpenWeeklyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly)).get();
  }

  /// Get all daily challenges, that are still open.
  Future<List<Challenge>> getOpenDailyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly.not())).get();
  }

  /// Stream all challenges, that have been completed by the user and that are closed,
  /// which means the rewards were collected.
  Stream<List<Challenge>> streamClosedCompletedChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen.not() & tbl.progress.isBiggerOrEqual(tbl.target))).watch();
  }

  /// Stream all challenges which can be completed in a certain given interval.
  Stream<List<Challenge>> streamChallengesInInterval(DateTime startDay, int lengthInDays) {
    var start = DateTime(startDay.year, startDay.month, startDay.day);
    var end = start.add(Duration(days: lengthInDays));
    return (select(challenges)..where((tbl) => tbl.begin.equals(start) & tbl.end.equals(end))).watch();
  }
}

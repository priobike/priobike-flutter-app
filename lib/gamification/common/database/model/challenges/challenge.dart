import 'package:drift/drift.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/database_dao.dart';

part 'challenge.g.dart';

enum ChallengeType {
  distance,
  duration,
  rides,
  streak,
}

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
class ChallengesDao extends DatabaseDao<Challenge> with _$ChallengesDaoMixin {
  ChallengesDao(AppDatabase attachedDatabase) : super(attachedDatabase);

  @override
  TableInfo<Table, dynamic> get table => challenges;

  @override
  SimpleSelectStatement selectByPrimaryKey(dynamic value) {
    return (select(challenges)..where((tbl) => (tbl as $ChallengesTable).id.equals(value)));
  }

  Stream<List<Challenge>> streamOpenDailyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly.not())).watch();
  }

  Stream<List<Challenge>> streamOpenWeeklyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly)).watch();
  }

  Stream<List<Challenge>> streamChallengesInInterval(DateTime startDay, int lengthInDays) {
    var start = DateTime(startDay.year, startDay.month, startDay.day);
    var end = start.add(Duration(days: lengthInDays));
    return (select(challenges)..where((tbl) => tbl.begin.equals(start) & tbl.end.equals(end))).watch();
  }

  Future<List<Challenge>> getChallengesInInterval(DateTime startDay, int lengthInDays) {
    var start = DateTime(startDay.year, startDay.month, startDay.day);
    var end = start.add(Duration(days: lengthInDays));
    return (select(challenges)..where((tbl) => tbl.begin.equals(start) & tbl.end.equals(end))).get();
  }

  Future<List<Challenge>> getOpenWeeklyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly)).get();
  }

  Future<List<Challenge>> getOpenDailyChallenges() {
    return (select(challenges)..where((tbl) => tbl.isOpen & tbl.isWeekly.not())).get();
  }

  Future<void> clearDatabase() async {
    var allObjects = await getAllObjects();
    for (var o in allObjects) {
      await deleteObject(o);
    }
  }
}
